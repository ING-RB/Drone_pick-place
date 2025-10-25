classdef rateControl < handle
%rateControl Execute loop at a fixed frequency
%   The rateControl class allows you to run a loop at a fixed frequency.
%   It also collects statistics about the timing of the loop
%   iterations.
%
%   The accuracy of the rate execution is influenced by the scheduling
%   resolution of your operating system and by the level of other
%   system activity.
%   The rateControl object relies on the PAUSE function. If "pause('off')"
%   is used to disable PAUSE, the rate execution will not be accurate.
%
%   R = rateControl(DESIREDRATE) creates a rate object R that executes
%   a loop at a fixed frequency equal to DESIREDRATE. The DESIREDRATE is
%   specified in Hz (executions per second).
%   The default setting for OverrunAction is 'slip', which executes the
%   next loop immediately if the LastPeriod is greater than DesiredPeriod.
%
%
%   rateControl properties:
%      DesiredRate      - Desired execution rate (Hz)
%      DesiredPeriod    - Desired time period between executions (seconds)
%      TotalElapsedTime - Elapsed time since construction or reset (seconds)
%      LastPeriod       - Elapsed time between last two waitfor calls (seconds)
%      OverrunAction    - Action used for handling overruns
%
%   rateControl methods:
%      waitfor      - Pause the code execution to achieve desired execution rate
%      reset        - Reset the rateControl object
%      statistics   - Returns the statistics of past execution periods
%
%
%   Example:
%
%       % Create a rate object running at 20 Hz
%       r = rateControl(20);
%
%       % Start loop right away
%       tic
%       for i = 1:30
%          toc
%          % User Code goes here
%
%          % Sleep to maintain the 20 Hz loop rate
%          waitfor(r)
%       end
%
%       % Reset the rate object to run another loop.
%       reset(r);
%       for i = 1:10
%          % User Code goes here
%          waitfor(r)
%       end
%
%   See also robotics.ros.rateControl

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

    properties (SetAccess = protected)
        %DesiredRate - Execution rate (Hz).
        %   The execution rate (Hz) of a looping code segment that the
        %   object maintains.
        %   This is the inverse of the DesiredPeriod.
        DesiredRate

        %DesiredPeriod - The desired time period between executions (seconds).
        %   This is the inverse of the DesiredRate.
        DesiredPeriod
    end

    properties (Dependent)
        %OverrunAction - Method used for handling overruns
        %   If the elapsed time between two WAITFOR calls is greater than
        %   DesiredPeriod, then the second WAITFOR call behaves according
        %   to the OverrunAction property.
        %   If the OverrunAction is 'slip', the WAITFOR call returns
        %   immediately.
        %   If the OverrunAction is 'drop', the WAITFOR method pauses
        %   execution until the next integer multiple of the desired period.
        %
        %   Default: 'slip'
        OverrunAction
    end

    properties (Dependent, SetAccess = protected)
        %TotalElapsedTime - Elapsed time since object construction or reset (seconds)
        %   Accumulated time (in seconds) that has elapsed since the rate
        %   object was constructed or reset.
        %
        %   Default: 0
        TotalElapsedTime

        %LastPeriod - Elapsed time between last two WAITFOR calls (seconds)
        %   Elapsed time (seconds) between the last two WAITFOR calls. If WAITFOR
        %   is called only once after object construction, this returns
        %   the time period between construction and the
        %   WAITFOR call. Before the first WAITFOR is called, this has a value of
        %   NaN.
        %
        %   Default: NaN
        LastPeriod
    end

    properties (Constant, Access = {?rateControl, ?matlab.unittest.TestCase})
        %ValidOverrunActions - All valid overrun handling methods
        ValidOverrunActions = {'drop', 'slip'}

        %MemoryLength - Defines the upper bound of how many periods can be stored in memory
        %   This is used for calculating execution statistics.
        %
        %   Default: 1000
        MemoryLength = 1000
    end

    properties (Access = {?rateControl, ?matlab.unittest.TestCase})
        %LastWakeTime - The completion time of the last WAITFOR call
        %   This is used to detect time retrogression.
        %   Default: NaN
        LastWakeTime

        %TimeProvider - The TimeProvider object
        %   Changing the time provider allows the rate object to work with
        %   different time sources, for example system time or simulated
        %   time.
        TimeProvider

        %PastPeriods - Circular buffer that stores the periods between WAITFOR calls (seconds)
        %   The number of periods in this buffer (buffer size) is defined by
        %   MemoryLength. This is used for calculating execution statistics.
        PastPeriods

        %InternalOverrunAction - Indicates the selected overrun method
        %   Internal storage for dependent OverrunAction property.
        InternalOverrunAction

        %PeriodCount - Number of completed waitfor periods since last construction or RESET
        %   A waitfor period is completed when the WAITFOR method runs to
        %   completion and no time retrogression occurs.
        %   This period count is used for calculating execution statistics.
        PeriodCount

        %NumOverruns - Number of overruns since last construction or RESET
        %   This is used for calculating execution statistics.
        NumOverruns

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

    methods
        function obj = rateControl(desiredRate)
        %rateControl Constructor for rateControl object
        %   Please see the class documentation for more details.
        %   See also rateControl

            narginchk(1,1);

            % Validate the rate input and store it
            validateattributes(desiredRate, {'numeric'}, {'scalar', 'real', 'positive', 'nonnan', 'finite'}, ...
                               'rateControl', 'desiredRate');
            obj.DesiredRate = double(desiredRate);
            obj.DesiredPeriod = 1.0/obj.DesiredRate;

            if coder.target('MATLAB')
                coder.internal.warningIf(strcmp(pause('query'), 'off'),'shared_robotics:robotcore:rate:PauseDisabled');
            end

            % Use system time as timing source
            obj.TimeProvider = robotics.core.internal.SystemTimeProvider;

            % Default overrun method is 'slip'. Set both the internal
            % action and execute the custom setter to initialize other
            % properties.
            obj.InternalOverrunAction = robotics.core.internal.OverrunActions.Slip;
            obj.OverrunAction = 'slip';

            obj.reset;
        end


        function numMisses = waitfor(obj)
        %WAITFOR Pause the execution to achieve desired execution rate
        %   WAITFOR(OBJ) pauses execution for an appropriate time to
        %   achieve the desired execution rate. The function accounts
        %   for the time that is spent executing user code between
        %   WAITFOR calls.
        %
        %   NUMMISSES = WAITFOR(OBJ) returns the number of missed task
        %   executions since the last WAITFOR call. If NUMMISSES is > 0,
        %   an overrun occurred.
        %
        %   If more than the DesiredPeriod of time elapsed between two WAITFOR
        %   calls, then the second WAITFOR call behaves according
        %   to the OverrunAction property.
        %
        %   If WAITFOR detects that the time regressed, the state of the
        %   object resets to use this new time as a baseline.
        %
        %   Example:
        %
        %      % Create a rate object running at 5 Hz
        %      r = rateControl(5);
        %
        %      for i = 1:2
        %         WAITFOR(r);
        %      end

        % Get current time and use it to decide how long to sleep
            currentTime = obj.TimeProvider.getElapsedTime;

            % By default, assume that no overrun occurs, so the number of
            % missed execution tasks is 0.
            numMisses = 0;

            if currentTime < obj.LastWakeTime
                % If time goes backwards, the rateControl resets its time
                % related parameters.
                % This can happen if the TimeProvider does not provide a
                % monotonically increasing time.
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
                obj.NumOverruns = obj.NumOverruns + 1;

                switch obj.InternalOverrunAction
                  case robotics.core.internal.OverrunActions.Drop
                    obj.NextExecutionIndex = ceil((currentTime-obj.ExecutionStartTime)/obj.DesiredPeriod);
                    sleepTime = obj.NextExecutionIndex*obj.DesiredPeriod + obj.ExecutionStartTime - currentTime;
                  case robotics.core.internal.OverrunActions.Slip
                    obj.NextExecutionIndex = 0;
                    obj.ExecutionStartTime = currentTime;
                    sleepTime = 0;
                  otherwise
                    assert(false, ['OverrunAction ' char(obj.InternalOverrunAction) ' is not valid.']);
                end
            end

            % Sleep for the desired amount of time.
            obj.TimeProvider.sleep(sleepTime);

            % Detect time retrogression during sleep and adjust the
            % recorded past periods.
            currentTime = obj.TimeProvider.getElapsedTime;
            if  currentTime > obj.LastWakeTime
                obj.PastPeriods(obj.getIndexOfOldestPeriod)...
                    = currentTime - obj.LastWakeTime;
                % Save the end time of the sleep
                obj.PeriodCount = obj.PeriodCount + 1;
                obj.LastWakeTime = currentTime;
            else
                obj.recoverFromClockReset(currentTime);
            end
        end

        function reset(obj)
        %RESET Reset the rateControl object
        %   RESET(OBJ) resets the state of the rateControl object,
        %   including the elapsed time and all statistics about
        %   previous periods.
        %   RESET is useful if you want to run multiple successive loops
        %   at the same rate or if the object is created before the
        %   loop is executed.
        %
        %   Example:
        %       % Create a rate object running at 20 Hz
        %       r = rateControl(20);
        %
        %       % Run some other user code here
        %
        %       % Reset the rate object to start the execution loop
        %       RESET(r);
        %       for i = 1:10
        %          % User Code goes here
        %          waitfor(r)
        %       end

            obj.PastPeriods = zeros(1,obj.MemoryLength);
            obj.NumOverruns = 0;
            obj.PeriodCount = 0;
            obj.NextExecutionIndex = 0;
            obj.ExecutionStartTime = 0;
            obj.LastWakeTime = NaN;
            obj.startTimeProvider;
        end

        function stats = statistics(obj)
        %STATISTICS Returns the statistics of past execution periods
        %   STATS = STATISTICS(OBJ) returns statistics of previous
        %   periods in the execution.
        %
        %   STATS is returned as a struct with the following fields:
        %     Periods           - All time periods used to calculate statistics
        %                         as an indexed array.
        %                         Periods(end) is the most recent period
        %                         and Periods(1) is the oldest
        %     NumPeriods        - Number of elements in Periods
        %     AveragePeriod     - Average time in seconds between executions
        %     StandardDeviation - Standard deviation of all Periods, centered
        %                         around the mean stored in
        %                         AveragePeriod (in seconds)
        %     NumOverruns       - Number of execution periods that had an overrun
        %
        %   The statistics are calculated for the past 1,000 execution
        %   periods. If less than 1,000 periods are available, all periods
        %   are used for the calculation.

        % Initialize return structure
            stats = struct('Periods', [], 'NumPeriods', 0, ...
                           'AveragePeriod', NaN, 'StandardDeviation', NaN, ...
                           'NumOverruns', 0);

            pastPeriods = obj.getPastPeriodsInOrder;
            if isempty(pastPeriods)
                % Nothing to calculate, so return right away
                return;
            end

            stats.Periods = pastPeriods;
            stats.NumPeriods = length(pastPeriods);
            stats.AveragePeriod = mean(pastPeriods,2);
            stats.StandardDeviation = std(pastPeriods,0,2);
            stats.NumOverruns = obj.NumOverruns;
        end
    end

    methods
        function elapsedTime = get.TotalElapsedTime(obj)
        %get.TotalElapsedTime getter for TotalElapsedTime
            elapsedTime = obj.TimeProvider.getElapsedTime;
        end

        function lastPeriod = get.LastPeriod(obj)
        %get.LastPeriod getter for LastPeriod
            if obj.PeriodCount == 0
                lastPeriod = NaN;
            else
                coder.internal.errorIf(obj.PeriodCount == 0, 'shared_robotics:robotcore:rate:EmptyBuffer');
                pastPeriods = obj.getPastPeriodsInOrder;
                lastPeriod = pastPeriods(end);
            end
        end

        function set.OverrunAction(obj, overrunAction)
        %set.OverrunAction setter for OverrunAction
            validMethod = validatestring(overrunAction, obj.ValidOverrunActions, ...
                                         'rateControl', 'OverrunAction');

            % Mark the overrun method string as variable-sized during code
            % generation (with an upper limit of 20 characters).
            coder.varsize('validMethod', [1 20], [0 1]);
            switch validMethod
              case 'drop'
                obj.InternalOverrunAction = robotics.core.internal.OverrunActions.Drop;
              case 'slip'
                obj.InternalOverrunAction = robotics.core.internal.OverrunActions.Slip;
              otherwise
                assert(false, ['Action ' validMethod ' is not supported.']);
            end

            if ~obj.TimeProvider.IsInitialized
                return
            end

            % If overrun method is changed after object has been initialized,
            % reset the ExecutionStartTime properly.
            switch obj.InternalOverrunAction
              case robotics.core.internal.OverrunActions.Slip
                % If the new overrun method is 'slip', the execution sequence
                % is computed from current time instance.
                obj.NextExecutionIndex = 0;
                obj.ExecutionStartTime = obj.TimeProvider.getElapsedTime;

              case robotics.core.internal.OverrunActions.Drop
                % If the new overrun method is 'drop', the execution sequence
                % is computed from the last rateControl reset.
                obj.NextExecutionIndex = 0;
                obj.ExecutionStartTime = 0;

              otherwise
                assert(false, ['InternalOverrunAction ' char(obj.InternalOverrunAction) ' is not valid.'])
            end
        end

        function overrunAction = get.OverrunAction(obj)
            %get.OverrunAction getter for OverrunAction
            
            switch obj.InternalOverrunAction
                case robotics.core.internal.OverrunActions.Drop
                    overrunAction = 'drop';
                case robotics.core.internal.OverrunActions.Slip
                    overrunAction = 'slip';
                otherwise
                    overrunAction = 'drop';
                    assert(false, ['InternalOverrunAction ' char(obj.InternalOverrunAction) ' is not valid.'])
            end
        end
    end


    methods (Static, Access = protected)
        function obj = loadobj(s)
        %LOADOBJ Custom implementation for loading the rateControl object from a MAT file
        %   Reconstruct the rateControl object based on the saved data structure.

            obj = rateControl(s.DesiredRate);
            obj.InternalOverrunAction = s.InternalOverrunAction;
            obj.PastPeriods = s.PastPeriods;
            obj.PeriodCount = s.PeriodCount;
            obj.NumOverruns = s.NumOverruns;
        end
    end

    methods (Access = {?rateControl, ?matlab.unittest.TestCase})
        function startTimeProvider(obj)
        %startTimeProvider Connect to the time source

            obj.TimeProvider.reset();
            coder.internal.errorIf(~obj.TimeProvider.IsInitialized, 'shared_robotics:robotcore:rate:TimeSourceNotConnected');

            obj.LastWakeTime = 0;
        end

        function periods = getPastPeriodsInOrder(obj)
        %getPastPeriodsInOrder Returns unwrapped list of periods based on the circular buffer PastPeriods
        %   Since the circular buffer PastPeriods stores the past
        %   periods in a wrapped form, this function unwraps the
        %   periods and returns them in an unwrapped list.
        %   It unwraps the circular buffer so that periods(end) is the
        %   most recent, and periods(1) is the oldest.

            if obj.PeriodCount == 0
                periods = [];
                return;
            end

            if obj.PeriodCount <= obj.MemoryLength
                % No wrapping occurred yet
                periods = obj.PastPeriods(1:obj.PeriodCount);
            else
                % Unwrap the wrapped circular buffer
                startIndex = obj.getIndexOfOldestPeriod;
                periods = [obj.PastPeriods(startIndex:end), obj.PastPeriods(1:startIndex-1)];
            end
        end

        function recoverFromClockReset(obj, currentTime)
        %recoverFromClockReset Reset time-related properties and update statistics properties.
            obj.PastPeriods(obj.getIndexOfOldestPeriod) = obj.DesiredPeriod;
            obj.NextExecutionIndex = 0;
            obj.ExecutionStartTime = 0;
            obj.startTimeProvider;
            obj.LastWakeTime = currentTime;
            obj.PeriodCount = obj.PeriodCount + 1;
        end

        function idx = getIndexOfOldestPeriod(obj)
        %getIndexOfOldestPeriod Get the index of the oldest period in the circular buffer Past Periods
        %   Note that this function is only useful if the buffer
        %   contains at least MemoryLength elements.
            idx = mod(obj.PeriodCount, obj.MemoryLength) + 1;
        end
    end
end
