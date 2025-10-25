function Pos = getPosition(h,Units)
% Gets position of HG object in specified units

%   Copyright 2017-2020 The MathWorks, Inc.

h = handle(h);
CurrentUnits = h.Units;
h.Units = Units;
Pos = h.Position;
h.Units = CurrentUnits;
