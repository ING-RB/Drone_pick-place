classdef UserComponentInstanceCloser < appdesigner.internal.appcloser.RunningInstanceCloser
    %USERCOMPONENTINSTANCECLOSER Closing the running app instance of user
    %components authored in App Designer
    
    % Copyright 2021, MathWorks Inc.
    
    methods
        function obj = UserComponentInstanceCloser(runningInstance)
            obj@appdesigner.internal.appcloser.RunningInstanceCloser(runningInstance);
        end
        
        function closeRunningInstance(obj)
            obj.RunningInstance.Parent.delete();
        end
    end
end

