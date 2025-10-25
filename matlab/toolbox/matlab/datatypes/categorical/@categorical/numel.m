function e = numel(a,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc. 

% Call the built-in to ensure correct dispatching regardless of what's in varargin
e = builtin('numel',a.codes,varargin{:});
