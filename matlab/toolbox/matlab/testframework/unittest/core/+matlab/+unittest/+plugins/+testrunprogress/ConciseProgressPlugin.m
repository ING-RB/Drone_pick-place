classdef ConciseProgressPlugin < matlab.unittest.plugins.TestRunProgressPlugin
    % ConciseProgressPlugin - Plugin which outputs test run progress.
    %
    %   The ConciseProgressPlugin can be added to the TestRunner to show
    %   progress of the test run to the Command Window when running test
    %   suites.
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Hidden, Constant)
        RowLength = 50;
        GroupLength = 10;
    end
    
    properties(Access=private)
        MethodCount = 0;
    end
    
    methods (Hidden, Access=?matlab.unittest.plugins.TestRunProgressPlugin)
        function plugin = ConciseProgressPlugin(varargin)
            plugin = plugin@matlab.unittest.plugins.TestRunProgressPlugin(varargin{:});
        end
    end
    
    methods (Hidden, Access=protected)
        function setupSharedTestFixture(plugin, pluginData)
            import matlab.unittest.internal.diagnostics.createClassNameForCommandWindow;
            import matlab.unittest.internal.diagnostics.MessageString;
            
            displayedName = createClassNameForCommandWindow(pluginData.Name);
            plugin.Printer.printLine(MessageString('MATLAB:unittest:TestRunProgressPlugin:SettingUp', displayedName));
            
            setupSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            
            description = MessageString('MATLAB:unittest:TestRunProgressPlugin:DoneSettingUp', displayedName);
            if ~isempty(pluginData.Description)
                description = sprintf('%s: %s', description, pluginData.Description);
            end
            plugin.Printer.printLine(description);
            plugin.Printer.printLine(plugin.ContentDelimiter);
            plugin.Printer.printLine('');
        end
        
        function teardownSharedTestFixture(plugin, pluginData)
            import matlab.unittest.internal.diagnostics.createClassNameForCommandWindow;
            import matlab.unittest.internal.diagnostics.MessageString;
            
            displayedName = createClassNameForCommandWindow(pluginData.Name);
            plugin.Printer.printLine(MessageString('MATLAB:unittest:TestRunProgressPlugin:TearingDown', displayedName));
            
            teardownSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            
            description = MessageString('MATLAB:unittest:TestRunProgressPlugin:DoneTearingDown', displayedName);
            if ~isempty(pluginData.Description)
                description = sprintf('%s: %s', description, pluginData.Description);
            end
            plugin.Printer.printLine(description);
            plugin.Printer.printLine(plugin.ContentDelimiter);
            plugin.Printer.printLine('');
        end
        
        function runTestClass(plugin, pluginData)
            % Reset the method count prior to running each test class.
            plugin.MethodCount = 0;
            
            plugin.Printer.printLine(plugin.Catalog.getString('Running', pluginData.Name));
            
            runTestClass@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            
            plugin.Printer.printLine('');
            plugin.Printer.printLine(plugin.Catalog.getString('Done', pluginData.Name));
            plugin.Printer.printLine(plugin.ContentDelimiter);
            plugin.Printer.printLine('');
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

