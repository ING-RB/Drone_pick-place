function varargout = feval(fh, varargin)
%FEVAL MATLAB coded equivalent for builtin FEVAL for test purposes.
%
% This function is for internal use only, and may be removed in a future
% release.

%  Copyright 2023 The MathWorks, Inc.

[varargout{1:nargout}] = feval(fh, varargin{:});

end
