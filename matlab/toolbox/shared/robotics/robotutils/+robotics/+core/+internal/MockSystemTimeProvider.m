classdef MockSystemTimeProvider < robotics.core.internal.TimeProvider & coder.ExternalDependency
%MockSystemTimeProvider A placeholder for the system time object
%   This object is used in place of the SystemTimeProvider when a time
%   object must be provided, but the intent is to avoid calling
%   system-specific code (e.g., to enable cross-platform generated code
%   deployment). The methods and properties are placeholders for those
%   of the SystemTimeProvider with limited functionality.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    properties (Dependent, SetAccess = protected)
        %IsInitialized - Indication if the time provider has been initialized
        %   Use the RESET method to initialize the time provider.
        IsInitialized
    end

    properties (Access = {?robotics.core.internal.SystemTimeProvider, ?matlab.unittest.TestCase})
        %StartTime - Placeholder for the time when the clock starts.
        %   A value of -1 implies that the time provider has not been
        %   initialized. Call RESET to initialize the provider.
        %
        %   Default: -1
        StartTime
    end

    methods
        function obj = MockSystemTimeProvider
        %MockSystemTimeProvider Constructor for MockSystemTimeProvider object
        %   See also robotics.core.internal.SystemTimeProvider.
            obj.StartTime = -1;
        end

        function elapsedTime = getElapsedTime(obj)
        %getElapsedTime Placeholder method for the elapsed time.
        %   For the mock case, this will always return the StartTime.

            elapsedTime = obj.StartTime;
        end

        function initialized = get.IsInitialized(obj)
        %get.IsInitialized getter for IsInitialized property.
        %   Indicates whether the timer is initialized or not.
            initialized = obj.isStartTimeValid;
        end

        function success = reset(obj)
        %RESET Reset the time provider
        %   This resets the initial state of the time provider.

            obj.StartTime = 0;
            success = obj.isStartTimeValid;
        end

        function sleep(obj, ~)
        %SLEEP Placeholder method for the sleep function.
        %   For the mock case, this sets the StartTime to zero.

            obj.StartTime = 0;
        end
    end

    methods (Access = private)
        function valid = isStartTimeValid(obj)
        %isStartTimeValid Check if StartTime property contains a valid value
            valid = obj.StartTime ~= -1;
        end
    end

    %% The following functions implement the coder.ExternalDependency interface
    % These functions are used during code generation.
    methods (Static)
        function name = getDescriptiveName(~)
        %getDescriptiveName Returns a descriptive name for the build configuration

            name = 'MockSystemTimeProvider';
        end

        function canBuild = isSupportedContext(ctx)
        %isSupportedContext Verifies that build configuration is supported

            coder.internal.errorIf(~ctx.isMatlabHostTarget, ...
                                   'shared_robotics:robotutils:timeprovider:InvalidCodegenTarget');

            % This is host-only code generation, so allow build.
            canBuild = true;
        end

        function updateBuildInfo(~, ~)
        %updateBuildInfo Update the include and source folder path build configuration
        end
    end

end
