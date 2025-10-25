function out = processHTTPRequest(uri, inputs, options, readFcn)

% Copyright 2020 The MathWorks, Inc.

if ~readFcn % urlwrite function called
    postData = '';
    if ~isempty(inputs.post)
        options.RequestMethod = 'POST';
        [postData, options] = validatePostData(inputs.post, options);
    else
        options.RequestMethod = 'GET';
    end
    url = matlab.internal.webservices.urlencode(uri, options, inputs.get{:});
    connection = openHTTPConnection(url, options, postData, false);
    copyContentToFile(connection, inputs.filename);
    out = inputs.filename;
    
else % urlread function called
    if ~isempty(inputs.post)
        options.RequestMethod = 'POST';
        url = matlab.internal.webservices.urlencode(uri, options, inputs.get{:});
        [postData, options] = validatePostData(inputs.post, options);
        connection = openHTTPConnection(url, options, postData, false);
    else
        options.RequestMethod = 'GET';
        url = matlab.internal.webservices.urlencode(uri, options, inputs.get{:});
        connection = openHTTPConnection(url, options, '', false);
    end
    charset = findCharset(connection, inputs);
    byteArray = copyContentToByteArray(connection);
    out = native2unicode(byteArray',charset);
end
end

function connection = openHTTPConnection(url, options, postData, decode)
if strcmpi(options.MediaType, 'auto')
    % if MediaType still remains auto, set it to the default for consistency with
    % legacy behavior
    options.MediaType = 'application/x-www-form-urlencoded';
end

connection = matlab.internal.webservices.HTTPConnector(url, options);
connection.PostData = postData;
connection.Decode = decode;
openConnection(connection);
end

function result = findCharset(connection, inputs)
if ~isempty(inputs.charset)
    result = inputs.charset;
elseif ~isempty(connection.CharacterSet)
    result = connection.CharacterSet;
else
    result = 'utf-8';
end
end

function [postData, options] = validatePostData(postData, options)

% Validate and encode postDataName, postDataValue.
requestName  = 'postName';
requestValue = 'postValue';
if strcmpi(options.MediaType,'auto')
    options.MediaType = 'application/x-www-form-urlencoded';
end
try
    postData = matlab.internal.webservices.formencode( ...
        options, postData, requestName, requestValue);
catch
    ME = MException('MATLAB:PostFailed', 'Post params incorrect');
    throw(ME);
end
end