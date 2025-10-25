function h = ftp(host, varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.
try
    h = matlab.io.ftp.FTP(host, varargin{:});
catch ME
    throw(ME);
end
