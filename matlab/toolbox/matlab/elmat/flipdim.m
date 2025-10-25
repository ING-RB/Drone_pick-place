function y = flipdim(x,dim)
%FLIPDIM Flip matrix along specified dimension.
%   FLIPDIM is not recommended. Use FLIP instead.
%
%   FLIPDIM(X,DIM) returns X with dimension DIM flipped.  
%   For example, FLIPDIM(X,1) where
%   
%       X = 1 4  produces  3 6
%           2 5            2 5
%           3 6            1 4
%
%
%   Class support for input X:
%      float: double, single
%
%   See also FLIP, FLIPLR, FLIPUD, ROT90, PERMUTE.

%   Copyright 1984-2023 The MathWorks, Inc.

y = flip(x, dim);
