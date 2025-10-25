function out = overlaps(P, Q)
%MATLAB Code Generation Library Function

%   Limitations:
%   1) Only scalar polyshape inputs allowed to overlaps

% Copyright 2023 The MathWorks, Inc.
%#codegen

coder.internal.polyshape.checkScalar(P);

if nargin == 1
    % only 1x0 and 0x1 empties pass
    coder.internal.assert(isvector(P), 'MATLAB:polyshape:vectorPolyshapeError');
    Q = P;
else
    coder.internal.polyshape.checkScalar(Q);
end

% Added as a safeguard, codegen doesnt allow creation of polyshape.empty.
if coder.internal.isConstTrue( isempty(P) || isempty(Q) )
    out = zeros(0,0,'logical');
    return;
end
out = isOverlapping(P, Q);

end

%actually checking if two shapes overlap
function tf = isOverlapping(P, Q)

coder.inline('always');
if P.isEmptyShape || Q.isEmptyShape
    tf = false;
    return;
end

[xP, yP] = boundingbox(P);
[xQ, yQ] = boundingbox(Q);

tf = true;
if xP(2) < xQ(1) || xP(1) > xQ(2) || yP(2) < yQ(1) || yP(1) > yQ(2)
    tf = false;
else
    inte = intersect(P, Q);
    if numboundaries(inte) == 0
        tf = false;
    end
end
end
