classdef NodeTimeProvider < robotics.core.internal.TimeProvider
%NodeTimeProvider A time provider synchronized with ROS 2 node time
%
%   NodeTimeProvider properties:
%       IsInitialized    - Indication if the time provider has been initialized
%       IsSimulationTime - Indication if time source is simulated or wall time
%
%   NodeTimeProvider methods:
%       rest             - Reset the time provider
%       sleep            - Sleep for a number of seconds
%       getElapsedTime   - Returns the elapsed time since the time provider was reset (seconds)
%
%   See also robotics.core.internal.SystemTimeProvider.

%   Copyright 2022-2024 The MathWorks, Inc.

    properties (Dependent, SetAccess = protected)
        %IsInitialized - Indication if the time provider has been initialized
        %   Use the RESET method to initialize the time provider.
        IsInitialized

        %IsSimulationTime - Indication if time source is simulated or wall time
        IsSimulationTime
    end

    properties (Access = ?matlab.unittest.TestCase)
        %StartTime - The time when the time provider was started
        StartTime = ros2message("builtin_interfaces/Time")

        %Clock - The node time source to the NodeTimeProvider
        Clock
    end

    properties (Access = private)
        %CheckPeriod - Period for checking simulation time
        % Due to the varying ratio between simulation and real time, it
        % is necessary to check whether simulation time has reached
        % the end. The current implementation checks simulation
        % time at the rate of 100 Hz, about equal to the Gazebo clock
        % frequency. The overhead of frequent checks can be higher
        % than the error introduced by less frequent checking.
        CheckPeriod = 0.01
    end

    methods
        function obj = NodeTimeProvider(node)
        %NodeTimeProvider Constructor for NodeTimeProvider
        %   Please see the class documentation for more details
        %   See also ros.internal.ros2.NodeTimeProvider
            validateattributes(node, {'ros2node'}, {'scalar'}, ...
                               'NodeTimeProvider', 'node');
            obj.Clock = ros.internal.ros2.Time(node);
        end

        function elapsedTime = getElapsedTime(obj)
        %getElapsedTime Returns the elapsed time since the time provider was reset (seconds)
        %   You need to call RESET to initialize the time provider before
        %   you can call this method.

            coder.internal.errorIf(~obj.isStartTimeValid,'shared_robotics:robotutils:timeprovider:TimeProviderNotInitialized');

            currentTime = obj.Clock.CurrentTime;
            elapsedTime = double(currentTime.sec - obj.StartTime.sec) + ...
                double(currentTime.nanosec - obj.StartTime.nanosec)*10^-9;
        end

        function started = get.IsInitialized(obj)
            started = obj.isStartTimeValid;
        end

        function isSim = get.IsSimulationTime(obj)
            isSim = obj.Clock.IsUsingSimTime;
        end

        function success = reset(obj)
        %RESET Reset the time provider
        %   This resets the initial state of the time provider. You have to
        %   call RESET before you can call any other methods on the object.
        %   This function returns whether the time provider has been
        %   successfully reset.

            obj.StartTime = obj.Clock.CurrentTime;
            success = obj.isStartTimeValid;
        end

        function sleep(obj, seconds)
        %SLEEP Sleep for a number of seconds
        %   This sleep uses the time information from the ROS 2 node.
        %   You need to call RESET to initialize the time provider before
        %   you can call this method.

            coder.internal.errorIf(~obj.isStartTimeValid,'shared_robotics:robotcore:rate:TimeProviderNotInitialized');

            % For negative sleep time, don't sleep at all
            if seconds <= 0
                return
            end

            if obj.IsSimulationTime

                lastWakeTime = obj.getElapsedTime;
                endTime = lastWakeTime + seconds;

                elapsedTime = obj.getElapsedTime;
                while elapsedTime < endTime

                    pause(min(seconds, obj.CheckPeriod));

                    % Update elapsed time reading
                    elapsedTime = obj.getElapsedTime;

                    % Detect time reset during sleep
                    if elapsedTime < lastWakeTime
                        return
                    end

                    lastWakeTime = elapsedTime;
                    seconds = endTime - elapsedTime;
                end
            else
                pause(seconds);
            end

        end

        function delete(obj)
        % DELETE delete the object

            delete(obj.Clock);
        end
    end

    methods (Access = private)
        function valid = isStartTimeValid(obj)
        %isStartTimeValid Check if StartTime property contains a valid value
            valid = ~isempty(obj.StartTime) && seconds(double(obj.StartTime.sec)+double(obj.StartTime.nanosec)*1e-9) > 0;
        end
    end
end
