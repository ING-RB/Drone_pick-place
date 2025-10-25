%matlab.internal.webservices.HTTPConnector HTTP connector handle object
%
%   FOR INTERNAL USE ONLY -- This class is intentionally undocumented and
%   is intended for use only within the scope of functions and classes in
%   toolbox/matlab/external/interfaces/webservices/restful. Its behavior
%   may change, or the class itself may be removed in a future release.
%
%   matlab.internal.webservices.HTTPConnector properties (read-only):
%      URL          - URL string
%      CharacterSet - Connection charset value
%      ContentType  - Connection content type
%
%   matlab.internal.webservices.HTTPConnector properties:
%      Username - User identifier
%      Password - User authentication password
%      KeyName - Name of key
%      KeyValue - Value of key
%      HeaderFields - n-by-2 string matrix or cellstr of header names and values
%      UserAgent - User agent identification
%      Timeout - Connection timeout
%      RequestMethod - Name of HTTP request method (GET or POST)
%      PostData - String data to post to service
%      MediaType - Media type of data to post to service
%      Debug - Print debug information
%
%   matlab.internal.webservices.HTTPConnector methods:
%      HTTPConnector - Constructor
%      closeConnection - Close HTTP connection
%      copyContentToByteArray - Copy content to byte array
%      copyContentToFile - Copy content to file
%      delete - Delete object
%      openConnection - Open HTTP connection

% Copyright 2014-2024 The MathWorks, Inc.

