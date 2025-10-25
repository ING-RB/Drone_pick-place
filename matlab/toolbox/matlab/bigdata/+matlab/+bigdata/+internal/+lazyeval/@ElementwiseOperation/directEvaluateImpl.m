function varargout = directEvaluateImpl(obj, varargin)
% Evaluate function handle that represents this ElementwiseOperation.
% Method overriden from Operation.

%   Copyright 2022-2023 The MathWorks, Inc.

heights = cellfun(@(x) size(x, 1), varargin);
if numel(unique(heights(heights ~= 1))) >= 2
    matlab.bigdata.internal.throw(...
        MException(message('MATLAB:bigdata:array:IncompatibleTallSize')));
end
fh = obj.getCheckedFunctionHandle();
[varargout{1 : nargout}] = feval(fh, varargin{:});
end
