% Copyright 2021 The MathWorks, Inc.

classdef SessionEndTriggeredScheduler < simulink.online.internal.autosave.EventTriggeredScheduler

    methods (Access = public)
        function obj = SessionEndTriggeredScheduler(logger)
            % assert(~isempty(logger))
            import simulink.online.internal.autosave.SessionEndTriggeredScheduler;
            import simulink.online.internal.events.SessionEmitter;
            obj = obj@simulink.online.internal.autosave.EventTriggeredScheduler(...
                logger,...
                SessionEmitter.getInstance(),...
                @(src, callback)SessionEndTriggeredScheduler.addListenerToSessionEnd(src, callback),...
                @(src, hListener)SessionEndTriggeredScheduler.removeListenerFromSessionEnd(hListener)...
            );
        end
    end

    methods (Static, Access = public)
        function hListener = addListenerToSessionEnd(src, callback, varargin)
            import simulink.online.internal.events.SessionEmitter;
            hListener = src.connect( ...
                SessionEmitter.EVT_SAVE_SESSION, callback, varargin{:} ...
            );
        end  % addlistenerToSessionEnd

        function removeListenerFromSessionEnd(hListener)
            delete(hListener);
        end  % removelistenerFromSessionEnd
    end

    methods (Access = protected)
    end

    properties (Access = protected)
    end
end
