function varargout = directEvaluateImpl(obj, varargin) %#ok<STOUT>
% Per-operation implementation for direct evaluation. Do not
% call this method directly, use directEvaluate instead
% (template pattern).
assert(false, ...
    'Assertion failed: %s does not support direct evaluation.', ...
    class(obj));
end