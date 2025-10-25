function PG = convhull(pshape)
%MATLAB Code Generation Library Function

% Copyright 2023 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkScalar(pshape); % convert to Array check when support is added

if pshape.isEmptyShape()
    PG = polyshape();
    return;
end
[x, y] = pshape.boundary();
F = isfinite(x);
xf = x(F);
yf = y(F);
K = convhull(xf, yf);
H = [xf(K), yf(K)];
PG = polyshape(H);
