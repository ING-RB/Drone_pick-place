classdef(Hidden) CodeCoverageCollectionPlugin < matlab.unittest.plugins.TestRunnerPlugin & ... 
                                                matlab.unittest.plugins.Parallelizable
    % This class is undocumented and may change in a future release.
    
    % CodeCoverageCollectionPlugin - A plugin for collecting code coverage.
    
    % Copyright 2013-2020 The MathWorks, Inc.
    
    properties (Hidden, SetAccess=private, GetAccess=protected)
        Collector
        CollectorResults
    end
    
    methods (Access=protected)
        function plugin = CodeCoverageCollectionPlugin(collector)
            plugin.Collector = collector;
        end
        
        function runTestSuite(plugin, pluginData)
            plugin.Collector.initialize();
            plugin.Collector.clearResults;
            clean = onCleanup(@()assignResultsAndResetProfilerCollector(plugin,pluginData.CommunicationBuffer));
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            function assignResultsAndResetProfilerCollector(plugin,comBuffer)                
                plugin.storeIn(comBuffer,plugin.Collector.Results);
                plugin.Collector.reset();
            end
        end
        
        function evaluateMethod(plugin, pluginData)
            plugin.Collector.start;
            stopCollector = onCleanup(@()plugin.Collector.stop);
            evaluateMethod@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end
    end
    
    methods
        function set.Collector(plugin, collector)
            validateattributes(collector, {'matlab.unittest.internal.plugins.CodeCoverageCollectorInterface'}, ...
                {'scalar'}, '', 'Collector');
            plugin.Collector = collector;
        end
    end
end
