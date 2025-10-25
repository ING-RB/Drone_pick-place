classdef ros2rate < ...
        rateControl & ...
        ros.internal.mixin.InternalAccess & ...
        robotics.core.internal.mixin.Unsaveable
%ros2rate Execute a loop at a fixed frequency
%   The ros2rate object allows you to run a loop at a fixed frequency.
%   It uses the ROS 2 node as a source for time information, so it can
%   handle both wall clock time (system time) and ROS 2 simulation time.
%
%   The accuracy of the rate execution is influenced by the scheduling
%   resolution of your operating system and by the level of other
%   system activity.
%
%   The ros2rate object relies on the PAUSE function. If "pause('off')"
%   is used to disable PAUSE, the rate execution will not be accurate.
%
%   R = ros2rate(NODE,DESIREDRATE) creates a ros2rate object R that
%   executes a loop at a fixed frequency equal to DESIREDRATE. The
%   DESIREDRATE is specified in Hz (executions per second). The
%   OverrunAction is set to 'slip'. The time source is linked to the
%   same time source as used by the valid ROS 2 node object NODE. The
%   default setting for OverrunAction is 'slip', which executes the
%   next loop immediately if the LastPeriod is greater than
%   DesiredPeriod.
%
%
%   ros2rate properties:
%      IsSimulationTime - Indicator if simulation time or wall clock time is used
%      DesiredRate      - Desired execution rate (Hz)
%      DesiredPeriod    - Desired time period between executions (seconds)
%      TotalElapsedTime - Elapsed time since construction or reset (seconds)
%      LastPeriod       - Elapsed time between last two waitfor calls (seconds)
%      OverrunAction    - Action used for handling overruns
%
%   ros2rate methods:
%      waitfor          - Pause the code execution to achieve desired execution rate
%      reset            - Reset the ros2rate object
%      statistics       - Returns the statistics of past execution periods
%
%
%   Example:
%       % Create a ros2node object
%       node = ros2node("/testTime");
%
%       % Create a ros2rate object to run at 20 Hz
%       frequency = 20;
%       r = ros2rate(node,frequency);
%
%       % Start looping
%       reset(r);
%       for i = 1:10
%           % User Code
%           waitfor(r)
%       end
%
%       % Clear workspace
%       clear
%
%   See also rateControl

%   Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        %IsSimulationTime - Indicator if simulation time or wall clock time is used
        IsSimulationTime
    end

    methods
        function obj = ros2rate(node, desiredRate)
        %ros2rate Constructor for ros2rate object
        %   Please see the class documentation for more details

            narginchk(2,2);

            % Initialize base class with desired rate
            obj@rateControl(desiredRate);

            % Parse input argument, node cannot be empty
            validateattributes(node,{'ros2node'},{'scalar'},...
                               'ros2rate','node');

            timeObj = ros.internal.ros2.Time(node);
            obj.IsSimulationTime = timeObj.IsUsingSimTime;

            node.ListofNodeDependentHandles{end+1} = matlab.internal.WeakHandle(obj);

            % Set time provider to the ROS 2 node time source (by default,
            % the rateControl base class uses the system time provider)
            if obj.IsSimulationTime
                obj.TimeProvider = ros.internal.ros2.NodeTimeProvider(node);
                obj.startTimeProvider;
            end
        end

        function delete(obj)
        %DELETE Shut down ROS2RATE object

            delete(obj.TimeProvider)
        end
    end

    methods (Access = protected)
        function s = saveobj(obj)
        %saveobj Raise errors when attempt to save the object.
            s = saveobj@robotics.core.internal.mixin.Unsaveable(obj);
        end
    end

    methods (Static, Access = protected)
        function obj = loadobj(s)
        %loadobj Raise errors when attempt to load the object.
            obj = loadobj@robotics.core.internal.mixin.Unsaveable(s);
        end
    end

    %----------------------------------------------------------------------
    % MATLAB Code-generation
    %----------------------------------------------------------------------
    methods (Static = true, Access = private)
        function name = matlabCodegenRedirect(~)
            name = 'ros.internal.codegen.ros2rate';
        end
    end
end
