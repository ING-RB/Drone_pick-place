function plugins = getFactoryDefaultPlugins(pluginProviderData)
% This function is undocumented.

% Copyright 2014-2023 The MathWorks, Inc.

import matlab.unittest.internal.plugins.PluginProviderData;
import matlab.unittest.internal.services.plugins.locateDefaultPlugins;

if nargin < 1
    pluginProviderData = PluginProviderData;
end
options = pluginProviderData.Options;

plugins = [ ...
    createStopOnFailuresPluginIfNeeded(options),...
    createFailOnWarningsPluginIfNeeded(options),...
    createTestRunProgressPlugin(options), ...
    createDiagnosticsOutputPlugin(options), ...
    createDiagnosticsRecordingPlugin(options), ...
    locateDefaultPlugins( ...
        ?matlab.unittest.internal.services.plugins.TestRunnerPluginService,...
        'matlab.unittest.internal.services.plugins', ...
        pluginProviderData)];
end


function plugin = createStopOnFailuresPluginIfNeeded(options)
if isfield(options,'Debug') && options.Debug
    plugin = matlab.unittest.plugins.StopOnFailuresPlugin();
else
    plugin = matlab.unittest.plugins.TestRunnerPlugin.empty(1,0);
end
end


function plugin = createFailOnWarningsPluginIfNeeded(options)
if isfield(options,'Strict') && options.Strict
    plugin = matlab.unittest.plugins.FailOnWarningsPlugin();
else
    plugin = matlab.unittest.plugins.TestRunnerPlugin.empty(1,0);
end
end


function plugin = createTestRunProgressPlugin(options)
import matlab.unittest.Verbosity;
import matlab.unittest.plugins.TestRunProgressPlugin;
if isfield(options,'OutputDetail')
    progressVerbosity = options.OutputDetail;
elseif isfield(options,'Verbosity') % for backward compatibility
    progressVerbosity = options.Verbosity;
else
    progressVerbosity = Verbosity.Concise;
end
plugin = TestRunProgressPlugin.withVerbosity(progressVerbosity);
end


function plugin = createDiagnosticsOutputPlugin(options)
import matlab.unittest.plugins.DiagnosticsOutputPlugin;

if isfield(options, 'TestViewHandler_') && ...
        ~options.TestViewHandler_.UseDiagnosticOutputPlugin
    plugin = matlab.unittest.plugins.TestRunnerPlugin.empty(1,0);
    return;
end

args = {};
if isfield(options,'LoggingLevel')
    args = [args,{'LoggingLevel',options.LoggingLevel}];
end
if isfield(options,'OutputDetail')
    args = [args,{'OutputDetail',options.OutputDetail}];
end
plugin = DiagnosticsOutputPlugin(args{:});

end


function plugin = createDiagnosticsRecordingPlugin(options)
import matlab.unittest.plugins.DiagnosticsRecordingPlugin;
args = {};
if isfield(options,'LoggingLevel')
    args = [args,{'LoggingLevel',options.LoggingLevel}];
end
if isfield(options,'OutputDetail')
    args = [args,{'OutputDetail',options.OutputDetail}];
end
if isfield(options,'Verbosity') % for backward-compatibility
    args = [args,{'Verbosity',options.Verbosity}];
end
plugin = DiagnosticsRecordingPlugin(args{:});
end

% LocalWords:  plugins unittest
