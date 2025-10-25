function y = flipdim(x,dim)
%FLIPDIM Flip tall matrix along specified dimension.
%   FLIPDIM is not recommended. Use FLIP instead.
% 
%   FLIPDIM(X,DIM)
%
%   Limitations:
%   DIM must be greater than one.
%
%   See also FLIP, TALL.

%   Copyright 2017-2023 The MathWorks, Inc.

y = flip(x, dim);