classdef HTTPConnector < handle

    properties (SetAccess = 'protected', Dependent)
        URL
    end

    properties (SetAccess = 'protected')
        CharacterSet = ''
        ContentType = ''
    end

    properties
        Username = ''
        Password = ''
        KeyName = ''
        KeyValue = ''
        HeaderFields = []
        UserAgent = ''
        Timeout = []
        RequestMethod = 'GET'
        PostData = ''
    end

    properties (Dependent)
        MediaType char
    end

    properties
        CharacterEncoding
        Decode logical = true % false to turn off decompression
    end

    properties (Hidden)
        Debug = false   % display request and response messages
        RealMediaType = matlab.net.http.MediaType('application/x-www-form-urlencoded')
        NativeDebug = 0 % debug at the C++ level
    end

    properties (Dependent)
        CertificateFilename = ''
    end

    properties (Hidden, Access = 'protected')
        Connection = [] % matlab.internal.webservices.HTTPConnectionAdapter (C++)
        ConnectionIsOpen = false
        Proxy = []
        Protocol = ''
        OptionsContentType = ''
        NumberOfRedirects = 0
        MaximumRedirects = 20

        % Reference: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
        StatusCode = struct( ...
            'MovedPermanently', 301, ...
            'Found', 302, ...
            'SeeOther',  303, ...
            'TemporaryRedirect', 307, ...
            'Unauthorized', 401, ...
            'ProxyAuthenticationRequired', 407)

        NumberOfUnauthorizedAttempts = 0
        MaximumNumberOfUnauthorizedAttempts = 1
    end

    properties (Access = 'private')
        pURL
        pCertificateFilename

        % The DefaultCertificateFilename is the location of the generated
        % file containing root certificates. If set, then the certificate
        % from the HTTP server is validated against the certificates in the
        % PEM file. The verification validates the host domain against the
        % domain in the certificate and also issues an error if the
        % certificate in the PEM file has expired. Since the current
        % version of rootcerts.pem does have an expired certificate, set
        % the property value to ''. Even with an empty root certificate
        % file, the domain verification is still performed.
        % DefaultCertificateFilename = fullfile(matlabroot,'sys','certificates','ca','rootcerts.pem');
        DefaultCertificateFilename = ''
        MessageCount = 0  % used in log
    end

    methods
        function set.MediaType(connector, value)
            if isempty(value) || value == ""
                connector.RealMediaType = matlab.net.http.MediaType.empty;
            elseif (ischar(value) || isstring(value)) && strcmpi(value,'auto')
                connector.RealMediaType = value;
            else
                connector.RealMediaType = matlab.net.http.MediaType(value);
            end
        end

        function value = get.MediaType(connector)
            value = char(connector.RealMediaType);
        end

        function obj = HTTPConnector(url, options, connection)
        % Constructor for HTTPConnector class.

            % Create a connection object, if not passed as an argument.
            if ~exist('connection', 'var')
                connection = matlab.internal.webservices.HTTPConnectionAdapter;
            end
            obj.Connection = connection;

            % Set the CertificateFilename property.
            obj.CertificateFilename = obj.DefaultCertificateFilename;

            % Set the URL property value.
            obj.URL = url;

            % Set the HTTPConnector request properties.
            if ~exist('options', 'var')
                options = weboptions;
            end
            if options.RequestMethod == "auto"
                options.RequestMethod = 'GET';
            end
            obj = setProperties(obj, options);
            obj.OptionsContentType = options.ContentType;

        end

        %------------------------------------------------------------------

        function openConnection(obj)
        % Open the URL connection and set request properties. Follow URL
        % redirects.

            if ~obj.ConnectionIsOpen
                try
                    connection = obj.Connection;
                    connection.Debug = obj.NativeDebug;

                    % Set timeout.  This sets both the connect timemout and
                    % response timeout to the user-specified value.  So even if we get a connect to
                    % complete on time, we may still time out if the server does not send a response
                    % header within this time after we have sent our request.
                    milliseconds = secondsToMilliseconds(obj.Timeout);
                    connection.TimeoutInMilliseconds = [milliseconds milliseconds];

                    % Set Username and Password property values. (Allow
                    % an empty password to be passed to the server, but not
                    % an empty username).
                    [username, password] = ...
                        checkRequestProperty(obj, 'Username', 'Password');
                    if ~isempty(username)
                        connection.Username = getSecretFromValue(username);
                        connection.Password = getSecretFromValue(password);
                    end


                    % Need to decide in advance whether to decode response, if it's compressed
                    obj.Decode = ~strcmpi(obj.OptionsContentType,'binary') && obj.Decode;

                    % Open the connection to the URL.
                    if isempty(obj.Proxy.Host)
                        connection.openConnection();
                    else
                        connection.ProxyUsername = obj.Proxy.Username;
                        connection.ProxyPassword = obj.Proxy.Password;
                        connection.openProxyConnection(obj.Proxy);
                    end

                    % Set the request properties.
                    setRequestProperties(obj);

                    % Set the connection properties.
                    setConnectionProperties(obj);

                    % Check if redirecting.
                    if any(strcmpi(obj.Protocol, {'http', 'https'}))
                        if isRedirecting(obj) && ...
                                obj.NumberOfRedirects < obj.MaximumRedirects
                            if obj.Debug
                                % For purposes of logging the body of the redirect
                                % message, assume native encoding.  We should really be
                                % looking at the charset in the Content-Type header.
                                try
                                    bytes = copyContentToByteArray(obj.Connection, true);
                                catch
                                    % a redirect likely just throws an error in
                                    % RESTful mode, so copy no bytes
                                    bytes = '';
                                end
                                obj.log(native2unicode(bytes));
                            end
                            % Follow redirects. Increase count to prevent
                            % indefinite recursion.
                            obj.NumberOfRedirects = obj.NumberOfRedirects + 1;

                            % Redirecting to a different URL.
                            openRedirectConnection(obj);
                        end
                    end

                    % If an unauthorized code is returned by the server,
                    % the request method is 'get', and the JVM is running,
                    % then try again using the HTTPJavaConnectionAdapter.
                    % This adapter uses Java to communicate to the server
                    % and Java supports NTLM authentication (on Windows).
                    % Do not attempt more times than allowed by
                    % MaximumNumberOfUnauthorizedAttempts.
                    if (obj.Connection.ResponseCode == obj.StatusCode.Unauthorized || ...
                        obj.Connection.ResponseCode == obj.StatusCode.ProxyAuthenticationRequired) && ...
                            usejava('jvm') && ...
                            obj.NumberOfUnauthorizedAttempts < obj.MaximumNumberOfUnauthorizedAttempts
                        obj.NumberOfUnauthorizedAttempts = obj.NumberOfUnauthorizedAttempts + 1;
                        if obj.Debug
                            try
                                % Try to grab data from the unauthorized message.  Need to pretend connection
                                % is open to avoid trying to open it again.
                                oldOpen = obj.ConnectionIsOpen;
                                obj.ConnectionIsOpen = true;
                                clean = onCleanup(@()obj.ConnectionIsOpen(oldOpen));
                                bytes = obj.copyContentToByteArray();
                            catch
                                bytes = '';
                            end
                            obj.log(char(bytes)');
                            obj.log("Trying again");
                        end
                        openConnection(obj);
                    end

                    % Connection is open.
                    obj.ConnectionIsOpen = true;
                catch e
                    if obj.Debug || obj.NativeDebug
                        rethrow(e)
                    else
                        throwAsCaller(e)
                    end
                end
            end
        end

        %------------------------------------------------------------------

        function res = log(obj, responseData)
        % Return a log of the request and response messages, including the
        % data.  If no return value, print it.

            connection = obj.Connection;
            if isa(connection, 'matlab.internal.webservices.HTTPConnectionAdapter')
                % We use functions in the http package to reconstruct request and response
                % messages, which are able to pretty-print their contents.
                import matlab.net.http.*
                import matlab.net.*
                [a,b,c] = connection.getRequestLine();
                requestLine = RequestLine(a, b, c);
                requestMessage = RequestMessage(requestLine);
                requestMessage = ...
                    requestMessage.addFieldsNoCheck(connection.getRequestFields());
                % get the raw payload that was sent, as uint8 vector, and insert it into
                % MessageBody
                payload = connection.Payload;
                charset = '';
                if ~isempty(payload)
                    body = MessageBody();
                    body.Payload = payload;
                    requestMessage.Body = body;
                    % The set method for Body in the line above copied any Content-Type from the
                    % requestMessage into Body.ContentType, as a MediaType object, so fetch it and
                    % save any specified or implied charset.
                    ct = requestMessage.Body.ContentType;
                    if ~isempty(ct)
                        charset = matlab.net.internal.getCharsetForMediaType(ct);
                    end
                end
                requestMessage.Completed = true;
                [version, status, reason] = connection.getStatusLine();
                response = ResponseMessage(StatusLine(version, status, reason));
                response = response.addFieldsNoCheck(connection.getResponseFields());
                obj.MessageCount = obj.MessageCount + 1;
                res = sprintf('\nREQUEST %d to %s\n\n%s\n', obj.MessageCount, ...
                              obj.URL,  char(requestMessage));
                % If request payload is text (has a known charset), print it as a string
                if charset ~= ""
                    payload = native2unicode(payload, char(charset));
                    res = [res sprintf('%s\n\n', payload)];
                end

                res = [res sprintf('RESPONSE\n\n%s\n', char(response))];
                if ~ischar(responseData)
                    responseData = evalc('disp(responseData)');
                end
                if length(responseData) > 1000
                    res = [res sprintf('<<%d bytes of data>>\n', length(responseData))];
                else
                    res = [res sprintf('%s\n', responseData)];
                end
                res = [res sprintf('----------------------------\n')];
            else
                res = sprintf('\nUsing Java\n');
            end
            if nargout == 0
                fprintf('%s',res);
            end
        end

        %------------------------------------------------------------------

        function closeConnection(obj)
        % Close the connection.

            connection = obj.Connection;
            % check isvalid because connection may have been passed in as an argument
            % and gotten deleted
            if ~isempty(connection) && ismethod(connection, 'closeConnection') && isvalid(connection)
                connection.closeConnection;
            end
            obj.ConnectionIsOpen = false;
        end

        %------------------------------------------------------------------

        function delete(obj)
        % Close the connection when deleting the object.

            obj.closeConnection()
            delete@handle(obj);
        end

        %------------------------------------------------------------------

        function byteArray = copyContentToByteArray(obj)
        % Copy the content from the Web service to a byte (uint8) array.

            openConnection(obj);
            closeObj = onCleanup(@()closeConnection(obj));
            try
                byteArray = copyContentToByteArray(obj.Connection, true);
            catch e
                code = obj.Connection.ResponseCode;
                e = convertCopyContentToDataStreamException(e,code);
                throwAsCaller(e);
            end
        end

        %------------------------------------------------------------------

        function copyContentToFile(obj, filename)
         % Copy the content from the Web service to a file.

            openConnection(obj);
            closeObj = onCleanup(@()closeConnection(obj));
            try
                copyContentToFile(obj.Connection, filename);
            catch e
                code = obj.Connection.ResponseCode;
                e = convertCopyContentToDataStreamException(e,code);
                throwAsCaller(e);
            end
        end

        %------------------------- set/get methods ------------------------

        function set.URL(obj, url)
        % Set the URL property value by storing the value in the private
        % copy. Set the Protocol, and Proxy property values.

            % Set private copy.
            obj.pURL = url;
            obj.Connection.URL = url;

            % Get the protocol (before the ":") from the URL.
            obj.Protocol = getProtocolFromURL(url);

            % Get the proxy information using the MATLAB proxy API
            % and set the property.
            obj.Proxy = getProxySettings(url);
        end

        function url = get.URL(obj)
            url = obj.pURL;
        end

        function set.CertificateFilename(obj, filename)
            filename = matlab.net.internal.validateCertificateFile(filename);
            obj.pCertificateFilename = filename;
            obj.Connection.CertificateFilename = filename;
        end

        function filename = get.CertificateFilename(obj)
        % Get CertificateFilename from private copy.
            filename = obj.pCertificateFilename;
        end
    end

    methods (Access = 'protected')

        function tf = isRedirecting(obj)
        % Return true if the connection indicates that the URL is being
        % redirected by examining the response code.

            try
                % For all requests, redirect the same request on Found, MovedPermanently and
                % TemporaryRedirect. For GET, also redirect on SeeOther: the response may not
                % be what the user expects, but there will at least be a response.  Not
                % appropriate to redirect SeeOther for other request methods.  (RFC 7231,
                % 6.4.4)
                code = obj.Connection.ResponseCode;
                tf = any(code == [ ...
                        obj.StatusCode.Found ...
                        obj.StatusCode.MovedPermanently ...
                        obj.StatusCode.TemporaryRedirect]) || ...
                    (strcmpi(obj.RequestMethod, 'GET') && ...
                     code == obj.StatusCode.SeeOther);
            catch
                tf = false;
            end
        end

        %------------------------------------------------------------------

        function contentType = getConnectionContentType(obj)
        % Get the content type from the connection. Return unknown if any
        % error occurs. Empty may be returned if content type cannot be
        % determined. Invoking this function causes content to be
        % downloaded from the server.

            try
                contentType = obj.Connection.ContentType;
            catch e
                throwAsCaller(e)
            end

            if isempty(contentType)
            % Some servers may not have the mime types setup for
            % spreadsheet data. Check the URL extension to see if a
            % match is found.
                tableExtensions = {'.xls' '.xlsx' '.xlsb' '.xlsm' '.xltm' '.xltx' '.ods'};
                url = obj.URL;
                [~,~,ext] = fileparts(url);
                if any(strcmpi(ext, tableExtensions))
                   contentType = 'spreadsheet';
                end
            end
        end

        %------------------------------------------------------------------

        function setConnectionProperties(obj)
        % Set connection properties. These properties must be set after the
        % connection is established and will initiate data transfer from
        % the server.

            connection = obj.Connection;
            if ~isempty(connection)
                contentType = getConnectionContentType(obj);

                % Set ContentType and CharacterSet properties.
                obj.ContentType  = getContentTypeFromConnection(contentType);
                obj.CharacterSet = getCharacterSetFromConnection(contentType);
            end
        end

        %------------------------------------------------------------------

        function setRequestProperty(obj, name, value)
        % Set connection request property if name and value are not empty.
            connection = obj.Connection;
            if ~isempty(name) && ~isempty(connection) %&& strlength(value) ~= 0
                connection.setRequestProperty(name, value);
            end
        end

        %------------------------------------------------------------------

        function setDefaultRequestProperty(obj, name, value)
        % Set connection request property if it is not in the list of
        % obj.HeaderField that the user added.  Value may be empty.
            connection = obj.Connection;
            if ~isempty(name) && ~isempty(connection) && ...
                    (isempty(obj.HeaderFields) || ~any(strcmpi(obj.HeaderFields(:,1), name)))
                connection.setRequestProperty(name, value);
            end
        end

        %------------------------------------------------------------------

        function setRequestProperties(obj)
        % Set the obj property values on the connection.

            % The set order is important. Certain property manipulations
            % will invoke the connect method of the connection. After
            % connection, setting certain properties, such as Accept, can
            % cause an exception.

            % Assign a local variable for the connection.
            connection = obj.Connection;

            % Set Request method.
            if any(strcmpi(obj.Protocol, ["http", "https"]))
                connection.RequestMethod = upper(obj.RequestMethod);

                % Set PostData and MediaType if RequestMethod is POST, PUT or PATCH
                 if any(strcmpi(obj.RequestMethod, ["POST", "PUT", "PATCH"]))
                   connection.PostData = obj.PostData;

                    % If CharacterEncoding has been specified and the
                    % MediaType is not application/x-www-form-urlencoded,
                    % then add a "charset=" parameter to MediaType with the
                    % value set to the value of CharacterEncoding. charset
                    % values are not needed for form-encoded data since the
                    % data is already encoded.  Also, don't add the CharacterEncoding
                    % if the MediaType object already contains a charset.
                    if isempty(obj.CharacterEncoding) || ...
                            strcmp('auto',obj.CharacterEncoding) || ...
                            strcmp('application/x-www-form-urlencoded',obj.MediaType) || ...
                            ~isempty(obj.RealMediaType.getParameter('charset'))
                        mediaType = obj.RealMediaType;
                    else
                        mediaType = obj.RealMediaType.setParameter('charset',obj.CharacterEncoding);
                    end
                    chars = char(mediaType);
                    % The following line is ignored by HTTPJavaConnectionAdapter
                    obj.MediaType = chars;
                    % For HTTPConnectionAdapter, this line is redundant with above.
                    % It's needed for HTTPJavaConnectionAdapter.
                    obj.setDefaultRequestProperty('Content-Type', chars);
                end
            end

            % Set User-Agent, if not empty.
            userAgent = obj.UserAgent;
            if ~isempty(userAgent)
                setDefaultRequestProperty(obj, 'User-Agent', userAgent);
            end

            % Set Accept-Encoding field
            setDefaultRequestProperty(obj, 'Accept-Encoding', 'gzip, deflate');
            connection.Decode = obj.Decode;

            % Obtain KeyName and KeyValue values.
            [keyName, keyValue] = ...
                checkRequestProperty(obj, 'KeyName', 'KeyValue');

            % Set the Accept request property if options.ContentType is
            % xmldom or json and KeyName is not Accept.
            if ~strcmp(keyName, 'Accept')
                setAcceptRequestProperty(obj);
            end

            % Set Key name and value, if KeyName is not empty. (Allow an
            % empty KeyValue to be passed to the server.) The key
            % name/value pair may override the Authorization value, if set.
            if ~isempty(keyName)
                if ~ischar(keyValue)
                    keyValue = num2str(keyValue);
                end
                setDefaultRequestProperty(obj, keyName, keyValue);
            end

            % HeaderFields was already verified by weboptions to be an n-by-2 cellstr
            % or string matrix, so calling cellstr converts them to a cellstr.  These fields
            % will replace any similarly-named fields we already added.
            if ~isempty(obj.HeaderFields)
                headers = cellstr(obj.HeaderFields);
                cellfun(@(n,v)setRequestProperty(obj, n, v), ...
                         headers(:,1), headers(:,2));
            end
            % For POST and PUT requests if there is no data present
            % in the body of the request the Content-Length of the
            % request header should be set to zero.
            if((strcmpi(obj.RequestMethod, 'post') || strcmpi(obj.RequestMethod, 'put')) && ...
               isempty(obj.PostData))
                    obj.setDefaultRequestProperty('Content-Length', '0');
            end

        end

        %------------------------------------------------------------------

        function setAcceptRequestProperty(obj)
        % Set the Accept request property if options.ContentType is xmldom
        % or json.

            % Some RESTful Web servers send either XML or JSON responses.
            % Set the Accept header property, if either of these content
            % types are requested.
            optionsContentType = obj.OptionsContentType;
            index = strcmp(optionsContentType, {'auto', 'json', 'xmldom'});
            if any(index)
                if index(1) || index(2)
                    % JSON is requested, set the Accept header property to
                    % application/json.
                    contentType = 'application/json';
                else
                    % XML is requested, set the Accept header property to
                    % text/xml
                    contentType = 'text/xml';
                end

                % Add all others as secondary types.
                contentType = [contentType ', */*'];

                % Set the request property.
                try
                    setDefaultRequestProperty(obj, 'Accept', contentType);
                catch
                    % Ignore this error. We are only trying to assist in
                    % specifying the Accept value. In most cases, it is not
                    % needed anyway.
                end
            end
        end

        %------------------------------------------------------------------

        function openRedirectConnection(obj)
        % Open redirect connection if the redirect URL is valid.

            url = obj.Connection.RedirectURL;
            if ~isempty(url)
                if obj.Debug
                    disp(['Redirecting to ' url]);
                end
                % Reset URL to new location.  Just in case the url contains non-ASCII
                % characters, process it using URI to get the encoded version.
                url = matlab.net.URI(url,'literal');
                obj.URL = char(url);

                % Redirecting to a different URL.
                % Ensure connection is closed.
                closeConnection(obj);

                % Try again to open URL connection.
                openConnection(obj);
            else
                % Close the redirection attempt since the redirect URL is
                % not valid.
                obj.NumberOfRedirects = obj.MaximumRedirects + 1;
            end
        end

        %------------------------------------------------------------------

        function encoding = getEncoding(connector)
            contentEncoding = connector.Connection.ContentEncoding;
            encoding = 0;
            if ~strcmp('binary', connector.OptionsContentType)
                switch lower(contentEncoding)
                    case 'gzip'
                        encoding = 1;
                    case 'deflate'
                        encoding = 2;
                end
            end
        end
    end
end

%--------------------------------------------------------------------------

function obj = setProperties(obj, options)
% Generic function that sets the public property values of obj with the
% matching properties of options only if obj and options are non-empty and
% scalar objects.

if isobject(obj) && isscalar(obj) && isobject(options) && isscalar(options)
    names = properties(options);
    mc = metaclass(obj);
    index = strcmp('public', {mc.PropertyList.SetAccess});
    props = {mc.PropertyList.Name};
    props = props(index);
    for k = 1:length(names)
        prop = find(strcmpi(names{k}, props),1);
        if ~isempty(prop)
            obj.(props{prop}) = options.(names{k});
        end
    end
    % these properties are hidden, so copy explicitly
    obj.Debug = options.Debug;
    obj.NativeDebug = options.NativeDebug;
end
end

%--------------------------------------------------------------------------

function proxy = getProxySettings(url)
% Get proxy settings from MATLAB preferences panel. If settings are not
% found in MATLAB then system proxy settings will be used.
% This calls into C++ to get the settings which
% returns a struct with fields {"Host", "Port", "Username", "Password"}
proxy = matlab.internal.webservices.getProxyInfo(url);
end

%--------------------------------------------------------------------------

function protocol = getProtocolFromURL(url)
% Get protocol (http or https) from URL.

protocol = url(1:find(url == ':', 1) -1);
end

%--------------------------------------------------------------------------

function contentType = getContentTypeFromConnection(connectionContentType)
% Get content type from connection content type. The connection content
% type may include the character set.

index = find(connectionContentType == ';', 1) - 1;
if ~isempty(index)
    index = index(1);
else
    index = length(connectionContentType);
end
contentType = connectionContentType(1:index);
end

%--------------------------------------------------------------------------

function charSet = getCharacterSetFromConnection(connectionContentType)
% Get character set from connection content type. The default value if not
% found is left as empty.

defaultCharacterSet = '';
index = find(connectionContentType == ';', 1) + 1;
if isempty(index)
    charSet = defaultCharacterSet;
else
    charSet = connectionContentType(index:end);
    if ~isempty(charSet) && ~all(isspace(charSet))
        charsetMatch = regexpi(charSet,'charset=([a-z0-9\-\.:_])*','tokens','once');
        if ~isempty(charsetMatch)
            charSet = charsetMatch{1};
        else
            % The sub-string "charset=" was not found in connectionContentType.
            charSet = '';
        end
    end
end
end

%--------------------------------------------------------------------------

function milliseconds = secondsToMilliseconds(seconds)
% Convert to milliseconds.  No upper bound.  Input may be empty but must not be
% negative.
if ~isempty(seconds)
    % Use ceil to prevent the calculation from reaching 0.
    secondsToMilliseconds = 1000;
    milliseconds = round(ceil(seconds*secondsToMilliseconds));
else
    % The value is empty, set to the minimum.
    milliseconds = 1;
end
end

%--------------------------------------------------------------------------

function [name, value] = checkRequestProperty(obj, propName, propValue)
% Ensure that if propName is set, then propValue may be set or empty.
% If propValue is set, then propName must also be set.

name  = obj.(propName);
value = obj.(propValue);

% If propValue is set, then propName must be set.
propValueIsSet = ~isempty(value);
if propValueIsSet && isempty(name)
    id = 'MATLAB:webservices:ExpectedNonempty';
    error(message(id, ['options.' propName]));
end
end

%--------------------------------------------------------------------------

function e = convertCopyContentToDataStreamException(e, responseCode)
% Convert an MException with CopyContentToDataStream ID to an exception
% with an ID that contains the HTTP status code.

id = 'MATLAB:webservices:StatusError';
if strcmp(e.identifier, id) && ~isempty(responseCode)
    responseCode = num2str(responseCode);
    id = ['MATLAB:webservices:HTTP' responseCode 'StatusCodeError'];
    e = MException(id, '%s', e.message);
end
end

%--------------------------------------------------------------------------

function secret = getSecretFromValue(value)
if class(value) == "secretID"
    value = getSecret(value);
end
secret = value;
end