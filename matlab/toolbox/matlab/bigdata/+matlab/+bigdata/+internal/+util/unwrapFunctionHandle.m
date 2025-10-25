function functionHandle = unwrapFunctionHandle(functionHandle)
%UNWRAPFUNCTIONHANDLE unwraps the underlying function handle of special function handle classes.
%
% FCN = UNWRAPFUNCTIONHANDLE(functionHandle) unwraps the most underlying
% function handle FCN when FUNCTIONHANDLE is one of the following special
% function handle classes:
%  - matlab.bigdata.internal.FunctionHandle
%  - matlab.bigdata.internal.io.ExternalSortFunction
%  - matlab.bigdata.internal.io.WriteFunction
%  - matlab.bigdata.internal.lazyeval.GroupedByKeyFunction
%  - matlab.bigdata.internal.lazyeval.TaggedArrayFunction
%  - matlab.bigdata.internal.optimizer.FusedSlicewiseFunction
%  - matlab.bigdata.internal.splitapply.AdvancedGroupedFunction
%  - matlab.bigdata.internal.splitapply.GroupedFunction
%  - matlab.bigdata.internal.splitapply.GroupedPartitionfunFunction
%  - matlab.bigdata.internal.util.StatefulFunction
%  - function_handle
%  - Any combination of the above

%   Copyright 2022 The MathWorks, Inc.

% Most of these special function handle classes store the underlying
% function handle in "Handle". We include here special handling for those
% that have the function handle stored in a different property.
while true
    if isprop(functionHandle, "Handle")
        functionHandle = functionHandle.Handle;
    elseif isa(functionHandle, "matlab.bigdata.internal.io.ExternalSortFunction")
        functionHandle = functionHandle.SortFunctionHandle;
    elseif isa(functionHandle, "matlab.bigdata.internal.io.WriteFunction")
        functionHandle = functionHandle.WriterFactory;
    elseif isa(functionHandle, "matlab.bigdata.internal.splitapply.GroupedPartitionfunFunction")
        functionHandle = functionHandle.UnderlyingFunction;
    elseif isa(functionHandle, "matlab.bigdata.internal.optimizer.FusedSlicewiseFunction")
        % FusedSlicewiseFunction contains multiple function handles in the
        % property "Functions". For better usability we return an empty
        % string instead.
        functionHandle = "";
    else
        break;
    end
end
end