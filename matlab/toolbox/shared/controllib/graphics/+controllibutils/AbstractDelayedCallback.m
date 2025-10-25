% AbstractDelayedCallback class

%  Copyright 2008 The MathWorks, Inc.

classdef AbstractDelayedCallback < handle
    properties(SetAccess='private',GetAccess = 'private')
        DelayedCallbackListeners;
    end

    methods
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function addDelayedCallbackListener(this,CallbackObject,fcn)
            hCallback = handle(CallbackObject);
            L = handle.listener(hCallback,'delayed',{@LocalExtractJavaDataFcn,fcn});
            this.DelayedCallbackListeners = [this.DelayedCallbackListeners;L];    
        end
    

        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function deleteDelayedCallbackListeners(this)
            delete(this.DelayedCallbackListeners)
        end

    end

end

 

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LocalExtractJavaDataFcn(es,ed,fcn)
feval(fcn{1},es,ed.JavaEvent,fcn{2:end});
end

