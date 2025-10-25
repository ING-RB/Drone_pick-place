function processEventQueue(aSfxObject)
    %@todo: varargin with name value pair at callsite
    if isempty(coder.target)
        processEventQueueForMATLAB(aSfxObject);
    else
        processEventQueueForMATLABCoder(aSfxObject);
    end
end
function processEventQueueForMATLAB(aSfxObject)
    while(~isempty(aSfxObject.StateflowInternalData.QueuedMethodNames))
        nextMethodName = aSfxObject.StateflowInternalData.QueuedMethodNames{1};
        nextMethodArguments = aSfxObject.StateflowInternalData.QueuedMethodArguments{1};
        aSfxObject.StateflowInternalData.QueuedMethodNames =  aSfxObject.StateflowInternalData.QueuedMethodNames(2:end);
        aSfxObject.StateflowInternalData.QueuedMethodArguments =  aSfxObject.StateflowInternalData.QueuedMethodArguments(2:end);
        if isempty(nextMethodArguments)
            aSfxObject.(nextMethodName);
        else
            aSfxObject.(nextMethodName)(nextMethodArguments{:});
        end
    end
end

function processEventQueueForMATLABCoder(aSfxObject) %#ok<INUSD>
end
  