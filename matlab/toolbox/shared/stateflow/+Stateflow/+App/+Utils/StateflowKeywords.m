classdef StateflowKeywords
    properties
        %operators
        count = 'count';
        in = 'in';
        after = 'after';
        at = 'at';
        every = 'every';
        second = 'sec';
        tick = 'tick';
        hasChanged = 'hasChanged';
        hasChangedFrom = 'hasChangedFrom';
        hasChangedTo = 'hasChangedTo';
        elapsed = 'elapsed';
        t = 't';
        et = 'et';
        temporalCount = 'temporalCount';
        classQualifier = 'this';
        
        
        %public api
        step = 'step';
        getDisp = 'disp';
        getActiveStatesFcn = 'getActiveStates';
        reset = 'reset';
        delete = 'delete';
        setter = 'set';
        getter = 'get';
        
        
        %internal hidden-public properties
        StateflowInternalData = 'StateflowInternalData';
        StateflowInternalConstData = 'StateflowInternalConstData';
        
        %internal hidden-public methods
        routeEvent = 'fRouteEvent';
        timerCallback = 'fTimerCallback';
        
        
    end
end
