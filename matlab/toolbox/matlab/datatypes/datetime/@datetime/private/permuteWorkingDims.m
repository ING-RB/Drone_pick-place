function [A,szOut,perm] = permuteWorkingDims(A,dim)
% PERMUTEWORKINGDIMS
%   [A,SZOUT] = PERMUTEWORKINGDIMS(A,DIM) permutes input A such that the
%   working dimensions, as specified in DIM, are in front and then reshapes
%   A to a matrix. SZOUT is the size of of input A with the working
%   dimensions set to 1.
%
%   [A,SZOUT,PERM] = PERMUTEWORKINGDIMS(A,DIM) also returns the permuation.

%   Copyright 2018-2020 The MathWorks, Inc.

% Make sure dim is a row vector
dim = reshape(dim, 1, []);

% Remove dims > ndims
dim(dim > ndims(A)) = [];

% Set output size to 1 along the working dimensions
szIn = size(A);
szOut = szIn;
szOut(dim) = 1;

% Permute working dims to the front if there are some dims <= ndims
if isempty(dim)
    perm = 1:ndims(A); % Need this for median
else
    tf = false(1, ndims(A));
    tf(dim) = true;
    perm = [find(tf), find(~tf)];
    A = permute(A, perm);
end

A = reshape(A, [prod(szIn(dim)), prod(szOut)]);
