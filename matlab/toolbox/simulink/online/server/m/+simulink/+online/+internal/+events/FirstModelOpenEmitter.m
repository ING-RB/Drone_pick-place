% Copyright 2021 The MathWorks, Inc.
% Emitter for the first model open

classdef FirstModelOpenEmitter < handle
    properties (Constant)
        EventName = 'FirstModelOpen';
    end

    events
        FirstModelOpen
    end

     methods (Static, Access = public)
        function inst = getInstance()
            persistent s_inst;
            import simulink.online.internal.events.FirstModelOpenEmitter;
            if isempty(s_inst)
                s_inst = FirstModelOpenEmitter();
            end
            inst = s_inst;
        end
    end
end
