% Copyright 2021 The MathWorks, Inc.

classdef PreferenceChangeEmitter < simulink.online.internal.events.ExceptionLogEmitter
    % Will only emit limited preference changes published by UI callbacks

    properties (Constant)
        EVT_CHANGE_ON_SL_PREF_DIALOG = 'changeOnSLPreferenceDialog';
    end

    methods (Static, Access = public)
        function inst = getInstance()
            % TODO: add online resource manager to host all singletons
            persistent s_inst;
            import simulink.online.internal.events.PreferenceChangeEmitter;
            if isempty(s_inst)
                s_inst = PreferenceChangeEmitter();
            end
            inst = s_inst;
        end
    end

    methods (Access = protected)
        function obj = PreferenceChangeEmitter()
            logger = simulink.online.internal.events.getEventsLogger();
            obj = obj@simulink.online.internal.events.ExceptionLogEmitter(...
                logger ...
            );
        end  % PreferenceChangeEmitter
    end

    properties (Access = protected)
    end

    events
        % TODO:change to ListenAccess = {?simulink.online.internal.events.ExceptionLogEmitter}
        % when membership method: connect is used everywhere
        changeOnSLPreferenceDialog
    end
end
