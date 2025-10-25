function pushToEventQueue(aSfxObject, aMethodName, varargin)
    %@todo: varargin with name value pair at callsite
    if length(aSfxObject.StateflowInternalData.QueuedMethodNames) < aSfxObject.StateflowInternalData.ConfigurationOptions.EventQueueSize
        aSfxObject.StateflowInternalData.QueuedMethodNames{end+1} = aMethodName;
        aSfxObject.StateflowInternalData.QueuedMethodArguments{end+1} = varargin{:}';
    else
        warnId = 'MATLAB:sfx:QueueIsFull';
        msg = getString(message(warnId, num2str(aSfxObject.StateflowInternalData.ConfigurationOptions.EventQueueSize)));
        Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwWarning(warnId, msg, aSfxObject.StateflowInternalConstData.ChartName);
    end
end
