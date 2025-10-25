% Copyright 2021 The MathWorks, Inc.

classdef SessionEmitter< simulink.online.internal.events.ExceptionLogEmitter
    properties (Constant)
        EVT_SAVE_SESSION = 'saveSession'
    end
    % Invoked by Matlab session events and emit to internal observer
    methods (Static, Access = public)
        function inst = getInstance()
            % TODO: add online resource manager to host all singletons
            import simulink.online.internal.events.SessionEmitter;
            persistent s_inst;
            if isempty(s_inst)
                s_inst = SessionEmitter();
            end
            inst = s_inst;
        end  % getInstance
    end

    methods (Access = public)
    end

    methods (Access = protected)
        function obj = SessionEmitter()
            logger = simulink.online.internal.events.getEventsLogger();
            obj = obj@simulink.online.internal.events.ExceptionLogEmitter(...
                logger ...
            );
        end
    end

    properties (Access = protected)
    end

    events (ListenAccess = {?simulink.online.internal.events.ExceptionLogEmitter})
        %TODO: change to session end events after hooking up slonline session end pipeline
        saveSession
    end
end
