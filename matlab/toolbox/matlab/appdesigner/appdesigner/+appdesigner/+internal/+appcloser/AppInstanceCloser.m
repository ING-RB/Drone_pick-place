classdef AppInstanceCloser < appdesigner.internal.appcloser.RunningInstanceCloser
    %APPINSTANCECLOSER Closes the running app instance of standard and
    %responsive apps
    
    % Copyright 2021, MathWorks Inc.
    
    methods
        function obj = AppInstanceCloser(runningInstance)
            obj@appdesigner.internal.appcloser.RunningInstanceCloser(runningInstance);
        end
        
        function closeRunningInstance(obj)
            obj.RunningInstance.delete();
        end
    end
end

