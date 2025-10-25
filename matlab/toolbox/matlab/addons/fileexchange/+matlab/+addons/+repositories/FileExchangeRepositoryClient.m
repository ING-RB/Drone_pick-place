classdef (Hidden = true) FileExchangeRepositoryClient
% Sends HTTP requests to a web-based repository. Wraps known types of error responses as a
% convenience for users of FileExchangeRepositoryClient objects.

% Copyright 2018 The MathWorks, Inc.

    properties
        ConnectionErrorIdentifiers = { ...
            'MATLAB:webservices:CopyContentToDatastreamError', ...
            'MATLAB:webservices:ConnectionFailed', ...
            'MATLAB:webservices:ConnectionRefused', ...
            'MATLAB:webservices:Timeout', ...
            'MATLAB:webservices:SSLConnectionFailure' ...
        };

        NotFoundErrorIdentifier = { ...
            'MATLAB:webservices:HTTP404StatusCodeError', ...
        };

        ServerErrorIdentifiers = { ...
            'MATLAB:json:ExpectedValueAtEnd', ...
            'MATLAB:webservices:ContentTypeReaderError', ...
            'MATLAB:webservices:HTTP500StatusCodeError', ...
            'MATLAB:webservices:HTTP503StatusCodeError', ...
            'MATLAB:webservices:InvalidJSON' ...
        };
    end

    methods
        % Sends requests to an HTTP-based repository.
        %
        % The httpImplementation argument allows injection of an alternative function to
        % make the HTTP call (for example, a test stub).
        function responseBody = get(obj, url, httpImplementation)
            if ~exist("httpImplementation", "var")
                httpImplementation = @(u) webread(u);
            end

            try
                responseBody = httpImplementation(url);
            catch exception
                switch exception.identifier
                    case obj.ConnectionErrorIdentifiers
                        error("MATLAB:addons:repositories:ConnectionError", exception.message);
                    case obj.NotFoundErrorIdentifier
                        error("MATLAB:addons:repositories:NotFound", exception.message);
                    case obj.ServerErrorIdentifiers
                        error("MATLAB:addons:repositories:ServerError", exception.message);
                    otherwise
                        rethrow(exception);
                end
            end
        end
    end
end
