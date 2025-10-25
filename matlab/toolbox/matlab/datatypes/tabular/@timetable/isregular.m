function [tf, dt] = isregular(tt, unit)
%

%   Copyright 2016-2024 The MathWorks, Inc.

if nargin < 2
    [tf, dt] = tt.rowDim.isregular();
else
    [tf, dt] = tt.rowDim.isregular(unit);
end
