function topos = convertUnits(viewport, tounits, fromunits, frompos)
% This is an undocumented function and may be removed in a future release.

% Use the matlab.graphics.general.UnitPosition object "viewport" to convert
% the units of "frompos" from "fromunits" to "tounits".

%   Copyright 2018 The MathWorks, Inc.

% Set the 'Units' and 'Position' to the starting units and position.
viewport.Units = fromunits;
viewport.Position = frompos;

% Set the 'Units' to the new units, this will trigger a unit conversion.
viewport.Units = tounits;

% Read back the new position in the new units.
topos = viewport.Position;

end

