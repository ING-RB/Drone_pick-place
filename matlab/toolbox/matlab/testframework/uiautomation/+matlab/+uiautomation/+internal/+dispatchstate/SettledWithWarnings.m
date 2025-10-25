classdef SettledWithWarnings < matlab.uiautomation.internal.dispatchstate.Settled
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        Message
    end
    
    methods
        
        function state = SettledWithWarnings(msg)
            state.Message = msg;
        end
        
        function resolve(state)
            w = warning('query','backtrace');
            cleanup = onCleanup(@()warning(w));
            warning('backtrace','off'); % concise warnings
            warning(state.Message)
        end
        
    end
    
end