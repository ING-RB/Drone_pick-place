classdef ViewModelListenerPlaceholder < appdesservices.internal.interfaces.view.ViewModelOperationPlaceholder
    %VIEWMODELLISTENERPLACEHOLDER A place holder to queue addlistener() 
    % call to a ViewModel

    % Copyright 2024 MathWorks, Inc.
    
    properties (SetAccess = private)
        EventName
        Callback
    end

    properties (Access = private)
        Listener
    end
    
    methods
        function obj = ViewModelListenerPlaceholder(eventName, callback)
            obj.EventName = eventName;
            obj.Callback = callback;
        end
        
        function attach(obj, vm)
            obj.Listener = addlistener(vm, obj.EventName, obj.Callback);
        end

        function delete(obj)
            delete(obj.Listener);
        end
    end
end

