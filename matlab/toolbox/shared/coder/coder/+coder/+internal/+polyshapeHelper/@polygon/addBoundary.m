function pg = addBoundary(pg, X, Y, btype, fillingRule)
%MATLAB Code Generation Library Function
% Add boundary to polygon

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

n1 = numel(X);
n2 = numel(Y);

coder.internal.assert(n1==n2,'MATLAB:polyshape:twoInputSizeError');

pg = pg.addPoints(X, Y, n1, btype);
pg = pg.setFillingRule(uint8(fillingRule));
