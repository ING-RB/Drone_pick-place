function boundaries = bndScale(boundaries, sx, sy, ox, oy, this_bd)
% Scale boundary specified by this_bd

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

[bdStPtr, bdEnPtr] = boundaries.getBoundary(this_bd);
boundaries.vertices = boundaries.vertices.ptScale(sx, sy, ox, oy, bdStPtr, bdEnPtr);
boundaries.clean(this_bd) = false;

boundaries = boundaries.updateArea(this_bd);

tf = coder.internal.scalarizedAll(@(x)x, boundaries.clean);
coder.internal.assert(tf, 'MATLAB:polyshape:scaleOverflow');
