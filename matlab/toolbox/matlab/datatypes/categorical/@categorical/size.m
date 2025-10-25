function varargout = size(a,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

% Call the built-in to ensure correct dispatching regardless of what's in dim
    varargout = cell(1,max(nargout,1));
if nargin == 1
    [varargout{:}] = builtin('size',a.codes);
else
    [varargout{:}] = builtin('size',a.codes,varargin{:});
end
