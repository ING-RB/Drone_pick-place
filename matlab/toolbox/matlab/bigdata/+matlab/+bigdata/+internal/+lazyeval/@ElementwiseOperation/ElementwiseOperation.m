%ElementwiseOperation
% An operation that acts on each element of data.
%
% Properties:
% FunctionHandle - Function handle for the operation.
%
% Overriden methods from Operation:
% varargout = directEvaluateImpl(obj, varargin)
% tasks = createExecutionTasks(obj, TaskDependencies, inputFutureMap)
%
% Overriden methods from SlicewiseFusableOperation
% tf = isSlicewiseFusable(obj)
% fh = getCheckedFunctionHandle(obj)

% Copyright 2015-2022 The MathWorks, Inc.
