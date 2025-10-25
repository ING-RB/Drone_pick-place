function e = numel(a,varargin) %#codegen
%NUMEL Number of elements in a categorical array.
%   N = NUMEL(A) returns the number of elements in the categorical array A.
%
%   See also SIZE.

%   Copyright 2019 The MathWorks, Inc. 

% Call the built-in to ensure correct dispatching regardless of what's in varargin
e = builtin('numel',a.codes,varargin{:});
