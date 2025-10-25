function plugins = getFactoryDefaultPlugins(options)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023-2024 The MathWorks, Inc.

arguments
    options (1,1) struct = struct
end

plugins = [ ...
    createBuildRunProgressPlugin(options), ...
    createDiagnosticsOutputPlugin(options), ...
];
end

function plugin = createBuildRunProgressPlugin(options)
import matlab.automation.Verbosity;
import matlab.buildtool.plugins.BuildRunProgressPlugin;

if isfield(options, "Verbosity")
    verbosity = options.Verbosity;
else
    verbosity = Verbosity.Concise;
end

plugin = BuildRunProgressPlugin.withVerbosity(verbosity);
end

function plugin = createDiagnosticsOutputPlugin(options)
import matlab.buildtool.plugins.DiagnosticsOutputPlugin;

args = {};
if isfield(options, "Verbosity")
    args = [args {"OutputDetail", options.Verbosity, "LoggingLevel", options.Verbosity}];
end

plugin = DiagnosticsOutputPlugin(args{:});
end
