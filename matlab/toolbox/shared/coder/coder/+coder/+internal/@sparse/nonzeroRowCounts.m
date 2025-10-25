function counts = nonzeroRowCounts(x)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.

% Return counts which is a size(x,1)-by-1 array containing the number of
% nonzeros in each row.
%#codegen
counts = zeros(x.m,1,'like',ONE);
nzx = nnzInt(x);
for k = 1:nzx
    row = x.rowidx(k);
    counts(row) = counts(row) + 1;
end
