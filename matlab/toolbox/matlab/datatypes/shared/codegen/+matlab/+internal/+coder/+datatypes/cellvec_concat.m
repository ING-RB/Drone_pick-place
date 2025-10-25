function z = cellvec_concat(x,y,nx,ny) %#codegen
% Cell vector concatenation
%   Z = CELLVEC_CONCAT(X,Y) concatenate the two cell vectors X and Y. X and
%   Y must have the same orientation (they must both be rows or they must
%   both be columns).
%   Z = CELLVEC_CONCAT(X,Y,NX,NY) uses only the first NX and NY elements in
%   X and Y.

%   Copyright 2020-2023 The MathWorks, Inc.

if nargin < 4
    ny = numel(y);
    if nargin < 3
        nx = numel(x);
    end
end

if coder.internal.isConstTrue(isrow(x)) && coder.internal.isConstTrue(isrow(y))
    z = coder.nullcopy(cell(1,nx+ny));
else
    coder.internal.assert(coder.internal.isConstTrue(iscolumn(x)) && coder.internal.isConstTrue(iscolumn(y)), ...
        'MATLAB:datatypes:MustBothBeVectors');
    z = coder.nullcopy(cell(nx+ny,1));
end

for i = 1:nx
    z{i} = x{i};
end
for i = 1:ny
    z{nx+i} = y{i};
end
