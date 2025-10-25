classdef TerseProgressPlugin < matlab.unittest.plugins.TestRunProgressPlugin
    % TerseProgressPlugin - Plugin which outputs minimal test run progress.
    %
    %   The TerseProgressPlugin can be added to the TestRunner to show
    %   progress of the test run to the Command Window when running test
    %   suites.
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties (Hidden, Constant)
        RowLength = 50;
        GroupLength = 10;
    end
    
    properties (Access=private)
        MethodCount = 0;
    end
    
    methods (Hidden, Access=?matlab.unittest.plugins.TestRunProgressPlugin)
        function plugin = TerseProgressPlugin(varargin)
            plugin = plugin@matlab.unittest.plugins.TestRunProgressPlugin(varargin{:});
        end
    end
    
    methods (Hidden, Access=protected)
        function runTestSuite(plugin, pluginData)
            plugin.MethodCount = 0;
            
            runTestSuite@matlab.unittest.plugins.TestRunProgressPlugin(plugin, pluginData);
            
            plugin.Printer.printEmptyLine;
        end
        
        function setupTestMethod(plugin, pluginData)
            setupTestMethod@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            if plugin.needNewLine()
                plugin.Printer.printEmptyLine();
            elseif plugin.needSpace()
                plugin.Printer.print(' ');
            end
        end
        
        function teardownTestMethod(plugin, pluginData)
            teardownTestMethod@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.MethodCount = plugin.MethodCount + 1;
            plugin.Printer.print('.');
        end
    end
    
    methods(Access=private)
        function bool = needNewLine(plugin)
            bool = plugin.MethodCount > 0 && mod(plugin.MethodCount,plugin.RowLength) == 0;
        end
        
        function bool = needSpace(plugin)
            bool = plugin.MethodCount > 0 && mod(plugin.MethodCount,plugin.GroupLength) == 0;
        end
    end
end

