function [response, status] = handleHTTP(fcn, uri, inputs, readFcn, catcherrors)

% Copyright 2020 The MathWorks, Inc.

opts = weboptions;
% Set the timeout.
if ~isempty(inputs.timeout)
    opts.Timeout = inputs.timeout;
else
    opts.Timeout = 5; % set default timeout to 5 secs
end

if ~isempty(inputs.charset)
    opts.CharacterEncoding =  char(inputs.charset);
end

% Set the username.
if ~isempty(inputs.username)
    opts.Username = inputs.username;
end

% Set the password.
if ~isempty(inputs.password)
    opts.Password = inputs.password;
end

% Setting accept-encoding to empty explicitly as this coupled with
% Decode set to false is required to suppress decompression in case of
% urlwrite. See https://curl.haxx.se/libcurl/c/CURLOPT_ACCEPT_ENCODING.html
opts.HeaderFields = {'Accept-Encoding', ''; 'Accept', ''};

% If username and password exists, perform basic authentication
if(strcmpi(inputs.authentication, 'Basic'))
    usernamePassword = [char(inputs.username), ':', char(inputs.password)];
    headerName  = 'Authorization';
    headerValue = ['Basic ', matlab.net.base64encode(usernamePassword)];
    hf = opts.HeaderFields;
    hf{end+1, 1} = headerName;
    hf{end, 2}   = headerValue;
    opts.HeaderFields = hf;
end

if ~isempty(inputs.useragent)
    opts.UserAgent = inputs.useragent;
end

response = processHTTPRequest(uri, inputs, opts, readFcn);
status = 1;
end

