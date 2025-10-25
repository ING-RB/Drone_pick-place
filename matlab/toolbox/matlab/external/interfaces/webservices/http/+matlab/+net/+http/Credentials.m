classdef (Sealed) Credentials < handle & matlab.mixin.Copyable & matlab.mixin.CustomDisplay
    % Credentials Credentials for authenticating HTTP requests
    %   You may include a vector of these Credentials in the HTTPOptions.Credentials
    %   property to specify authentication credentials when sending a RequestMessage
    %   to servers that may require authenticaiton. The RequestMessage.send method
    %   uses these credentials to respond to authentication challenges from servers
    %   or proxies. The authentication challenge from the server or proxy is
    %   contained in an AuthenticateField (with the name 'WWW-Authanticate' or
    %   'Proxy-Authenticate') and specifies one or more AuthenticationSchemes that
    %   the server or proxy is willing to accept to satisfy the request.
    %
    %   Exact behavior depends on the AuthenticationScheme, but in general MATLAB
    %   searches the vector of Credentials for one that applies to the request URI
    %   and which supports the specified AuthenticationScheme, and resends the
    %   original request with appropriate credentials in an AuthorizationField
    %   header. If multiple Credentials apply, the "most specific" one for the
    %   strongest scheme is used. If there are duplicates, the first one is used.
    %
    %   If the server requires schemes other than the ones MATLAB implements
    %   (AuthenticationSchemes whose numeric values are >= 0), or if you do not
    %   supply Credentials for the required scheme, you will receive the
    %   authentication response message (which will have a StatusCode of 401 or 407)
    %   and you must implement the appropriate response yourself.
    %
    %   For schemes that do not require a username or password, such as NTLM and
    %   Negotiate (the scheme name for SPNEGO) on Windows, a successful
    %   authentication to any server can occur simply by providing a default
    %   Credentials object, with default or empty properties, in HTTPOptions,
    %   because a default Credentials object applies to all supported schemes and
    %   URIs. In such cases your authorization credentials come from information
    %   stored in your system when you logged in, such as Kerberos tickets. However
    %   you may specify additonal properties such as Scope and Realm if you want to
    %   constrain the conditions under which a particular scheme is used. For
    %   example you may want NTLM to be used for some URLs and Kerberos for others,
    %   and reject authentication requests from servers that do not match those URLs
    %   and schemes. Note that a default HTTPOptions object contains a default
    %   Credentials object that allows these schemes.
    %
    %   For schemes that require a username or password, once MATLAB carries out a
    %   successful authentication using a Credentials object, MATLAB saves the
    %   results in this Credentials object so that it can proactively apply these
    %   credentials on subsequent requests without waiting for an authentication
    %   challenge from the server. To take advantage of this, provide the same
    %   Credentials instance on subsequent requests, in the same or other
    %   HTTPOptions objects.
    %
    %   This object is a handle, as it internally accumulates information about prior
    %   (successful) authentications, so that the information can be reused for
    %   subsequent messages. If you insert this object into multiple HTTPOptions, it
    %   may be updated on each use. You may copy the object using the copy method,
    %   but that only copies the visible properties that you have set, not the
    %   internal state.
    %
    %   Credentials properties:
    %      Scheme            - vector of AuthenticationScheme to which Credentials applies
    %      Scope             - vector of URI to which Credentials applies
    %      Realm             - vector of string, the realm(s) to which this Credentials applies
    %      Username          - string, the username to use for authentication
    %      Password          - string, the password to use for authentication
    %      GetCredentialsFcn - function handle, to obtain username and password
    %                          without embedding them in this object
    %
    %   Credentials methods:
    %      Credentials       - constructor
    %
    %   Example:
    %
    %      % insure these credentials sent only to appropriate server
    %      scope = URI('http://my.server.com');
    %      creds = Credentials('Username','John','Password','secret','Scope',scope);
    %      options = HTTPOptions('Credentials',creds);
    %      % if the server requires authentication, the following transaction will 
    %      % involve an exchange of several messages
    %      req = RequestMessage;
    %      resp = req.send(scope, options);
    %      ...
    %      % later, reuse same options that contains same credentials
    %      % since credentials already used successfully, this transaction will only
    %      % require a single message
    %      resp = req.send(scope, options)
    %
    % See also HTTPOptions.Credentials, AuthenticationScheme, RequestMessage
    % StatusCode
    
    % Copyright 2015-2024 The MathWorks, Inc.
    properties
        % Scheme - vector of AuthenticationScheme to which the credentials apply
        %   Default specifies all the schemes implemented by MATLAB (those whose
        %   AuthenticationScheme value is non-negative). If empty, it applies to all
        %   defined AuthenticationScheme values.
        %
        %   If you set this to AuthenticationScheme.Basic only, these credentials may be
        %   automatically sent in a request (in an AuthorizationField) whether or not
        %   the server requests authentication. This avoids an extra round trip
        %   responding to an authentication challenge (since Basic does not require a
        %   challenge), but could be undesirable if you are not sure whether the server
        %   requires Basic authentication, as it exposes the Username and Password to
        %   the netowrk and the server.
        %
        %   If this property mentions any scheme besides (or in addition to) Basic, or
        %   it is empty (thus allowing all schemes), then no authorization information
        %   will be sent to the server until the server responds with a challenge (such
        %   as a WWW-Authenticate field) that tells MATLAB what authentication scheme(s)
        %   the server desires. Then MATLAB will choose the strongest scheme listed
        %   among the Credentials you specify, which also match the Scope and Realm you
        %   specify (if set). Subsequent messages to that same server (with the same
        %   Scope) will include the appropriate authorization information without first
        %   requiring a challenge.
        %
        %   See also AuthenticationScheme, Scope, Realm, matlab.net.URI
        Scheme matlab.net.http.AuthenticationScheme = ...
            matlab.net.http.AuthenticationScheme.getSupportedSchemes()
        
        % Scope - vector of URI or strings to which the credentials apply
        %   The strings must be acceptable to the URI constructor, or of the form
        %   "host/path/..."  Values in this vector are compared against the URI in the
        %   request to determine whether this Credentials object applies. Normally
        %   this Credentials applies if the request URI refers to the same host at a
        %   path at or deeper than one of the URIs in this Scope. For example a Scope
        %   containing URI naming a host, with no path, applies to request URIs for
        %   all paths on that host.
        %
        %   Only the Host, Port and Path portions of the Scope URIs are used.
        %   Typically you would just specify a Host name, such as
        %   'www.mathworks.com', but you can include a Path, or portion of one, if
        %   you know that the credentials are needed only for some paths within that
        %   Host. A Host of 'mathworks.com' would match a request to
        %   'www.mathworks.com' as well as 'anything.mathworks.com'. A URI of
        %   'mathworks.com/foo/bar' would match a request to
        %   'www.mathworks.com/foo/bar/baz' but not to 'www.mathworks.com/foo'
        %   because the latter has a path '/foo' that is not at or deeper than
        %   '/foo/bar'.
        %
        %   An empty Scope (default), or an empty Host or Path in this vector matches
        %   all Hosts or Paths. You should not leave this property empty if Scheme
        %   is set to Basic only, unless you are careful to send your requests only
        %   to trusted servers, as this would send your Username and Password to any
        %   servers you access using the HTTPOptions containing this Credentials
        %   object.
        %
        %   See also matlab.net.URI, AuthenticationScheme, Username, Password
        Scope
        
        % Realm - vector of regular expressions describing realms for credentials
        %   This may be a string array, character vector, or cell array of character
        %   vectors. A realm is a string specified by the server in an AuthenticateField
        %   of of the ResponseMessage that is intended to be displayed to the user, so
        %   the user knows what name and password to use. It is useful when a given
        %   server requires different logins for different URIs.
        %
        %   The realm expressions in this list are compared against the
        %   authentication realm in the server's authentication challenge, to
        %   determine whether this Credentials object applies. Once MATLAB carries
        %   out a successful authentication using one of these realms, MATLAB will
        %   proactively apply this Credentials object to subsequent requests (using
        %   this same Credentials object) to the same Host and Path in the request
        %   URI without requiring another authentication challenge from the server,
        %   or a call to GetCredentialsFcn, on every request.
        %
        %   If you want to anchor the regular expression the start or end of the
        %   authentication realm string, include the '^' or '$' as appropriate.
        %
        %   If this property is empty it is considered to match all realms. If any value
        %   in this vector is an empty string, it only matches an empty or unspecified
        %   realm.
        %
        %   In general you would leave this property empty. Use it only if you want
        %   to specify different Credentials for different realms on the same server
        %   and are not prompting the user for a name and password.
        %
        %   This property is only used to determine which Credentials object to select
        %   on the response to the challenge in the AuthenticateField, which typically
        %   happens only on the first message to a given server in a given scope. After
        %   a successful authentication, subsequent messages to that same scope will
        %   proactively send authorization information without requiring a challenge.
        %
        %   See also regexp, AuthenticationScheme, GetCredentialsFcn
        Realm string
        
        % Username - user name for authentication
        %   This property applies only to schemes that require an explicit username
        %   and password, and not for schemes that get your credentials from the system:
        %   This includes Basic and Digest schemes and NTLM on Linux.
        %
        %   If you set this and the Password property to any string (including an
        %   empty one) this user name will be used for authentication in any request
        %   for which this Credentials object applies, unless GetCredentialsFcn is
        %   specified. If you set this to [] and a username is required, then you
        %   must specify a GetCredentialsFcn or authentication will not be attempted.
        %
        %   If you do not want to embed a username in your code then leave this empty
        %   and specify a GetCredentialsFcn that prompts the user for a name, or obtains
        %   it from another source.
        %
        %   See also GetCredentialsFcn, AuthenticationScheme
        Username
        
        % Password - password for authentication
        %   This property applies only to schemes that require an explicit username
        %   and password, and not for schemes that get your credentials from the system:
        %   This includes Basic and Digest schemes and NTLM on Linux.
        %
        %   If you set this and the Username property to any string (including an empty
        %   one) this password will be used for authentication in any request for which
        %   this Credentials object applies, unless GetCredentialsFcn is specified. If
        %   you set this to [] and there is no GetCredentialsFcn, then no password will
        %   be provided.
        %
        %   If you do not want to embed a password in your code then leave this empty
        %   and specify a GetCredentialsFcn that prompts the user for a password, or
        %   obtains it from another source.
        %
        %   See also GetCredentialsFcn, AuthenticationScheme
        Password
        
        % GetCredentialsFcn - handle to function providing username and password
        %  This property applies only to schemes requiring you to specify a username
        %  and password.
        %
        %  If you set this property, this function will be called to obtain the username
        %  and password to use for the authentication response, whether or not the
        %  Username or Password properties in this Credentials object are set. This
        %  function must take 3-6 input arguments and return at least 2 outputs, with
        %  the following signature:
        %
        %  [username,password] = GetCredentialsFcn(cred,request,response,authInfo,...
        %                                          previousUsername,previousPassword)
        %
        %     cred      handle to this Credentials object
        %     request   the last sent RequestMessage that provoked this
        %               authentication challenge. 
        %     response  the ResponseMessage from the server containing an
        %               AuthenticateField. May be empty if this function is being
        %               called prior to getting a response (possible if this
        %               cred.Scheme specifies Basic as the only option).
        %     authInfo  (optional) one element in the vector of AuthInfo returned by 
        %               AuthenticateField.convert() that MATLAB has selected to match
        %               with this Credentials object. Each object in this array will
        %               have a Scheme and at least a 'realm' parameter. If you have no
        %               use for this information you needn't specify this argument.
        %     previousUsername, previousPassword (optional)
        %               Initially empty. If non-empty, these are the values the
        %               GetCredentialsFcn returned in a previous invocation, but which
        %               were rejected by the server. If you are not prompting the user
        %               for credentials, you should compare these values to the ones you
        %               plan to return. If they are the same, authentication will likely
        %               fail again, so return [] for the username to indicate that
        %               MATLAB should give up and return an authentication failure. If
        %               you are prompting the user for credentials you needn't specify
        %               these arguments, as the user can choose whether to re-enter the
        %               same or different credentials.
        %     username  the username that MATLAB should use. It may be '' or "", to
        %               indicate the username should be left empty (some servers may
        %               require only a password, not a username), but if [] this says
        %               MATLAB should give up and abort the authentication.
        %     password  the password that MATLAB should use.
        %
        %  By implementing this function and leaving the Username and/or Password in
        %  this Credentials empty, you can implement a prompt or other mechanism to
        %  obtain these values from the user without embedding them in your program.
        %  In your prompt, you may want to display the URI of the request and/or the
        %  realm from authInfo. Another convenient pattern may be to set the Username in
        %  the Credentials object and prompt only for the password. Your prompt can
        %  display that existing Username (or the previousUsername, if set) and give
        %  the user the option to change it.
        %  
        %  The function can examine this Credentials object (the cred argument) as well
        %  as header fields in the request and response to determine which resource is
        %  being accessed, so it can prompt the user for the correct credentials. In
        %  general the prompt should display the realm parameter of authInfo to let the
        %  user know the context of the authentication.
        %
        %  Since the Credentials is a handle class, this function can store the desired
        %  username and password in the cred argument passed in, so that they will be
        %  reused for future requests without invoking the function again. Usually this
        %  is not necessary, as MATLAB already saves a successful username and password
        %  internally so it can apply them to future requests. But MATLAB may not always
        %  be able to determine whether the same username and password apply to
        %  different requests using this Credentials object.
        %
        %  If the function returns [] (as opposed to an empty string) for the username,
        %  this means that authentication should be denied and MATLAB returns the
        %  server's authentication failure response message to the caller of
        %  RequestMessage.send. This is appropriate behavior if you are implementing a
        %  user prompt and the user clicks cancel in the prompt. If you are supplying
        %  the username and password programmatically rather than propmting the user,
        %  you must return [] if the previousUsername and previousPassword arguments
        %  passed in are identical to the username and password that you would return
        %  (thus indicating that your credentials are not being accepted and you have no
        %  alternative choice). Otherwise, an infinte loop might occur calling your
        %  GetCredentaislFcn repeatedly.
        %
        %  This is an example of a simple GetCredentialsFcn that prompts the user,
        %  that fills in the Username from the Credentials object as a default:
        %
        %    function [u,p] = getMyCredentials(cred, req, resp, authInfo)
        %        prompt = ["Username:" "Password:"];
        %        defAns = [cred.Username ""];
        %        title = "Credentials needed for " + getParameter(authInfo,'realm');
        %        answer = inputdlg(prompt, title, [1, 60], defAns, 'on');
        %        if isempty(answer)
        %            u = [];
        %            p = [];
        %        else
        %            u = answer{1};
        %            p = answer{2};
        %        end
        %    end
        %
        %  The above function prevents the password from being stored in any 
        %  accessible property.
        %
        %  See also RequestMessage, Username, Password, AuthInfo
        %  matlab.net.http.field.AuthenticateField
        GetCredentialsFcn 
    end
    
    properties (Access=private)
        % CredentialInfos - Vector of matlab.internal.webservices.CredentialInfo used
        %   for Basic or Digest authentication, created or updated by updateCredential()
        %   containing information needed to authenticate subsequent requests using this
        %   Credentials object without waiting for an authentication challenge from the
        %   server. Not used for other schemes.
        %
        %   On each new request we first search all CredentialInfos in all Credentials
        %   objects to see if any one applies to the request URI. If we find none, we
        %   search the Credentials objects to look for the most specific match. If we
        %   find no matching Credentials object we send the request without
        %   authentication. In this case a response containing an authentication
        %   challenge (401 or 407) can't be answered and we'll return the challenge to
        %   the user.
        %
        %   If we don't find a CredentialInfo (which means we never authenticated to
        %   this URI using Basic or Digest), and the most specific matching Credentials
        %   object specifies only AuthenticationScheme.Basic, we send those credentials
        %   with the request. If the most specific matching Credentials specifies a
        %   scheme other than Basic, or its Scheme is empty, we send the request without
        %   credentials. If the server comes back with an authentication challenge that
        %   for Basic or Digest (saved as AuthInfo), we once again look for the most
        %   specific matching Credentials object (this time using information in the
        %   challenge such as Scheme and Realm, as well as the URI) and use its
        %   credentials to respond to the challenge.
        %   
        %   When an authentication is successful, we add a new CredentialInfo object
        %   to this array in Credentials object from which we obtained the
        %   credentials.
        %
        %   If we find a CredentialInfo object in that matches the request URI, which
        %   means we previously authenticated using that CredentialInfo, MATLAB will
        %   update the CredentialInfo and send its credentials with the request,
        %   without waiting for a challenge. If authentication fails (i.e., we get a
        %   challenge anyway), and the URI in the CredentialInfo is identical to that
        %   in the request, we delete the CredentialInfo and retry the request as if
        %   there had been no CredentialInfo. If the URI is not an exact match, or
        %   if we deleted the CredentialInfo, we go back to the paragraph above as if
        %   we never authenticated to this URI.
        %
        %   We never remove an entry from this list unless its URI exactly matches
        %   that of a request whose authentication has failed. For example, say we
        %   add an entry for www.mathworks.com/foo. If a subsequent request is for
        %   www.mathworks.com/foo/bar, we try to use the existing entry. If it
        %   succeeds, we just update the existing entry. If it fails, we
        %   authenticate from scratch and if that succeeds, we add a new entry for
        %   www.mathworks.com/foo/bar and keep both. If a subsequent request comes
        %   in for www.mathworks.com/foo/baz, we again try to use the first entry, as
        %   it's the only one that matches. If authentication with that entry fails,
        %   we again start from scratch and add a 3rd entry for
        %   www.mathworks.com/foo/baz. 
        %
        %   This property is not copied by the copy() method.
        CredentialInfos = matlab.net.http.internal.CredentialInfo.empty
    end
    
    
    methods
        function obj = Credentials(varargin)
        %Credentials constructor
        %   CREDENTIALS = Credentials(Name,Value) returns a Credentials object with
        %   named properties initialized to the specified values. Unnamed properties get
        %   their default values, if any. If you call this constructor with no
        %   arguments, the Credentials object applies to and thus permits authentication
        %   for all URIs and all authentication schemes, but it will only work for
        %   schemes that do not require a username or password. For example, on Windows,
        %   it will enable NTLM and Kerberos authentication using the credentials of
        %   the logged-in user.
        
        % Undocumented behavior: allow a single argument that is a Credentials array
        % which returns handle to same array, or [] which returns empty array.
            if nargin ~= 0
                arg = varargin{1};
                if isempty(arg) && isnumeric(arg)
                    obj = matlab.net.http.Credentials.empty;
                else
                    if nargin == 1 && isa(arg,class(obj))
                        obj = arg;
                    else
                        obj = matlab.net.internal.copyParamsToProps(obj, varargin);
                    end
                end
            end
        end
        
        function set.Scope(obj, value)
            import matlab.net.internal.*
            if isempty(value)
                obj.Scope = matlab.net.URI.empty;
            elseif isa(value, 'matlab.net.URI')
                obj.Scope = value;
            else
                value = getStringVector(value, mfilename, 'Scope');
                res = arrayfun(@matlab.net.URI.assumeHost, value, 'UniformOutput', false);
                obj.Scope = [res{:}];
            end
        end
       
        function set.Realm(obj, value)
            import matlab.net.internal.*
            if isempty(value)
                obj.Realm = [];
            else
                obj.Realm = getStringVector(value, mfilename, 'Realm');
            end
        end
        
        function set.Scheme(obj, value)
            import matlab.net.internal.*
            if isempty(value)
                obj.Scheme = [];
            elseif isa(value, 'matlab.net.http.AuthenticationScheme')
                obj.Scheme = value;
            else
                value = getStringVector(value, mfilename, 'Scheme', true, ...
                                        'matlab.net.http.AuthenticationScheme');
                obj.Scheme = matlab.net.http.AuthenticationScheme(value);
            end
        end
        
        function set.Username(obj, value)
            import matlab.net.internal.*
            if ~isempty(value)
                value = mustBeStringOrSecretIDScalar(value, "Username");
            end
            obj.Username = value;
        end
        
        function set.Password(obj, value)
            import matlab.net.internal.*
            if ~isempty(value)
                value = mustBeStringOrSecretIDScalar(value, "Password");
            end
            obj.Password = value;
        end
        
        function set.GetCredentialsFcn(obj, value)
            if ~isempty(value)
                validateattributes(value, {'function_handle'}, {'scalar'}, ...
                                   mfilename, 'GetCredentialsFcn');
                if (nargin(value) >= 0 && nargin(value) < 3) || ...
                        (nargout(value) >= 0 && nargout(value) < 2)
                    error(message('MATLAB:http:GetCredentialsFcnError', ...
                        nargin(value), nargout(value), 3, 1));
                else
                end
            else
            end
            obj.GetCredentialsFcn = value;
        end
    end
    
    methods (Access={?matlab.net.http.RequestMessage,?tHTTPCredentialsUnit})
        function [creds, cred, schemes] = getCredentials(obj, uri, authInfos)
        % getCredentials - get Credentials object in a vector of Credentials objects, 
        %   for the uri and optional authInfos taken from a challenge ResponseMessage,
        %   choosing the one with the best match for the strongest scheme.
        %
        %   obj       array of Credentials
        %   uri       URI of request
        %   authInfos vector of AuthInfos (challenges) in the response message; empty 
        %             if no challenge received yet, in which case we choose the best
        %             matching credential based on URI and scheme only. There is rarely
        %             more than one of these, but some servers offer multiple choices.
        %   creds     all Credentials whose Scope.Host matches uri.Hostm and, if authInfo 
        %             specified, authInfo.scheme allowed by Scheme and authInfo.realm to
        %             Realm. If no authInfo specified, sorted by best match to Host. If
        %             authInfo specified, sorted by strongest match of Scheme and then
        %             Host.
        %   cred      if authInfos empty, the first Credentials in creds that contains
        %             a credInfo (meaning we authenticated before using Basic/Digest).
        %             If authInfos empty and no credInfo found, the best matching one in
        %             creds based on Scope.Host and Scope.Path to uri and strongest
        %             Scheme. If authInfos set, the best matching one that additionally
        %             looks Scheme and Realm. [] if none found.
        %   schemes   allowed schemes. This is union of all creds.Scheme; [] if any
        %             creds.Scheme is empty implying all schemes are allowed. These are
        %             the schemes with we'll be willing to use in addition to the one(s)
        %             in cred. 
        %
        % Returns [] if there is no match.
        %
        % See getCredentialsInternal() description for more information.
        %
        % This function is designed to be called in 2 cases
        %   1. After an "unauthorized" response from a server indicating that
        %      authentication failed or was required. The uri is the URI of the request
        %      message and the authInfos is information in the server's response message
        %      containing the WWW-Authenticate or Proxy-Authenticate AuthenticationField
        %      contents (there may be more than one such field, but both types won't
        %      appear in the same message). In this case we search the Credentials in
        %      obj array for a match of:
        %          Scope to uri
        %          Scheme and Realm to the Scheme and 'realm' in authInfos
        %      and return return the "strongest" matching cred based on Scheme.
        %   2. Before any send, other than response to a challenge.
        %      This is to determine if we have previously successfully authenticated
        %      with the server or proxy to be contacted, using one of the Credentials
        %      objects in obj, or to determine whether to proactively send
        %      credentials in a request using Basic authentication. In this case the
        %      uri is the URI of the request and authInfo is empty. 
        %
        % Matching algorithm looks at these matches, where an empty value on the
        % right matches anything on the left, and an empty value on the left only
        % matches an empty value on the right. All these have to match in order for
        % a Credential to be selected.
        %
        %      authInfo.Scheme in obj.Scheme (if authInfo specified)
        %      uri.Host        == obj.Scope.Host, anchored to end of uri.Host
        %      uri.Path        == obj.Scope.Path, anchored to start of uri.Path
        %    if authInfo set:
        %      authInfo.Realm  == obj.Realm, general regexp
        %    
        % In case of multiple matches, the most specific (highest priority) match in
        % the first field above wins. If there is more then one most specific match
        % in the first matching field, then the most specific in the next field down
        % wins, etc. By "most specific" we mean "longest", except that a match with
        % an empty on the right is considered least specific. If there are multiple
        % equally specific matches, we return the one with the strongest Scheme.
        %
        % If authInfo is a vector naming different Schemes, do the above search
        % first with the strongest Scheme, based on the abs value of the Scheme.
        %
        % For example, for the uri www.internal.mathworks.com/foo/bar the following
        % Scopes match, from most specific to least:
        %
        %                                  uri.Host==Scope.Host  uri.Path==Scope.Path
        %    internal.mathworks.com/foo/bar       full                 full
        %    internal.mathworks.com/foo           full                 partial
        %    internal.mathworks.com               full                 empty
        %    mathworks.com/foo/bar                partial              full
        %    mathworks.com/foo                    partial              partial
        %    mathworks.com                        partial              empty
        %    /foo/bar                             empty                full
        %    /foo                                 empty                partial
        %    empty                                empty                empty
        
            import matlab.net.http.*
            if isempty(authInfos)
                % No challenge; try for proactive authentication. 
                [creds, cred, schemes] = getCredentialsInternal(obj, uri, []);
            else
                creds = Credentials.empty;
                schemes = AuthenticationScheme.empty;
                % We got a challenge. Find the authInfo among authInfos that 
                % specifies the strongest scheme MATLAB supports.
                supportedSchemes = AuthenticationScheme.getSupportedSchemes();
                cred = Credentials.empty;
                % matches returns true if a (an AuthenticationScheme, string or empty) is equal
                % to AuthenticationScheme b
                matches = @(a,b) ~isempty(a) && ~isstring(a) && a == b;
                % go through supported schemes, strongest to weakest
                found = false;
                for i = 1 : length(supportedSchemes)
                    % find first authInfo that matches the scheme
                    % the arrayfun returns a logical array
                    infos = authInfos(arrayfun(@(x) matches(x.Scheme,supportedSchemes(i)), authInfos));
                    if ~isempty(infos)
                        % found an authInfo for the scheme; see if we have a Credentials to match
                        [rcreds, rcred, thisScheme] = getCredentialsInternal(obj, uri, infos(1));
                        if ~isempty(rcred)
                            % found a match
                            if ~found
                                % save the first matching one, but keep looking at weaker ones
                                % in order to determine all allowed schemes
                                creds = rcreds;
                                cred = rcred;
                                schemes = thisScheme;
                                found = true;
                            else
                                % add matching scheme and creds
                                schemes = [schemes thisScheme]; %#ok<AGROW>
                                creds = [creds rcreds];  %#ok<AGROW>
                            end
                        else
                            % no Credentials for this uri + authInfo found
                        end
                    else
                        % no authInfo for the scheme
                    end
                    % go to next weaker scheme
                end
                schemes = unique(schemes);
            end
        end
        
        % addProxyCredInfo Add candidate proxy Credential info to Credentials
        %   This is used to add a CredentialInfo for a proxy that might require
        %   authentication, whose username and password came from someplace like
        %   preferences, prior to getting a challenge from a server. This
        %   CredentialInfo has an empty AuthInfo, which we set when choosing this
        %   in response to a challenge. 
        function addProxyCredInfo(obj, proxyURI, username, password)
            credInfo = matlab.net.http.internal.CredentialInfo([], proxyURI, ...
                                                          username, password, true);
            obj.addCredInfo(credInfo, false);
        end
        
        function credInfo = createCredInfo(obj, uri, req, resp, authInfos, ...
                                           forProxy, prevCredInfo, usePrevCredInfo)
        % createCredInfo Create a new CredentialInfo in this Credentials object as a
        %   candidate to be added to this Credentials object, choosing the strongest
        %   Scheme supported by both this object and authInfos (which came from the
        %   WWW-Authenticate or Proxy-Authenticate header field, or "made up" to
        %   authenticate for Basic), that has a matching Realm. Caller
        %   should try to authenticate using this returned credInfo, and if successful,
        %   caller should call addCredInfo(credInfo, true) to add it. This credInfo will
        %   be used by our caller to authenticate to the server in response to a
        %   challenge.
        %
        %   We always call the GetCredentialsFcn, if set. Otherwise we use the
        %   Username and Password in this object. In this case, if authentication
        %   using credInfo fails, caller might want to reinvoke this function, in
        %   case the GetCredentialsFcn is interacting with the user and wants to give
        %   the user another chance to type a good name and password.
        %
        %   We don't check that the Scope of this Credentials is appopriate for the
        %   uri -- that is normally done by the caller who chose this Credentials
        %   object. 
        %
        %   uri          URI of the request
        %
        %   req          RequestMessage. We don't look at this, but just
        %                pass it to the GetCredentialsFcn
        %   
        %   resp         ResponseMessage containing the challenge. We don't look at
        %                this, but just pass it to the GetCredentialsFcn. May be 
        %                empty if we're being called to proactively authenticate
        %                before a message is sent.
        %
        %   authInfos    vector of AuthInfos in all challenges in the response, or
        %                made up by caller
        %
        %   forProxy     true if this is for proxy
        %
        %   prevCredInfo initially empty. If set, this is the previous credInfo
        %                that we tried to authenticate with but failed, or which we
        %                never tried. 
        %
        %   usePrevCredInfo true if we never tried to use prevCredInfo, so use the
        %                username/password in it to make the new CredInfo instead of
        %                that in this Credentials object. This happens when the
        %                infrastructure created the prevCredInfo proactively prior to
        %                responding to any challenge based on information such as
        %                the username/password in the proxy preferences panel.
        %
        %   credInfo   empty if we can't create a CredentialInfo because this
        %              Credentials doesn't allow the Scheme or realm in any
        %              authInfos. Returns the number 0 if we couldn't get either a
        %              username or password because neither were set in this object
        %              and GetCredentialsFcn was unspecified or returned [] for
        %              username.
        %
        
            import matlab.net.http.*
            import matlab.net.http.internal.*
            
            assert(~isempty(authInfos));
            credInfo = CredentialInfo.empty;
            
            % Go through each scheme we support, strongest to weakest, supported by
            % this object. If this object supports the scheme, find an authInfo
            % with that scheme and realm that we support. If none, go to the next weakest
            % scheme.
            % get schemes this object supports, ordered by strength
            if isempty(obj.Scheme)
                schemes = matlab.net.http.AuthenticationScheme.getSupportedSchemes();
            else
                schemes = sort(obj.Scheme, 'descend'); 
                schemes = schemes(schemes >= 0); % remove MATLAB unsupported schemes
            end
            
            % For each scheme this obj supports, find the authInfo with the highest priority realm
            % match that has a matching scheme. 
            % Lauren's inline conditional: iif(cond1,act1,cond2,act2,...,true,default)
            iif = @(varargin) varargin{2*find([varargin{1:2:end}], 1)}();
            authInfo = AuthInfo.empty;
            priority = zeros(1,length(authInfos)); 
            for i = 1 : length(schemes)
                for j = 1 : length(authInfos)
                    % note authInfo.Scheme may be a string
                    if isa(authInfos(j).Scheme, 'matlab.net.http.AuthenticationScheme') && ...
                            authInfos(j).Scheme == schemes(i)
                        % priority of this authInfo's realm match
                        priority(j) = matchRealm(obj.Realm, iif, authInfos(j));
                    else
                        priority(j) = -1;
                    end
                    % sort priorities, highest to lowest
                    [priority, sorts] = sort(priority,'descend');
                    if priority(1) >= 0
                        % if highest priority real match is >=0, use the authInfo
                        authInfo = authInfos(sorts(1));
                        break;
                    else
                    end
                end
                if ~isempty(authInfo)
                    break
                else
                end
            end
            if ~isempty(authInfo)
                if isempty(obj.GetCredentialsFcn)
                    if usePrevCredInfo
                        username = prevCredInfo.Username;
                        password = prevCredInfo.Password;
                    else
                        username = obj.Username;
                        password = obj.Password;
                    end
                else
                    fcn = obj.GetCredentialsFcn;
                    if ~isempty(prevCredInfo)
                        args = {obj, req, resp, authInfo, prevCredInfo.Username, ...
                            prevCredInfo.Password};
                    else
                        args = {obj, req, resp, authInfo, [], []};
                    end
                    % only call fcn with number of args it supports, unless it takes
                    % varargin
                    fcnArgs = min(nargin(fcn),length(args));
                    if fcnArgs >= 0
                        [username, password] = fcn(args{1:fcnArgs});
                    else
                        [username, password] = fcn(args{:});
                    end
                    username = string(username);
                    password = string(password);
                end
                if isempty(username) && ~ischar(username)
                    % a username of [], not '' or "" means don't attempt authentication
                    credInfo = 0;
                else
                    assert(~isempty(authInfo) || forProxy);
                    credInfo = CredentialInfo(authInfo, uri, username, password, forProxy);
                end
            else
            end
        end
        
        function addCredInfo(obj, credInfo, force)
        % addCredInfo Add the credInfo to this object's CredentialInfos
        %   This is called after a successful authentication using credInfo, to add
        %   the credInfo to the CredentialInfos so it can be used again for a future
        %   authentication, or to adjust existing credentials that would work for
        %   this credInfo. The LastUsed time is updated in any credInfo added or
        %   adjusted.
        %
        %   The force flag applies only to basic.
        %
        %   If credInfo.Scheme is anything other than Basic, or force is true,
        %   unconditionally add the this credInfo to the end of the list. In the
        %   non-Basic case, this likely means the credInfo was using Digest, and its
        %   URIs is either one URI equal to the URI of the authenticated request that
        %   prompted its creation or its URIs are a vector of absolute URIs
        %   corresponding to all of the URIs in the credInfo.AuthInfo.domain array.
        %   In the Basic/force case, this means that we already tried to proactively
        %   authenticate using all existing CredentialInfos that satisfied the prefix
        %   match, but none worked, or there was no prefix match, so this
        %   new one needs to be added unconditionally, or replace an existing one
        %   with the identical URI and realm. For example, for /foo/bar we tried to
        %   use an existing /foo, but that failed, so we need to add /foo/bar. If
        %   there was previously a /foo and /foo/bar that both failed, we'll replace
        %   the existing /foo/bar if its realm matches.
        %
        %   If credInfo.Scheme is Basic and force is false, it means we found an
        %   existing CredentialInfo whose URI matched the prefix of the request URI,
        %   and tried to authenticate with it, but it failed, so we created a new
        %   CredentialInfo which worked. If that new CredentialInfo has a URI that
        %   exactly matches any existing Basic CredentialInfo, replace the existing
        %   one. This likely means the username or password changed, which was the
        %   reason for the failure. If that new one shares a common prefix with an
        %   existing one, with the same realm and username/password it means we could
        %   have used the existing one, but didn't do so because the prefix match
        %   failed. In this case chop the existing one with the longest common prefix
        %   match at the common prefix and don't add the new one. If there is more
        %   than one such match, use the most recently used. This handles the case
        %   where an existing /foo/bar has the same credentials as /foo/baz: we trim
        %   the existing one to /foo so that a future reference to /foo/fat will
        %   proactively try to use the same credentials. (If it fails because the
        %   username or password is different, we'll store the new one for /foo/fat.)
        %   If there is no commo prefix, add the new one. A common prefix match
        %   includes one with no path at all (i.e., the root).
        
            import matlab.net.http.AuthenticationScheme
            if force || (isempty(credInfo.AuthInfo) || ...
                 credInfo.AuthInfo.Scheme ~= AuthenticationScheme.Basic) || ...
                 isempty(obj.CredentialInfos)
                obj.CredentialInfos(end+1) = credInfo;
            else
                % Basic and not force
                maxCredInfo = []; % handle to best matching CredentialInfo
                maxLength = 0;
                for i = 1 : length(obj.CredentialInfos)
                    % Check if the candidate CredentialInfo matches the one we were
                    % given, with the same username/password and realm. If so,
                    % remember the one with the longest URI match.
                    testInfo = obj.CredentialInfos(i);
                    if testInfo.AuthInfo.Scheme == AuthenticationScheme.Basic && ...
                       credInfo.appliesTo(testInfo) && ...
                       matchInfoRealms(testInfo.AuthInfo, credInfo.AuthInfo)
                        % Since credInfo and testInfo are Basic, we know URIs has
                        % just one entry
                        len = credInfo.URIs.matchLength(testInfo.URIs);
                        if len > maxLength
                            maxLength = len;
                            maxCredInfo = testInfo;
                        else
                        end
                    else
                    end
                end
                if maxLength > 0
                    % found the best match; trim it down
                    maxCredInfo.chopCommonPrefix(credInfo.URIs);
                    credInfo = maxCredInfo;
                else
                    % Didn't find a match, so add it
                    obj.CredentialInfos(end+1) = credInfo;
                end
            end
            
            % update LastUsed date for this added or modified credInfo
            credInfo.LastUsed = datetime('now');

            function tf = matchInfoRealms(a1, a2)
            % match optional realm fields in two AuthInfos. If both fields missing,
            % it's a match.
                r1 = a1.getParameter('realm');
                r2 = a2.getParameter('realm');
                tf = (isempty(r1) && isempty(r2)) || isequal(r1,r2);
            end
        end
        
        function credInfos = getCommonPrefixCredInfos(obj, uri)
        % Return all credInfos having a URI that matches everything up to, but not
        % including, Path
            if ~isempty(obj.CredentialInfos)
                credInfos = obj.CredentialInfos.commonPrefix(uri);
            else
                credInfos = [];
            end
        end
        
        function [credRes, credInfoRes] = getBestCredInfo(obj, uri, authInfo, forProxy)
        % getBestCredInfo Find best matching CredentialInfo for URI
        %   Searches across all CredentialInfos obj array of Credentials, to see if we
        %   authenticated to this host before. It returns the CredentialInfo and its
        %   containing Credentials with the longest match of URI to prefix of uri. In
        %   case of tie, returns the one most recently used. Prefix match requires all
        %   fields through Port to be exactly the same, and then 0 or more Path
        %   segments.
        %
        %   If authInfo is unset, this function is being used to find a CredentialInfo
        %   that we used before, to proactively authenticate without first getting a
        %   challenge. This is appropriate for Basic authentication, and for Digest
        %   authentication after having responded to an earlier challenge. In this case,
        %   we choose the CredentialInfo with the strongest AuthInfo.Scheme first and
        %   then with longest uri match.
        %
        %   But if authInfo is set and the AuthInfo.Scheme is Basic, we only use a
        %   CredentialInfo if uri is equal to or subordinate to the CredentialInfo's
        %   URI. This prevents us from proactively sending a username/password to /a/b
        %   that we previously used for /a/b/c, while allowing us to proactively
        %   authenticate to /a/b/c/d using that username/password. (Later, if we are
        %   asked to add CredentialInfo for /a/b that has the same username/password as
        %   the one for /a/b/c, we'll just trim the one for /a/b/c down to /a/b.      
        %
        %   If authInfo is set, this is being called after having received a challenge,
        %   either because the previous authentication failed or we didn't try to
        %   authenticate in th first place. In this case we only look at CredentialInfos
        %   whose AuthInfo applies to the challenge authInfo.
        %
        %   forProxy   if set, look only in CredentialInfos where ForProxy is set
        %              if unset or missing, look only in CredentialInfos where
        %              ForProxy is not set.
        %
        %   Returns the CredentialInfo and its containing Credentials.
            import matlab.net.http.AuthenticationScheme
            matchLen = 0; % length of longest match for strongest scheme
            credRes = [];
            credInfoRes = [];
            maxScheme = -1;  % numeric value of AuthInfo.Scheme we found
            if nargin < 4
                forProxy = false;
            else
            end
                
            struri = string(uri);
            for i = 1 : length(obj)
                cred = obj(i);
                for j = 1 : length(cred.CredentialInfos)
                    credInfo = cred.CredentialInfos(j);
                    % set this to prevent proactive Basic authentication for a uri with a 
                    % path that is not equal to or subordinate to one in credInfo
                    forProactiveBasic = isempty(authInfo) && ~isempty(credInfo.AuthInfo) && ...
                               credInfo.AuthInfo.Scheme == AuthenticationScheme.Basic;
                    if ~isempty(credInfo.AuthInfo) 
                        % get scheme in AuthInfo as an absolute number
                        scheme = abs(credInfo.AuthInfo.Scheme);
                    else
                        % only proxy credInfos have no AuthInfo
                        assert(credInfo.ForProxy)
                        scheme = 0;
                    end
                    % If authInfo is set, don't look at Scheme in credInfo;
                    % otherwise look only at strongest Scheme first. If
                    % credInfo.AuthInfo is empty, use it only if we don't already
                    % have maxScheme.
                    if credInfo.ForProxy == forProxy && ...            % credInfo applies, proxy or not
                       (isempty(credInfo.AuthInfo) || ...
                          credInfo.AuthInfo.worksFor(authInfo)) && ... % true if authInfo empty
                       (~isempty(authInfo) || ...
                          (isempty(credInfo.AuthInfo) && maxScheme < 0) || ...
                          scheme >= maxScheme)
                        % the credInfo applies to target (or its credInfo.AuthInfo
                        % is empty), or authInfo is empty and this credInfo is the
                        % equal to or stronger than maxScheme
                        for k = 1 : length(credInfo.URIs)
                            testURI = credInfo.URIs(k); % get a URI from the credInfo
                            % get number of matching leading segments
                            % returns intmax if all segments match, which causes an exact match to have more
                            % priority than a partial match. That is, a/b matches both a/b and a/b/c in 2
                            % segments, but we prefer the match to a/b since it's exact
                            if forProactiveBasic 
                                % in the case of proactive Basic, we want to know if uri is subordinate to
                                % testURI
                                [len, isSubordinate] = testURI.matchLength(uri);
                            elseif scheme == AuthenticationScheme.Digest
                                % For Digest, only use the credInfo if one of its URIs completely matches a
                                % prefix of the uri. 
                                if struri.startsWith(string(testURI))
                                    len = 1;
                                else
                                    len = -1;
                                end
                            else
                                len = testURI.matchLength(uri);
                            end
                            % Use this credInfo if:
                            %   scheme same as maxScheme: it has a longer match
                            %      or its match is equal but it's not the same,
                            %      and it was more recently used
                            %   scheme greater than maxScheme: it matches any part
                            if (scheme == maxScheme && ...
                                (len > matchLen) || ...
                                (len == matchLen && ...
                                 (~isempty(credInfoRes) && ...
                                  credInfo.LastUsed > credInfoRes.LastUsed))) || ...
                               (scheme > maxScheme && len > 0)
                                % Don't use this for proactive Basic unless uri is equal to or subordinate to
                                % testURI. Prevents us from proactively sending Basic credentials to /a/b that
                                % we previously used for /a/b/c prior to a challenge.
                                if ~forProactiveBasic || isSubordinate
                                    matchLen = len;
                                    credRes = cred;
                                    credInfoRes = credInfo;
                                    % if the credInfo has an AuthInfo, update the scheme
                                    if ~isempty(credInfo.AuthInfo)
                                        maxScheme = scheme;
                                    else
                                    end
                                else
                                end
                            end
                        end
                    else
                    end
                end
            end
            if ~isempty(credInfoRes) && isempty(credInfoRes.AuthInfo)
                % If the chosen credInfo doesn't have an AuthInfo, set it to the
                % one we matched. This only applies if the credInfo was inserted by
                % addProxyCredInfo.
                credInfoRes.AuthInfo = authInfo;
            end
        end
        
        function delete(obj, credInfo)
        % delete the credInfo from this object
            contains = obj.CredentialInfos == credInfo;
            assert(any(contains))
            obj.CredentialInfos(contains) = [];
        end
    end
    
    methods (Access=protected, Hidden)
        function cpObj = copyElement(obj)
        % Overridden to copy everything except the CredentialInfos handles.
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            cpObj.CredentialInfos = matlab.net.http.internal.CredentialInfo.empty;
        end
    end
    
    methods (Access=private)
        function [rcreds, cred, schemes] = getCredentialsInternal(obj, uri, authInfo)
        % Implementation of getCredentials, but for at most one authInfo. Used to find a
        % Credentials in obj array appropriate for creating an AuthorizationField or
        % ProxyAuthorizationField to authenticate to the uri (a server or proxy). 
        %
        % If there is a challenge (authInfo set), this is being called after receiving a
        % ResponseMessage containing challenges in the form of one or more
        % WWW-Authenticate or Proxy-Authenticate fields (you would never have both types
        % in the same message). In this case we use the authInfo as well as the uri to
        % determine which Credentials to return.
        %
        % If there are is no challenge (authInfo empty), this is being called to
        % possibly proactively authenticate to a server before receiving a challenge. In
        % this case use only the uri to determine which Credentials to return.
        %
        % We only look at Credentials allowing a supported scheme (where
        % Credentials.Scheme is empty or allows at least one AuthenticationScheme >=
        % 0).
        %
        % uri       URI of the host (server or proxy)
        %
        % authInfo  an AuthInfo challenge from the WWW-Authenticate or Proxy-Authenticate
        %           field in the Response Message, or [] if no challenge. If the ResponseMessage
        %           contains multiple challenges, caller will invoke us multiple times,
        %           once for each supported scheme, in order strongest to weakest, until
        %           getting a nonempty cred, in order to respond to the strongest
        %           supported scheme we and the server support.
        %
        % rcreds    all Credentials whose Scope.Host matches uri.Host (and, if authInfo specified,
        %           have a Scheme that allows authInfo.Scheme), sorted by most specific
        %           to least specific match. This sort does not prioritize Scheme.
        %           These are all the Credentials that we are willing to use to
        %           authenticate to the server (for the Scheme in authInfo, if
        %           specified).
        %
        % cred      if authInfo empty, the first Credentials in creds that contains
        %           a credInfo, which means we authenticated before using Basic or
        %           Digest. Otherwise, the best matching Credentials in rcreds based on
        %           Scheme, Host, Path, and Realm (meaning we support authInfo.Scheme
        %           and are willing to authenticate with it). [] if none found. If
        %           this is set and authInfo is empty, we may try to proactively
        %           authenticate to the server using the scheme in the credInfo (Basic
        %           or Digest) without waiting for a challenge.
        %
        % schemes   allowed schemes. If authInfo set, the scheme in that authInfo.
        %           If authInfo is empty, the union of all rcreds.Scheme; empty if any
        %           creds.Scheme is empty implying all supported schemes are allowed.
        %           These are the schemes we're willing to use in addition to the one(s)
        %           in cred. The purpose of this return value is to allow us to
        %           authenticate to the server using any of the schemes we support (that
        %           the user has allowed), typically stronger schemes like NTLM or
        %           Kerberos, even if we found a creds or a cred that supports Basic or
        %           Digest. The caller is obligated to use the strongest of the schemes.
        %
        % Note obj is vector of Credentials
        
        % TBD this function badly needs decomposing.
            cred = [];
            
            function res = getMatching(schemes)
            % Return Schemes in schemes that match those in authInfo
                if isempty(authInfo)
                    res = schemes;
                else
                    res = intersect(authInfo.Scheme, schemes);
                end
            end

            % set authScheme to the scheme in the challenge, or empty if no challenge
            % only save schemes we have enums for, so no strings
            if isempty(authInfo) || ~isa(authInfo.Scheme, 'matlab.net.http.AuthenticationScheme')
                authScheme = matlab.net.http.AuthenticationScheme.empty;
            else
                authScheme = authInfo.Scheme;
            end
            
            % set to true when we found a cred to return, but we need to keep
            % iterating an all credentials to obtain rcreds
            found = false; 

            % If there is a challenge, first find best Credentials whose Scheme
            % contains authScheme (comparator{1}). If none, look at Credentials with empty Scheme
            % (which matches anything) (comparator{2}).
            % If no challenge, just find best Credentials based on uri and Scope,
            % picking the one with strongest Scheme only if there's a tie.
            comparator{1} = @(c) ismember(authScheme, [c.Scheme]); % c.Scheme is in authScheme
            comparator{2} = @(c) isempty(c.Scheme); % c.Scheme is empty
            rcreds = matlab.net.http.Credentials.empty;
            for ci = 1 : length(comparator)
                if ci > 1 && isempty(authScheme)
                    % 1st comparator done; If authScheme is empty, we already
                    % looked at all creds, so no need to run through 2nd comparator
                    break
                else 
                end
                if ~isempty(authScheme)
                    % If authScheme specified, work only on creds that have matching
                    % schemes with authScheme. 
                    creds = obj(arrayfun(comparator{ci}, obj));
                    if isempty(creds)
                        % None of the creds have a matching scheme
                        continue
                    else % else clause included so that profiler gets to end statement
                    end
                else
                    % No authScheme specified, then look at all creds
                    creds = obj;
                end
                
                % The schemes in all creds match authScheme, or authScheme is empty

                % Get array of credentials matching Scope.Host and uri.Host with the
                % same Port. This will also match ones with empty scope.
                host = uri.Host; 
                port = uri.Port;
                % Loren's inline conditional: iif(cond1,act1,cond2,act2,...,true,default)
                % See link below for explanation:
                % https://blogs.mathworks.com/loren/2013/01/24/introduction-to-functional-programming-with-anonymous-functions-part-2/
                iif = @(varargin) varargin{2*find([varargin{1:2:end}], 1)}();

                % Function returning the priority of the match of uri.Host to sHost,
                % anchored to end of string. Priority is:
                %    no match     -1
                %    empty        0
                %    match        number of matching characters
                % The idea is that an empty sHost matches any uri.Host, but gets
                % lower priority than an actual match. In addition, if sPort isn't
                % empty, it has to match port exactly.
                hostMatcher = @(sHost, sPort) iif( ...
                   isempty(sHost),    @()0, ...
                   (isempty(sPort) || isequal(port,sPort)) && ~isempty(sHost) && ...
                       ~isempty(regexp(host, matlab.net.internal.getSafeRegexp(sHost) + '$','once')), ...
                                          @()strlength(sHost), ... 
                   true,             @()-1); 
                % Function that takes a scope (array of URIs) and returns the max
                % priority of the match of any of scope.Host fields, based on
                % hostMatcher. Returns 0 if scope is empty. We need to use {scope.Host}
                % instead of [scope.Host] so that empty values get passed into
                % hostMatcher.
                hostScopeMatcher = @(scope) iif( ...
                    isempty(scope), @()0, ...
                    true,           @()max(cellfun(hostMatcher, {scope.Host}, {scope.Port})));
                % Pass in each Scope array to hostScopeMatcher and get priority of
                % each. Result is a array of numbers. 
                priorities = cellfun(hostScopeMatcher, {creds.Scope});
                
                % Sort creds and matches by priority, high to low
                % This maintains the order of equal-priority Credentials because
                % we'll want to pick the first matching one (other things
                % being equal)
                [priorities,indices] = sort(priorities, 'descend');

                % examine only the creds whose priorities are >= 0
                creds = creds(indices(priorities >= 0));
                priorities(priorities < 0) = [];
                
                % Now creds is vector of Credentials whose URIs have have a Host and
                % Port that matches the uri Host and Port, and
                % priorities(i) is priority of Host match in creds(i). It will be
                % something like:
                %   15 15 15 10 10 2 2 2 2 0 -1 -1 -1
                % which says that:
                %   creds(1:3) prioirty 15: match 15 characters
                %   creds(4:5) priority 10: match 10 characters
                %   creds(6:9) priority 4:  match 4 characters
                %   creds(10)  priority 0:  no host specified in creds (matches any)
                %   creds(11:13) don't match
                % and the rest don't match.
                path = uri.EncodedPath;

                % Now do Path matching.
                % Go through each block of creds that has an equal value of host
                % priority and choose the one with the longest match of uri.Path to
                % creds.Scope.Path, and then longest realm match. In the example
                % above we first go through all the 15's looking for the longest Path
                % and realm match, then the 10's, then 2's and finally the 0. Once
                % we find a block with a matching Path and Realm, we save the best
                % matching one in cred, but keep looking through subsequent blocks and
                % accumulate them in rcreds.
                blockIndex = 1;
                %matchIndex = 0;
                while ~isempty(priorities) && priorities(blockIndex) >= 0
                    % Work on the block of equal priorities(blockIndex) beginning at
                    % blockIndex: these are all creds with same length of matching
                    % host.
                    matchIndex = 0;      % index of best Scope.Path/Realm in creds so far
                    pathPriority = -2;   % priority of Path match at matchIndex
                    realmPriority = -1;  % priority of Realm match at matchIndex
                    hostPriority = priorities(blockIndex); % Host priority we're working on
                    % Advance through block, looking for match with Path and then Realm
                    for j = blockIndex : length(creds)
                        if priorities(j) ~= hostPriority
                            % j has gotten to the next block
                            assert(priorities(j) <= hostPriority); % expect decreasing
                            break % advance to next block
                        else % else clause included so that profiler gets to end statement
                        end
                        curCred = creds(j);
                        % work on this block of creds with same hostPriority;
                        % first see if creds.Scope.Path matches path
                        scope = curCred.Scope;
                        % set pathLen to priority of path match: length of longest
                        % match or 0 for any empty match
                        if isempty(scope)
                            pathLen = 0;
                        else
                            pathMatcher = @(sPath) iif( ...
                               strlength(sPath) == 0, @()0, ...
                               ~isempty(regexp(path, '^' + matlab.net.internal.getSafeRegexp(sPath),'once')), ...
                                               @()strlength(sPath), ... 
                               true,           @()-1); 
                            pathLen = max(cellfun(pathMatcher, {scope.EncodedPath}));
                            if pathLen < 0
                                % none of the Paths in this cred match; go to next
                                % cred in block
                                continue 
                            else 
                            end
                            % pathLen is legnth of path match
                        end
                        % get highest priority match of authInfo.realm with realms in curCred.Realm
                        rlen = matchRealm(curCred.Realm, iif, authInfo);
                        if rlen >= 0
                            % At least one matches, so save it
                            rcreds(end+1) = curCred; %#ok<AGROW>
                            if pathLen >= pathPriority
                                % The creds(j) we're working on matches all the criteria for
                                % potentially using it: host, realm, scheme, so add it to rcreds
                                
                                % This function, given two vectors or AuthenticationScheme returns true if a is
                                % nonempty and has a larger value than any in vector b, looking only at
                                % the elements of a and b that are contained in authInfo.Scheme. The latter is
                                % needed because we don't care if one Credentials specifies Basic while another
                                % specifies [Digest,Basic], if only Basic is allowed by the AuthInfo.
                                aGTEb = @(a,b) ~isempty(a) && ...
                                    (isempty(b) || ...
                                    max(getMatching(a)) > max(getMatching(b)));
                                if pathLen > pathPriority || ...
                                        (pathLen == pathPriority && ...
                                        (rlen > realmPriority || ...
                                        (rlen == realmPriority && ...
                                        aGTEb(curCred.Scheme, creds(matchIndex).Scheme))))
                                    % A path match and it is higher priority than the
                                    % previous one; or the same priority and its realm
                                    % match is higher; or the realm match is equal but
                                    % the scheme is better or equal. Save it and the
                                    % priority of its Realm match.
                                    pathPriority = pathLen;
                                    matchIndex = j;
                                    realmPriority = rlen;
                                else
                                end
                                % if path match is the same but realm match is shorter,
                                % or realm is equal and scheme is not better, ignore and
                                % keep going to next cred
                            else
                                % if path match is shorter than longest so far, ignore
                                % cred
                            end
                        else
                            % no match of realm, ignore cred
                        end
                        % go to next cred in block
                    end % for j = blockIndex : length(creds)
                    % we got to the end of creds in this block
                    if matchIndex > 0
                        % we got a match
                        if ~found
                            % not found yet, so save the match
                            cred = creds(matchIndex);
                            found = true;
                        else
                            % matched, but already found, so keep going to
                            % build up rcreds
                        end
                    end
                    if j == length(creds)
                        % reached end of all creds, so done done
                        break;
                    else
                        % still more to go, so go to next block
                        blockIndex = j;
                    end
                end
            end % advance to next comparator for authScheme
            
            % Determine what schemes to return to caller
            if ~isempty(authScheme) && ~isempty(cred)
                % There is an AuthInfo with a recognizable scheme and we have
                % a cred to match so only allow it
                assert(isempty(cred.Scheme) || any(find(cred.Scheme == authScheme)));
                schemes = authScheme;
            else
                % There is no AuthInfo or no matching cred, so choice of schemes is based on
                % all possible returned creds
                if isempty(rcreds) || any(arrayfun(@(x) isempty(x.Scheme), rcreds)) 
                    % If no creds or any cred's scheme is empty, allow all schemes
                    schemes = [];
                else
                    % Get union of all schemes in matching creds,
                    % Since they may be row or column, so unionize themm
                    u = rcreds(1).Scheme;
                    for i = 2 : length(rcreds)
                        u = union(u, rcreds(i).Scheme);
                    end
                    schemes = unique(u);
                end
            end
        end % function getCredentialsInternal
    end % methods(Access=private)
    
    methods (Access = protected)
                
        function group = getPropertyGroups(obj)
        % Provide a custom display for the case in which obj is scalar
        % Display Scheme and Scope as strings. 
        % If Password is non-empty, replace each character with '*'.
            
            group = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            if isscalar(obj)
                scheme = group.PropertyList.Scheme;
                if ~isscalar(scheme) && ~isempty(scheme)
                    scheme = strjoin(arrayfun(@char,scheme,'UniformOutput',false),...
                                     ', ');
                    group.PropertyList.Scheme = scheme;
                else
                end
                scope = strjoin(arrayfun(@char, group.PropertyList.Scope, ...
                                         'UniformOutput',false),...
                                 ', ');
                group.PropertyList.Scope = scope;
                password = group.PropertyList.Password;
                username = group.PropertyList.Username;
                if ~isempty(password) && ~(class(password) == "secretID")
                    pw(1:strlength(password)) = '*';
                    group.PropertyList.Password = string(pw);
                end
                if ~isempty(username) && ~(class(username) == "secretID")
                    un(1:strlength(username)) = '*';
                    group.PropertyList.Username = string(un);
                end
                % make empty fields look like []
                names = fieldnames(group.PropertyList);
                for i = 1 : length(names)
                    name = names{i};
                    if isempty(group.PropertyList.(name))
                        group.PropertyList.(name) = [];
                    else
                    end
                end
            end
        end
    end
    
    methods (Access=?tHTTPCredentialsUnit)
        function credInfos = getCredInfos(obj)
        % Test API only.
            credInfos = obj.CredentialInfos;
        end
    end
end

function rlen = matchRealm(realms, iif, authInfo)
% Match array of realms (taken from a Credentials.Realm) to the realm parameter
% in the authInfo, returning priority (number of characters) of longest match or
% -1. An empty realms, or an authInfo with no "realm" parameter, matches
% anything, but returns the lowest priority of 0.
    rlen = 0;
    if ~isempty(authInfo)
        realm = authInfo.getParameter('realm');
        if ~isempty(realms) && ~isempty(realm)
            % This matches the realm in the authInfo with the one of the realms (r) in the
            % Credentials. Note that r is processed as a regular expression, so any
            % anchoring to the beginning or end of string has to be specified by the user
            % in the Credentials.
            match = @(r) regexp(realm, r, 'once');
            % realmMatcher returns first and last characters of each match, or [0,-1]
            % if no match
            realmMatcher = @(sRealm) iif( ...
                isempty(match(sRealm)),  @()deal(0,-1), ...
                strlength(sRealm) == 0 && strlength(realm) == 0, @()deal(0,0), ...
                true,                    @()match(sRealm));
            [first, last] = arrayfun(realmMatcher, realms);
            rlen = max(last - first); % length of the match
            if rlen < 0
                % no Realm matches
                rlen = -1;
            else
                % we got a match of 1 or more characters
            end
        else
            % no realm or realms to match
        end
    else
        % no authInfo
    end
end

function result = mustBeStringOrSecretIDScalar(value, propname)
if ~(ischar(value) || isstring(value) || class(value) == "secretID")
    id = "MATLAB:Credentials:invalidType";
    msg = getString(message("MATLAB:validateattributes:invalidType", propname, "string char secretID", class(value)));
    error(id, msg);
end
if class(value) == "secretID"
    validateattributes(value, "secretID", "scalar", mfilename, propname);
    result = value;
else
    result = matlab.net.internal.getString(string(value), mfilename, propname);
end

end
