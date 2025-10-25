classdef AuthenticationScheme < int8
% AuthenticationScheme Enumeration of recognized authentication schemes
%   This scheme is specified in a Credentials object, and appears in an AuthInfo
%   returned by a server or proxy in an AuthenticateField header field and sent by
%   the client in an AuthorizationField.
%
%   When you send a message to a server, and the server requires authentication to
%   satisfy the request, the server returns a ResponseMessage (StatusCode 401 or 407)
%   containing an AuthenticateField that specifies what AuthenticationSchemes are
%   required to satisfy the request. You should then choose the strongest of the
%   schemes that you can support, and reissue the request with an AuthorizationField
%   containing appropriate authorization information. For schemes whose numeric value
%   is non-negative (Basic, Digest, NTLM and Negotiate, depending on the platform),
%   MATLAB will do all this for you if you provide appropriate Credentials in
%   HTTPOptions. For other schemes you must implement the response yourself.
%
%   These schemes equate to integers, whose absolute values can be used to order
%   the strength of the scheme from lowest to highest. In other words, abs(s1) >
%   abs(s2) means that s1 is equal to or stronger than s2. A negative value means
%   that the scheme is not automatically implemented by this release of MATLAB.
%   You should not depend on the exact numeric values of these schemes, as they
%   may change in a future release.
%
%   AuthenticationScheme properties:
%       Basic      - Basic scheme (requires username/password)
%       Digest     - Digest scheme (requires username/password)
%       Bearer     - Bearer scheme
%       HOBA       - HOBA scheme
%       Mutual     - Mutual scheme
%       Negotiate  - Negotiate scheme
%       NTLM       - NTLM scheme (requires username/password on Mac and Linux)
%       Token      - Token scheme
%       OAuth      - OAuth scheme
%
%   Each property corresponds to a scheme listed in the IANA <a href="http://www.iana.org/assignments/http-authschemes/http-authschemes.xhtml#authschemes">Authentication Scheme Registry</a>. 
%   Other schemes may be added as well.
%
% See also Credentials, HTTPOptions, matlab.net.http.field.AuthenticateField,
% matlab.net.http.field.AuthorizationField, ResponseMessage, AuthInfo

% Copyright 2015-2018 The MathwWorks, Inc.

    % This list is from the 2017-04-13 version of the IANA HTTP Authentication Scheme
    % Registry plus others we are aware of.
    % http://www.iana.org/assignments/http-authschemes/http-authschemes.xhtml
    enumeration
        % Basic - authentication scheme (<a href="http://tools.ietf.org/html/rfc2617">RFC 2617</a>)
        %   In this scheme the user name and password are transmitted in the header
        %   of an HTTP message. MATLAB implements this scheme automatically when you
        %   supply appropriate Credentials in HTTPOptions when sending a message.
        %   This scheme exposes the password to the network (unless the connection is
        %   using https encryption) and to the server. 
        %
        % See also Credentials, HTTPOptions, RequestMessage
        Basic (0)
        % Digest - authentication scheme (<a href="http://tools.ietf.org/html/rfc2617">RFC 2617</a>)
        %   In this scheme the user is authenticated with a name and password, but it
        %   is more secure than Basic because the password is not sent to the server
        %   and is not transmitted over the connection. It can also prevent replay
        %   attacks. MATLAB implements this scheme automatically when you supply
        %   appropriate Credentials in HTTPOptions when sending a message.
        %
        % See also Basic, Credentials, HTTPOptions, RequestMessage
        Digest (1)
        % Bearer - authentication scheme (<a href="http://tools.ietf.org/html/rfc6750">RFC 6750</a>)
        %   This authentication scheme is based on OAuth. MATLAB does not implement
        %   this scheme, so to use this scheme you need to implement your own
        %   challenge responses.
        Bearer (-2)
        % HOBA - authentication scheme (<a href="http://tools.ietf.org/html/rfc7486">RFC 7486</a>)
        %   This is the HTTP Origin-bound scheme. MATLAB does not implement this
        %   scheme, so to use this scheme you need to implement your own
        %   challenge responses.
        HOBA (-3)
        % Mutual - authentication scheme (<a href="https://tools.ietf.org/html/rfc8120">RFC 8120</a>)
        %   This is the Mutual Authentication Scheme. MATLAB does not implement this
        %   scheme, so to use this scheme you need to implement your own
        %   challenge responses.
        Mutual (-4)
        % NTLM - authentication scheme
        %   MATLAB implements this scheme automatically when you supply Credentials in
        %   HTTPOptions that name this scheme or which have an empty Scheme (which is
        %   the default). For this scheme to work on Windows you must be properly logged
        %   into an NTLM environment, and the Username and Password properties of the
        %   Credentials object are ignored.  On other platforms you must explicitly
        %   specify the Username and Password in the Credentials object.
        %
        % See also Credentials, HTTPOptions
        NTLM (5)
        % Negotiate - authentication scheme (<a href="http://tools.ietf.org/html/rfc4559">RFC 4559</a>)
        %   This scheme supports SPNEGO-based Kerberos and NTLM on Windows only. MATLAB
        %   implements this scheme automatically when you supply Credentials in
        %   HTTPOptions that name this scheme or which have an empty Scheme (which is
        %   the default). For this scheme to work you must be properly logged into a
        %   Kerberos or NTLM environment. This scheme ignores the Username and Password
        %   properties of the Credentials object.
        %
        % See also Credentials, HTTPOptions
        Negotiate (12*ispc-6)   % +6 for PC, -6 for other platforms
        % Token - authentication scheme 
        %   This scheme is used support authentication schemes that require you to
        %   supply a previously-obtained token to the server. MATLAB does not
        %   implement this scheme, so to use this scheme you need to implement
        %   your own challenge responses.
        Token (-7)
        % OAuth - authentication scheme (<a href="http://tools.ietf.org/html/rfc6749">RFC 6749</a>)
        %   This scheme is more secure than Basic and Digest. MATLAB does not
        %   implement this scheme, so to use this scheme you need to implement
        %   your own challenge responses.
        OAuth (-8)
    end
    
    methods (Static, Access={?matlab.net.http.Credentials,?matlab.net.http.RequestMessage})
        function schemes = getSupportedSchemes() 
        % Return supported schemes in order, strongest to weakest
            schemes = sort(enumeration('matlab.net.http.AuthenticationScheme'),'descend');
            schemes = schemes(schemes >= 0); 
        end
    end
end


