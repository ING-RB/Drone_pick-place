function varargout = hFilterslices(varargin)
% Internal only - no help

% hFilterslices Helper to call the private filterslices primitive on the input data
%
% Internal and not supported. Will be removed in a future release.
%
% Copyright 2018 The MathWorks, Inc.

[varargout{1:nargout}] = filterslices(varargin{:});
end
