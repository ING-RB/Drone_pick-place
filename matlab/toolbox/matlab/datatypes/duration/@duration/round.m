function that = round(this,unit)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 2
    scale = 1000; % default: round to nearest second
else
    scale = checkUnit(unit);
end
that = this;
that.millis = scale * (round(this.millis / scale));
