classdef FigureReadyForLaunchToken < handle
% FIGUREREADYFORLAUNCHTOKEN Simple class that encapsulates the state of Figure infrastructure
% readiness in the Desktop with a timeout that can be used in a waitfor.

% Copyright 2024 The MathWorks, Inc.

    properties (Access = private)
        StartTime
        TimeOutDuration = seconds(120);
    end

    properties (Dependent)
        DoneWaiting
        Loaded
    end

    methods
        function obj = FigureReadyForLaunchToken()
            obj.StartTime = datetime("now");
        end
        
        function l = get.Loaded(~)
            l = matlab.ui.internal.getDesktopFigureReadyForLaunch;
        end

        function dw = get.DoneWaiting(obj)
            % Check for timeout
            TimeNow = datetime("now");
            timeout = (TimeNow - obj.StartTime) > obj.TimeOutDuration;

            % Ready if infrastructure loaded or timeout
            dw = timeout || obj.Loaded;
        end
    end
end
