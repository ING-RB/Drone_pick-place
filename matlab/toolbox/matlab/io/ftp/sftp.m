function obj = sftp(host, varargin)
%

%   Copyright 2020-2024 The MathWorks, Inc.

try
    obj = matlab.io.sftp.SFTP(host, varargin{:});
catch ME
    throw(ME);
end
end
