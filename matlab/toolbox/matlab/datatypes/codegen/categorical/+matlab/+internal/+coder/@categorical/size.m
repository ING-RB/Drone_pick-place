%#codegen
function varargout = size(a,varargin)
%SIZE Size of a categorical array.
%   D = SIZE(A), for an M-by-N categorical matrix A, returns the two-element
%   row vector D = [M,N] containing the number of rows and columns in the
%   matrix.  For N-D categorical arrays, SIZE(A) returns a 1-by-N vector of
%   dimension lengths.  Trailing singleton dimensions are ignored.
%
%   [M,N] = SIZE(A), for a categorical matrix A, returns the number of rows
%   and columns in A as separate output variables. 
%   
%   [M1,M2,M3,...,MN] = SIZE(A), for N>1, returns the sizes of the first N 
%   dimensions of the categorical array A.  If the number of output arguments
%   N does not equal NDIMS(A), then for:
%
%   N > NDIMS(A), SIZE returns ones in the "extra" variables, i.e., outputs
%                 NDIMS(A)+1 through N.
%   N < NDIMS(A), MN contains the product of the sizes of dimensions N
%                 through NDIMS(A).
%  
%   M = SIZE(A,DIM) returns the lengths of the specified dimensions in a
%   row vector. DIM can be a scalar or vector of dimensions.  For example,
%   SIZE(A,1) returns the number of rows of A and SIZE(A,[1,2]) returns a
%   row vector containing the number of rows and columns.
%
%   M = SIZE(A,DIM1,DIM2,...,DIMN) returns the lengths of the dimensions
%   DIM1,...,DIMN as a row vector.
%
%   [M1,M2,...,MN] = SIZE(A,DIM) OR [M1,M2,...,MN] = SIZE(A,DIM1,...,DIMN)
%   returns the lengths of the specified dimensions as separate outputs.
%   The number of outputs must equal the number of dimensions provided.
%
%
%   See also LENGTH, NDIMS, NUMEL.

%   Copyright 2018-2020 The MathWorks, Inc. 

coder.internal.prefer_const(varargin);
% Call the built-in to ensure correct dispatching regardless of what's in dim
if nargin == 1
    [varargout{1:nargout}] = builtin('size',a.codes);
else
    [varargout{1:nargout}] = builtin('size',a.codes,varargin{:});
end
