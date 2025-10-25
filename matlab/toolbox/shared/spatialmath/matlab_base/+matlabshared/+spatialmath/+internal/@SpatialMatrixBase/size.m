function varargout = size(obj,varargin)
%SIZE Size of array
%   D = SIZE(X), for M-by-N matrix X, returns the two-element row vector
%   D = [M,N] containing the number of rows and columns in the matrix X.
%   For N-D arrays, SIZE(X) returns a 1-by-N vector of dimension lengths.
%   Trailing singleton dimensions are ignored.
%
%   [M,N] = SIZE(X) for matrix X, returns the number of rows and columns in
%   X as separate output variables.
%
%   [M1,M2,M3,...,MN] = SIZE(X) for N>1 returns the sizes of the first N
%   dimensions of the array X.  If the number of output arguments N does
%   not equal NDIMS(X), then for:
%
%   N > NDIMS(X), SIZE returns ones in the "extra" variables, i.e., outputs
%                 NDIMS(X)+1 through N.
%   N < NDIMS(X), MN contains the product of the sizes of dimensions N
%                 through NDIMS(X).
%
%   M = SIZE(X,DIM) returns the lengths of the specified dimensions in a
%   row vector. DIM can be a scalar or vector of dimensions. For example,
%   SIZE(X,1) returns the number of rows of X and SIZE(X,[1 2]) returns a
%   row vector containing the number of rows and columns.
%
%   M = SIZE(X,DIM1,DIM2,...,DIMN) returns the lengths of the dimensions
%   DIM1,...,DIMN as a row vector.
%
%   [M1,M2,...,MN] = SIZE(X,DIM) OR [M1,M2,...,MN] = SIZE(X,DIM1,...,DIMN)
%   returns the lengths of the specified dimensions as separate outputs.
%   The number of outputs must equal the number of dimensions provided.
%
%   See also LENGTH, NDIMS, NUMEL.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    [varargout{1:nargout}] = size(obj.MInd,varargin{:});

end
