%createArray  Create an array of a specified size and class
%   createArray with no arguments creates the scalar 0.
%
%   createArray(N) creates an N-by-N matrix of zeros.
%
%   createArray(M,N) or createArray([M,N]) creates an M-by-N matrix of zeros.
%
%   createArray(M,N,P,...) or createArray([M N P ...]) creates an M-by-N-by-P-by-... array
%   of zeros.
%
%   createArray(SIZE(A)) creates an array of zeros with the same size as A.
%
%   createArray(..., CLASSNAME) creates an array of default values of the class specified
%   by the string CLASSNAME.
%
%   createArray(..., Like = T) creates an array of default values with the same class,
%   sparsity, and complexity (real or complex) as the template value T.
%
%   createArray(..., FillValue = F) creates an array with elements set to the fill value F.
%
%   createArray(..., CLASSNAME, FillValue = F) creates an array with elements set to the
%   fill value F converted to the class specified by the string CLASSNAME.
% 
%   createArray(..., Like = T, FillValue = F) creates an array with elements set to the
%   fill value F converted to the template value T.
%
%   Note: The size inputs M, N, and P... should be nonnegative integers. 
%   Negative integers are treated as 0.
%
%   Examples:
%      x = createArray(1, 3, 'int8');
%      x = createArray([2 3], Like = B);
%      x = createArray(size(A), FillValue = B);
%      x = createArray(100, 1, 'categorical', FillValue = missing);
%      x = createArray(1, 100, Like = single(1+1i), FillValue = NaN);
%
%   See also ZEROS, ONES, NAN, REPMAT.

% Copyright 2023 The MathWorks, Inc.

% Built-in function.
