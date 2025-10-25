classdef AppSavedObserver < handle
    
    properties
        Status
        Exception
    end

    properties (Access = private)
        Observer
        Listener
    end

    methods
        function obj = AppSavedObserver(observer)
            obj.Observer = observer;

            obj.Listener = addlistener(obj.Observer, 'SaveActionCompleted', @obj.handleAppSaved);
        end
    end

    methods (Access = private)
        function handleAppSaved(obj, ~, event)
            obj.Status = event.Status;
            obj.Exception = event.Exception;
        end
    end
end