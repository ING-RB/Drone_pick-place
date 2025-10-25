function todists = convertDistances(viewport, tounits, fromunits, distances)
% This is an undocumented function and may be removed in a future release.

% Use the matlab.graphics.general.UnitPosition object "viewport" to convert
% the units of "distances" from "fromunits" to "tounits".
%
% "distances" are [left bottom right top]. Unlike positions, pixel based
% distances are not 1-based. In order to do the conversion correctly,
% perform two conversions: once for left/bottom, and once for right/top.

%   Copyright 2018-2021 The MathWorks, Inc.

% Set the 'Units' and 'Position' to the starting units and position.
viewport.Units = fromunits;
viewport.Position = [0, 0, abs(distances(1:2))];

% Set the 'Units' to the new units, this will trigger a unit conversion.
viewport.Units = tounits;

% Read back the new position in the new units.
leftbottom = viewport.Position(3:4);

% Set the 'Units' and 'Position' to the starting units and position.
viewport.Units = fromunits;
viewport.Position = [0, 0, abs(distances(3:4))];

% Set the 'Units' to the new units, this will trigger a unit conversion.
viewport.Units = tounits;

% Read back the new position in the new units.
righttop = viewport.Position(3:4);

% Merge the outputs
todists = [leftbottom, righttop];

% Adjust sign to match input.
todists = todists .* sign(distances);
end
