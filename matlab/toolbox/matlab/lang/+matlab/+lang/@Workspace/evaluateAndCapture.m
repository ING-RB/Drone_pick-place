function [T , varargout] = evaluateAndCapture(obj, expression)
arguments
    obj
    expression {mustBeTextScalar}
end
[T, varargout{1:nargout-1}] = obj.m_workspace.runIn(expression);
end
%   Copyright 2024 The MathWorks, Inc.