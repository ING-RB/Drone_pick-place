%SlicewiseOperation
% An operation that acts on each slice of data.
%
% Properties:
% FunctionHandle - Function handle for the operation.
% AllowTallDimExpansion - Logical scalar that specifies if this slicewise
% operation is allowed to use singleton expansion in the tall dimension.
%
% Overriden methods from Operation:
% tasks = createExecutionTasks(obj, TaskDependencies, inputFutureMap)
%
% Overriden methods from SlicewiseFusableOperation
% tf = isSlicewiseFusable(obj)
% fh = getCheckedFunctionHandle(obj)

% Copyright 2015-2022 The MathWorks, Inc.
