classdef TestResultPlugin < matlab.unittest.plugins.TestRunnerPlugin
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Results;
    end

    methods
        function plugin = TestResultPlugin(initialResults)
            arguments
                initialResults = matlab.unittest.TestResult.empty;
            end
            plugin.Results = initialResults;
        end
    end
    
    methods (Access = protected)
        function runTestSuite(plugin, pluginData)
            clean = onCleanup(@()plugin.storeResults(pluginData));
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end
    end
    methods (Access = private)
        function storeResults(plugin, pluginData)
            plugin.Results = pluginData.TestResult;
        end
    end
    
end
