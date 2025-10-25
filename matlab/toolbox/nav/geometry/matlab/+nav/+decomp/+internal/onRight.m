function right = onRight(q)
%onRight - Return TRUE if the given quadrant is to the right of the y-axis
%
%   RIGHT = onLeft(Q) is TRUE when Q is in quadrants II, III, or EAST

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    right = (q == nav.decomp.internal.Quadrant.One || ...
        q == nav.decomp.internal.Quadrant.Four || ...
        q == nav.decomp.internal.Quadrant.East);
end
