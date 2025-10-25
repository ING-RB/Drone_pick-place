classdef ros2rate < ros.internal.mixin.InternalAccess & ...
        coder.ExternalDependency
% This class is for internal use only. It may be removed in the future.
%
% ros2rate - Code generation equivalent for ros2rate
% See also ros2rate

% Copyright 2022 The MathWorks, Inc.
%#codegen

    properties
        %DesiredRate - Desired execution rate (Hz)
        DesiredRate

        %DesiredPeriod - Desired time period between executions (seconds)
        DesiredPeriod
    end

    properties (Access = protected)
        %StartTime - Start time at construction or reset (seconds)
        StartTime

        %PreviousPeriod - Time at previous waitfor call
        PreviousPeriod

        %IsReset - Indicator on whether rclcpp::Rate get reset
        IsReset

        %InternalLastPeriod - Internal Elapsed time between last two waitfor calls (seconds)
        InternalLastPeriod
    end

    properties (SetAccess = protected)
        %OverrunAction - Action used for handling overruns
        OverrunAction
    end

    properties(Dependent, SetAccess = protected)
        %IsSimulationTime - Indicate if simulation time is used
        %   This property will be "true" if the "/use_sim_time" ROS
        %   parameter was set to true when the parent node was launched.
        IsSimulationTime

        %TotalElapsedTime - Elapsed time since construction or reset (seconds)
        TotalElapsedTime

        %LastPeriod - Elapsed time between last two waitfor calls (seconds)
        LastPeriod
    end

    properties(Access={?ros.internal.codegen.ros2rate, ?matlab.unittest.TestCase})
        %LastWakeTime - The completion time of the last WAITFOR call
        %   This is used to detect time retrogression.
        %   Default: NaN
        LastWakeTime
        %NextExecutionIndex - Track the expected index for the next execution
        %   This index refers to the integer multiple of DesiredPeriod, at
        %   which the next execution should occur. The next execution time
        %   can be calculated as follows:
        %   nextExecutionTime = ExecutionStartTime + NextExecutionIndex*DesiredPeriod
        NextExecutionIndex
        %ExecutionStartTime - Track the reference time for future executions
        %    All loop executions should occur at integer multiples of
        %    DesiredPeriod, relative to the baseline ExecutionStartTime.
        %
        %    executionTime = ExecutionStartTime + i * DesiredPeriod, where
        %    i is a non-negative integer.
        ExecutionStartTime
    end

    properties (Access = private)
        CheckPeriod = 0.01
    end

    methods
        function obj = ros2rate(node, desiredRate)
        %ROS2RATE - Constructor for ros2rate object
        %   Please see the class documentation for more details.
        %   See also: ros2rate.

            coder.inline('never');
            narginchk(2,2);

            %% Check input arguments
            % Validate input ros2node
            validateattributes(node, {'ros2node'},{'scalar'}, ...
                               'ros2rate','node');
            % The input argument desiredRate must be a numeric scalar
            validateattributes(desiredRate,{'numeric','positive'},{'scalar'}, ...
                               'ros2rate','desiredRate');

            coder.cinclude('rclcpp/rclcpp.hpp');
            coder.cinclude('mlros2_time.h');

            % Validate time source before moving forward. This ensures we
            % always get the time message/system time as expected. Without
            % validation, network latency might affect this feature.
            isTimeValid = false;
            while ~isTimeValid
                isTimeValid = obj.isTimeSourceValid();
            end

            obj.DesiredRate = desiredRate;
            obj.DesiredPeriod = 1.0/obj.DesiredRate;
            obj.PreviousPeriod = obj.getCurrentTime;
            obj.OverrunAction = 'slip';
            obj.InternalLastPeriod = NaN;
            obj.LastWakeTime = NaN;
            obj.reset;
            obj.ExecutionStartTime = obj.getCurrentTime;
        end

        function numMisses = waitfor(obj)
        %WAITFOR - Pause the code execution to achieve desired execution rate
        %   Please see the class documentation for more details.
        %   See also: rateControl

            currentTime = obj.getCurrentTime;

            % By default, assume that no overrun occurs, so the number of
            % missed execution tasks is 0.
            numMisses = 0;

            if currentTime < obj.LastWakeTime
                % If time goes backwards, the ros2rate resets its time
                % related parameters.
                % This can happen if the TimeProvider does not provide a
                % monotonically increasing time. For example, when Gazebo
                % get reset at certain moment.
                obj.recoverFromClockReset(currentTime);
                return;
            end

            % Decide how long the sleep should last by checking the
            % difference between the intended end time and the current time.
            obj.NextExecutionIndex = obj.NextExecutionIndex + 1;
            sleepTime = obj.NextExecutionIndex*obj.DesiredPeriod + obj.ExecutionStartTime - currentTime;

            % Handle different overrun actions. If sleepTime is negative,
            % an overrun occurred.
            if sleepTime < 0
                % Calculate the number of missed task executions. The
                % sleepTime is negative, so numMisses will be at least 1.
                % If sleepTime is an exact integer multiple of
                % obj.DesiredPeriod, the last scheduled task should not be
                % counted as a miss.
                numMisses = ceil(abs(sleepTime / obj.DesiredPeriod));

                switch obj.OverrunAction
                    % So far we only support 'slip' as the overrun action. This
                    % will be used in future enhancement.
                  case 'drop'
                    obj.NextExecutionIndex = ceil((currentTime-obj.ExecutionStartTime)/obj.DesiredPeriod);
                    sleepTime = obj.NextExecutionIndex*obj.DesiredPeriod + obj.ExecutionStartTime - currentTime;
                  case 'slip'
                    obj.NextExecutionIndex = 0;
                    obj.ExecutionStartTime = currentTime;
                    sleepTime = 0;
                  otherwise
                    assert(false,'OverrunAction is not valid.');
                end
            end

            obj.internalSleep(sleepTime);

            % Detect time retrogression during sleep and adjust the
            % recorded past periods.
            currentTime = obj.getCurrentTime - obj.StartTime;
            if  currentTime > obj.LastWakeTime
                obj.LastWakeTime = currentTime;
            else
                obj.recoverFromClockReset(currentTime);
            end

            % Update PreviousPeriod and InternalLastPeriod
            obj.InternalLastPeriod = obj.getCurrentTime - obj.PreviousPeriod;
            obj.PreviousPeriod = obj.getCurrentTime;

            % LastPeriod becomes available again once we call waitfor after
            % reset
            obj.IsReset = false;
        end

        function reset(obj)
        %RESET - Sets the start time for the rate to now.

            obj.LastWakeTime = 0;
            obj.StartTime = obj.getCurrentTime;
            obj.IsReset = true;
            obj.NextExecutionIndex = 0;
            obj.ExecutionStartTime = 0;
        end

        function statistics(~)
        %STATISTICS - statistics of past execution periods
        %   This method does not support codegen. Please see the class
        %   documentation for more details.
        %   See also: rateControl

            coder.internal.assert(false, 'ros:mlros2:codegen:UnsupportedMethodCodegen', ...
                                  'statistics');
        end

        function isSimTime = get.IsSimulationTime(~)
        %get.IsSimulationTime - getter for IsSimulationTime

            coder.cinclude('mlros2_time.h');
            isSimTime = coder.nullcopy(false);
            isSimTime = coder.ceval('getSimTime');
        end

        function totalElapsedTime = get.TotalElapsedTime(obj)
        %get.TotalElapsedTime - getter for TotalElapsedTime

            totalElapsedTime = obj.getCurrentTime - obj.StartTime;
        end

        function lastPeriod = get.LastPeriod(obj)
        %get.LastPeriod - getter for LastPeriod
            if obj.IsReset
                lastPeriod = NaN;
            else
                lastPeriod = obj.InternalLastPeriod;
            end
        end
    end

    methods (Access={?ros.internal.codegen.ros2rate, ?matlab.unittest.TestCase})
        function time = getCurrentTime(obj)
            coder.inline('never');
            timeStruct = ros2message("builtin_interfaces/Time");
            isSystemTime = ~obj.IsSimulationTime;
            coder.ceval('time2struct', coder.wref(timeStruct), isSystemTime);
            time = double(timeStruct.sec) + double(timeStruct.nanosec)*1e-9;
        end

        function recoverFromClockReset(obj, currentTime)
        %recoverFromClockReset Reset time-related properties

            obj.reset;
            obj.LastWakeTime = currentTime;
        end

        function internalSleep(obj, sleepTime)
        %internalSleep Pause until sleep time reached
            coder.inline('never');
            % Sleep for the desired amount of time.
            lastWakeTime = obj.getCurrentTime - obj.StartTime;
            endTime = lastWakeTime + sleepTime;
            elapsedTime = obj.getCurrentTime - obj.StartTime;
            while elapsedTime < endTime
                pause(min(sleepTime, obj.CheckPeriod));
                % Update elapsed time reading
                elapsedTime = obj.getCurrentTime - obj.StartTime;
                % Detect time reset during sleep
                if elapsedTime < lastWakeTime
                    return
                end
                lastWakeTime = elapsedTime;
                sleepTime = endTime - elapsedTime;
            end
        end

        function isValid = isTimeSourceValid(obj)
        %isTimeSourceValid Check and see whether time source is valid
            isValid = obj.getCurrentTime > 0;
        end
    end

    methods (Static)
        function ret = getDescriptiveName(~)
            ret = 'ROS 2 Rate';
        end

        function ret = isSupportedContext(bldCtx)
            ret = bldCtx.isCodeGenTarget('rtw');
        end

        function updateBuildInfo(buildInfo, bldCtx)
            if bldCtx.isCodeGenTarget('rtw')
                srcFolder = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
                addIncludeFiles(buildInfo,'mlros2_time.h',srcFolder);
            end
        end
    end
end
