function [f,status] = urlwrite(url,filename,varargin)
if nargin > 0
    url = convertStringsToChars(url);
end

if nargin > 1
    filename = convertStringsToChars(filename);
end

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if nargout == 2
    catchErrors = true;
else
    catchErrors = false;
end

[f,status] = urlreadwrite(mfilename,catchErrors,url,filename,varargin{:});

end

%   Copyright 1984-2022 The MathWorks, Inc.