classdef (Hidden) TaskRunReason
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % TaskRunReason - Reason build runner runs a task
    %
    %   The matlab.buildtool.plugins.plugindata.TaskRunReason enumeration class
    %   provides a means to specify the reason the build runner runs a task.

    %   Copyright 2024 The MathWorks, Inc.

    enumeration
        % IncrementalNotSupported - Task does not support incremental build
        IncrementalNotSupported

        % IncrementalDisabled - Task has incremental build disabled
        IncrementalDisabled

        % NoInputsOrOutputs - Task has no inputs or outputs defined
        NoInputsOrOutputs

        % NoTrace - Task has no previous trace
        NoTrace

        % Changed - Task changed
        Changed
    end
end