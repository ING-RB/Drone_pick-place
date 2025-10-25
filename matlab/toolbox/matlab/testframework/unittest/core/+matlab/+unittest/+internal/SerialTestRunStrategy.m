classdef SerialTestRunStrategy < matlab.unittest.internal.TestRunStrategy
    %
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties 
        ArtifactsRootFolder = string(matlab.unittest.internal.folderResolver(tempdir));
    end
    
    methods
        function runSession(strategy,runner,~)
            import matlab.unittest.plugins.plugindata.TestSuiteRunPluginData;
            suite = runner.TestRunData.TestSuite;
            testSuiteRunPluginData = TestSuiteRunPluginData('', runner.TestRunData, numel(suite));
            
            strategy.runTestSuite(runner,testSuiteRunPluginData);
        end
        
        function set.ArtifactsRootFolder(strategy,folder)
            folder = strategy.resolveArtifactsRootFolder(folder);
            strategy.ArtifactsRootFolder = folder;
        end
    end
    
    methods (Access=protected)
        function runTestSuite(~, runner, pluginData)
            groupNumber = 1;
            numGroups = 1;
            suite = pluginData.TestSuite;
            
            % make sure "reportFinalizedSuite" is invoked in case of FatalAssertions 
            finishUp = matlab.unittest.internal.CancelableCleanup(@() runner.TestRunStrategy.reportFinalizedSuite(runner, ...
                pluginData.WorkerPluginDataMap, 1:numel(suite), groupNumber, numGroups, suite, runner.TestRunData.TestResult));

            runner.PluginData.runTestSuite = pluginData;
            runner.evaluateMethodOnPlugins("runTestSuite", pluginData); 
            
            finishUp.cancelAndInvoke;
        end    
    end
    
    methods(Static)
        function strategy = loadobj(savedStrategy)
            strategy = matlab.unittest.internal.SerialTestRunStrategy;
            
            try
                strategy.ArtifactsRootFolder = savedStrategy.ArtifactsRootFolder;
            catch exception
                warning("MATLAB:unittest:TestRunner:UnableToLoadArtifactsRootFolder",'%s',exception.message);
                strategy.ArtifactsRootFolder = matlab.unittest.internal.folderResolver(tempdir);
            end
        end
    end
end


% LocalWords:  plugindata Cancelable
