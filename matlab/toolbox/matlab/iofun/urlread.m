function [s,status] = urlread(url,varargin)
if nargin > 0
    url = convertStringsToChars(url);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if nargout == 2
    catchErrors = true;
else
    catchErrors = false;
end

[s,status] = urlreadwrite(mfilename,catchErrors,url,varargin{:});

end

%   Copyright 1984-2022 The MathWorks, Inc.