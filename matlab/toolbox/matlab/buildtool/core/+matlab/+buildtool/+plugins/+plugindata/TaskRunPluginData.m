classdef (Hidden) TaskRunPluginData < matlab.buildtool.plugins.plugindata.RunPluginData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        RunReason (1,1) matlab.buildtool.plugins.plugindata.TaskRunReason
        ChangeDiagnostics (1,:) matlab.buildtool.diagnostics.TaskChangeDiagnostic
    end

    methods (Access = {?matlab.buildtool.BuildRunner, ?matlab.buildtool.plugins.plugindata.TaskRunPluginData})
        function data = TaskRunPluginData(name, runData, indices, reason, diagnostics)
            arguments
                name (1,1) string
                runData (1,1) matlab.buildtool.internal.BuildRunData
                indices (1,:) {mustBeNumeric}
                reason (1,1) matlab.buildtool.plugins.plugindata.TaskRunReason
                diagnostics (1,:) matlab.buildtool.diagnostics.TaskChangeDiagnostic = matlab.buildtool.diagnostics.TaskChangeDiagnostic.empty(1,0)
            end

            data@matlab.buildtool.plugins.plugindata.RunPluginData(name, runData, indices);

            data.RunReason = reason;
            data.ChangeDiagnostics = diagnostics;
        end
    end
end