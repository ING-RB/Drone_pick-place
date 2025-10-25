function b = reshape(a,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc. 

b = a;
% Call the built-in to ensure correct dispatching regardless of what's in varargin
b.codes = builtin('reshape',a.codes,varargin{:});
