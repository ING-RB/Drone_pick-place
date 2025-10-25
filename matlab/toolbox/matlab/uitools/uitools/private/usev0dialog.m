function result = usev0dialog(varargin)
%

%   Copyright 2007-2020 The MathWorks, Inc.
if (isempty(varargin))
    result = false;
else
    if (strcmpi(varargin{1}, 'v0'))
        result = true;
    else
        result = false;
    end
end
end
