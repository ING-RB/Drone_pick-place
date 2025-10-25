function that = ceil(this,unit) %#codegen
%CEIL Round durations towards infinity.

%   Copyright 2020 The MathWorks, Inc.

if nargin < 2
    scale = 1000; % default: round up to next second
else
    scale = checkUnit(unit);
end
that = this;
that.millis = scale * (ceil(this.millis / scale));
