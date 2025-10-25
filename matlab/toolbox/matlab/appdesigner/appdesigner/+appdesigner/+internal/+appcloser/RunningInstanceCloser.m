classdef (Abstract) RunningInstanceCloser < handle
    %RUNNINGINSTANCECLOSER Strategized method of closing an app instance
    %from AppDesigner
    
    % Copyright 2021, MathWorks Inc.
    
    properties (Access = protected)
        RunningInstance % Reference to the running instance
    end
    
    methods (Access = public)
        function obj = RunningInstanceCloser (runningInstance)
            obj.RunningInstance = runningInstance;
        end
    end
    
    methods (Abstract)
        closeRunningInstance(obj)
    end
end

