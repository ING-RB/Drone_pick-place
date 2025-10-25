classdef PlatformTrajectory < handle
% This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen
  
    properties (Abstract, SetAccess = protected)
        CurrentPosition
        CurrentVelocity
        CurrentAcceleration
        CurrentOrientation
        CurrentAngularVelocity
        CurrentPoseValid
    end
    
    methods (Abstract, Hidden)
        status = move(obj, simulationTime)
        restart(obj)
        initTrajectory(obj)
        initUpdateRate(obj, newUpdateRate)
    end
    
    methods (Hidden)
        function requestPose(obj)
            if ~obj.CurrentPoseValid
                initTrajectory(obj);
            end
        end
        
        function duration = trajectoryLifetime(~)
            duration = inf;
        end
        
        function start = startTime(~)
            start = 0;
        end
        
        function stop = stopTime(~)
            stop = inf;
        end
        
        function flag = isGeo(~)
            flag = false;
        end
    end
end
