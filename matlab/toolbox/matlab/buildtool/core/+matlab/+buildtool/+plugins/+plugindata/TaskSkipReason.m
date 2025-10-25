classdef (Hidden) TaskSkipReason
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % TaskSkipReason - Reason build runner skips a task
    %
    %   The matlab.buildtool.plugins.plugindata.TaskSkipReason enumeration class
    %   provides a means to specify the reason the build runner skips a task.

    %   Copyright 2022-2024 The MathWorks, Inc.

    enumeration
        % UpToDate - Task is up to date
        UpToDate

        % DependencyFailed - Task dependency failed
        DependencyFailed

        % UserRequested - Task requested to be skipped
        UserRequested
    end
end
