function that = floor(this,unit)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 2
    scale = 1000; % default: round down to previous second
else
    scale = checkUnit(unit);
end
that = this;
that.millis = scale * (floor(this.millis / scale));
