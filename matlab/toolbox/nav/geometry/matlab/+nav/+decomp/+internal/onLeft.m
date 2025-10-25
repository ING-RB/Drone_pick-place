function left = onLeft(q)
%onLeft - Return TRUE if the given quadrant is to the left of the y-axis
%
%   LEFT = onLeft(Q) is TRUE when Q is in quadrants I, IV, or WEST

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    left = (q == nav.decomp.internal.Quadrant.Two || ...
        q == nav.decomp.internal.Quadrant.Three || ...
        q == nav.decomp.internal.Quadrant.West);
end
