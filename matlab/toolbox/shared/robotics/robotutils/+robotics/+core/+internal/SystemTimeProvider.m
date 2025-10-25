classdef SystemTimeProvider < robotics.core.internal.TimeProvider
%SystemTimeProvider A time object synchronized with system time.
%   Note that during MATLAB execution, the object utilizes PAUSE, TIC,
%   and TOC. All three functions use a monotonic clock to measure elapsed
%   time, so discontinuous changes of the system time
%   (for example during Daylight Savings Time, manual system clock
%   adjustments, or automatic NTP adjustments) have no effects.
%
%   The same monotonic behavior holds true for the corresponding
%   functions in code generation.
%
%   SystemTimeProvider properties:
%       IsInitialized - Indication if the time provider has been initialized
%
%   SystemTimeProvider methods:
%       reset           - Reset the time provider
%       sleep           - Sleep for a number of seconds
%       getElapsedTime  - Returns the elapsed time since the time provider was reset (seconds)
%
%   See also robotics.core.internal.TimeProvider.

%   Copyright 2015-2020 The MathWorks, Inc.

%#codegen

    properties (Dependent, SetAccess = protected)
        %IsInitialized - Indication if the time provider has been initialized
        %   Use the RESET method to initialize the time provider.
        IsInitialized
    end

    properties (Access = {?robotics.core.internal.SystemTimeProvider, ?matlab.unittest.TestCase})
        %StartTime - The time when the clock starts.
        %   A value of -1 implies that the time provider has not been
        %   initialized. Call RESET to initialize the provider.
        %
        %   Default: -1
        StartTime
    end

    methods
        function obj = SystemTimeProvider
        %SystemTimeProvider Constructor for SystemTimeProvider object
        %   Please see the class documentation for more details.
        %   See also robotics.core.internal.SystemTimeProvider.
        
        % Note: the data type returned from tic is different between MATLAB 
        % and the generated code.
            if coder.target('MATLAB')
                obj.StartTime = -1;
            else
                obj.StartTime = struct('tv_sec', 0, 'tv_nsec', 0);
            end
        end

        function elapsedTime = getElapsedTime(obj)
        %getElapsedTime Returns the elapsed time since the time provider was reset (seconds)
        %   You need to call RESET to initialize the time provider before
        %   you can call this method.
        %   The returned time is monotonically increasing and is not affected
        %   by discontinuous jumps in the system time, for example on manual time
        %   changes or during Daylight Savings Time.

            coder.internal.errorIf(~obj.isStartTimeValid,'shared_robotics:robotutils:timeprovider:TimeProviderNotInitialized');

            elapsedTime = toc(obj.StartTime);
            
        end

        function initialized = get.IsInitialized(obj)
        %get.IsInitialized getter for IsInitialized property.
        %   Indicates whether the timer is initialized or not.
            initialized = obj.isStartTimeValid;
        end

        function success = reset(obj)
        %RESET Reset the time provider
        %   This resets the initial state of the time provider. You have to
        %   call RESET before you can call any other methods on the object.
        %   This function returns whether the time provider has been
        %   successfully reset.
            
            obj.StartTime = tic;
            success = obj.isStartTimeValid;
        end

        function sleep(obj, seconds)
        %SLEEP Sleep for a number of seconds
        %   This sleep uses the computer's system time. The SECONDS input
        %   specified the sleep time in seconds. A negative number for
        %   SECONDS has no effect and the function will return right
        %   away.
        %   You need to call RESET to initialize the time provider before
        %   you can call this method.
        %
        %   Caveats for pause in codegen:
        %   1) The use of pause in parfor loops is not supported for MEX 
        %      code generation.
        %   2) The generated code truncates pause delay values to uint32
        %      range during run-time execution (using POSIX nanosleep API)

            coder.internal.errorIf(~obj.isStartTimeValid,'shared_robotics:robotutils:timeprovider:TimeProviderNotInitialized');

            % It is reasonably accurate.
            pause(seconds);

        end
    end

    methods (Access = private)
        function valid = isStartTimeValid(obj)
        %isStartTimeValid Check if StartTime property contains a valid value
            if coder.target('MATLAB')
                valid = obj.StartTime ~= -1;
            else
                valid = obj.StartTime.tv_sec > 0;
            end
        end
    end

end
