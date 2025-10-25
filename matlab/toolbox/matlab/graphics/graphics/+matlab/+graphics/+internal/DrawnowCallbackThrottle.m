classdef DrawnowCallbackThrottle < handle
    %  Copyright 2024 The MathWorks, Inc.
    % DrawnowCallbackThrottle Class that coalesces calls to
    % matlab.graphics.internal.drawnow.callback so that they are not queued


    properties (Access = private)
        InFlightMap % Map for storing inFlight logic.
        CallbackMap % Map for storing the callbacks.
    end

    methods (Static)
        function output = getInstance()
            persistent singletonObj
            mlock
            if isempty(singletonObj) || ~isvalid(singletonObj)
                singletonObj =  matlab.graphics.internal.DrawnowCallbackThrottle;
            end
            output = singletonObj;
        end
    end

    methods (Access = private)
        function obj = DrawnowCallbackThrottle()
            obj.InFlightMap = containers.Map;
            obj.CallbackMap = containers.Map;
        end
    end

    methods (Access = public)    
        function postCallback(obj, actionID, callback)
            % 'actionID' is the unique string associated to the callback function
            % 'callback' is the function handle to be coalesced
            % For example:
            % h = matlab.graphics.internal.DrawnowCallbackThrottle.getInstance()
            % cb = @() disp('123');
            % h.postCallback('unique-action-ID', cb);
            % this will postpone the execution of function 'cd' after the next drawnow

            if ~ obj.InFlightMap.isKey(actionID)
                obj.InFlightMap(actionID) = false;
            end
            obj.CallbackMap(actionID) = callback;
            obj.postCallbackFactory(actionID);
        end

    end
    methods(Access = private)
        function postCallbackFactory(obj, actionID)
            % Add a callback or modify an existing callback to be executed
            % at the next drawnow
            % If there is no pending call to
            % matlab.graphics.internal.drawnow.callback start it
            % Mark the InFlightMap to true so that there is only one
            % pending callback
            if ~ obj.InFlightMap(actionID)
                obj.InFlightMap(actionID) = true;
                matlab.graphics.internal.drawnow.callback(@(~) obj.drawnowCallback(actionID));
            end
        end

        function drawnowCallback(obj, actionID)
            % Asynchronous operations can error out because objects may
            % have been deleted. Make sure not to leave the InFlight true
            try
                feval(obj.CallbackMap(actionID));
            catch

            end
            obj.InFlightMap(actionID) = false;
        end
    end
end