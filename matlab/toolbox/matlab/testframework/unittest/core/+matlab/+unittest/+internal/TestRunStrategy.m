classdef TestRunStrategy < handle
    % This class is undocumented and subject to change in a future release

    % Copyright 2018-2020 The MathWorks, Inc.

    properties(Abstract)
        ArtifactsRootFolder (1,1) string
    end

    methods (Abstract)
        runSession(strategy, runner, pluginData);
    end

    methods(Sealed)
        function reportFinalizedSuite(~, runner, pluginDataMap,suiteIndices, groupNumber, numGroups, suite, testResults)
            import matlab.unittest.plugins.plugindata.FinalizedSuitePluginData;

            pluginData = FinalizedSuitePluginData('',pluginDataMap, suiteIndices, groupNumber, numGroups, suite, testResults);
            runner.PluginData.reportFinalizedSuite = pluginData;
            runner.evaluateMethodOnPlugins("reportFinalizedSuite", pluginData);
            delete(runner.PluginData.reportFinalizedSuite);
        end
    end

    methods
        function setupTestRunEnvironment(~,~)
        end

        function validatePluginsSupported(~, plugins)
            for idx = 1:numel(plugins)
                if ~plugins(idx).supportsParallel_
                    throwAsCaller(MException(message("MATLAB:unittest:TestRunner:PluginDoesNotSupportParallel", class(plugins(idx)))));
                end
            end
        end

        function diag = getUnsupportedPluginDiagnostic(~, plugins)
            diag = "";
            unsupportedPlugins = plugins(~arrayfun(@supportsParallel_, plugins));
            if ~isempty(unsupportedPlugins)
                names = arrayfun(@class, unsupportedPlugins, "UniformOutput",false);
                diag = string(getString(message("MATLAB:unittest:runtests:IncompatibleWithParallel", strjoin(names, newline))));
            end
        end

        function validateSuiteSupported(~, ~)
        end

        function diag = getUnsupportedSuiteDiagnostic(~, ~)
            diag = "";
        end

        function diagData = getDiagnosticData(strategy, runIdentifier)
            import matlab.unittest.diagnostics.DiagnosticData;

            diagData = DiagnosticData('ArtifactsStorageFolder',...
                fullfile(strategy.ArtifactsRootFolder, runIdentifier));
        end

        function cleanupObj = createArtifactsStorageFolder(strategy, runIdentifier)
            import matlab.unittest.internal.createConditionallyKeptFolderEnvironment;

            cleanupObj = createConditionallyKeptFolderEnvironment( ...
                fullfile(strategy.ArtifactsRootFolder, runIdentifier));
        end
    end
    methods(Access=protected)
        function folder = resolveArtifactsRootFolder(~, folder)
            import matlab.unittest.internal.folderResolver
            folder = string(folderResolver(folder));
            validateArtifactsRootFolderHasWritePermissions(folder)
        end
    end

end
function validateArtifactsRootFolderHasWritePermissions(folder)
import matlab.lang.internal.uuid;
tmpFolder = fullfile(folder, uuid);
try
    mkdir(tmpFolder);
    rmdir(tmpFolder);
catch cause
    exception = MException(message('MATLAB:unittest:TestRunner:MustBeAWritableFolder','ArtifactsRootFolder'));
    throwAsCaller(exception.addCause(cause));
end
end

% LocalWords:  AWritable
