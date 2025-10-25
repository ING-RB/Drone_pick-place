classdef(Hidden) FailureDiagnosticsPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
                                    matlab.unittest.internal.plugins.HasOutputStreamMixin & ...
                                    matlab.unittest.plugins.Parallelizable
    % FailureDiagnosticsPlugin - Plugin to show diagnostics on failure.
    %
    %   FailureDiagnosticsPlugin is not recommended. Use DiagnosticsOutputPlugin
    %   instead.
    %
    %   The FailureDiagnosticsPlugin can be added to the TestRunner
    %   to show diagnostics upon failure.
    %
    %   FailureDiagnosticsPlugin methods:
    %       FailureDiagnosticsPlugin - Class constructor
    %
    %   Example:
    %
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.FailureDiagnosticsPlugin;
    %
    %       % Create a TestSuite array
    %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       % Create a TestRunner with no plugins
    %       runner = TestRunner.withNoPlugins;
    %
    %       % Add a new plugin to the TestRunner
    %       runner.addPlugin(FailureDiagnosticsPlugin);
    %
    %       % Run the suite to see diagnostic output on failure
    %       result = runner.run(suite)
    %
    %   See also:
    %       matlab.unittest.plugins.DiagnosticsOutputPlugin
    %       matlab.unittest.plugins.TestRunnerPlugin
    %       matlab.unittest.diagnostics
    
    % Copyright 2012-2023 The MathWorks, Inc.
    
    properties(Constant, Access=private)
        Catalog = matlab.internal.Catalog('MATLAB:unittest:DiagnosticsOutputPlugin');
    end
    
    properties(Dependent, GetAccess=private, SetAccess=immutable)
        Printer
    end
    
    properties(Transient, Access=private)
        InternalPrinter = [];
    end
    
    methods (Hidden, Sealed)
        function tf = supportsParallelThreadPool_(plugin)
            tf = plugin.OutputStream.supportsParallelThreadPool_;
        end
    end
    
    methods
        function printer = get.Printer(plugin)
            import matlab.unittest.internal.plugins.EventReportPrinter;
            import matlab.unittest.Verbosity;
            if isempty(plugin.InternalPrinter)
                plugin.InternalPrinter = EventReportPrinter.withVerbosity( ...
                    Verbosity.Detailed, plugin.OutputStream);
            end
            printer = plugin.InternalPrinter;
        end
        
        function plugin = FailureDiagnosticsPlugin(varargin)
            %FailureDiagnosticsPlugin - Class constructor
            %
            %   FailureDiagnosticsPlugin is not recommended. Use DiagnosticsOutputPlugin
            %   instead.
            %
            %   PLUGIN = FailureDiagnosticsPlugin creates a FailureDiagnosticsPlugin
            %   instance and returns it in PLUGIN. This plugin can then be added to a
            %   TestRunner instance to show diagnostics when test failure conditions
            %   are encountered.
            %
            %   PLUGIN = FailureDiagnosticsPlugin(STREAM) creates a
            %   FailureDiagnosticsPlugin and redirects all the text output produced to
            %   the OutputStream STREAM. If this is not supplied, a ToStandardOutput
            %   stream is used.
            %
            %   Example:
            %
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.plugins.FailureDiagnosticsPlugin;
            %
            %       % Create a TestSuite array
            %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       % Create a TestRunner with no plugins
            %       runner = TestRunner.withNoPlugins;
            %
            %       % Create an instance of FailureDiagnosticsPlugin
            %       plugin = FailureDiagnosticsPlugin;
            %
            %       % Add the plugin to the TestRunner
            %       runner.addPlugin(plugin);
            %
            %       % Run the suite and see diagnostics on failure
            %       result = runner.run(suite)
            %
            %   See also:
            %       matlab.unittest.plugins.DiagnosticsOutputPlugin
            %       matlab.unittest.plugins.OutputStream
            %       matlab.unittest.plugins.ToStandardOutput
            %
            plugin = plugin@matlab.unittest.internal.plugins.HasOutputStreamMixin(varargin{:});
        end
    end

    
    methods (Access=protected)
        function runTestSuite(plugin, pluginData)
            import matlab.unittest.internal.plugins.getFailureSummaryTableText;
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            
            txt = getFailureSummaryTableText(pluginData.TestResult);
            if strlength(txt) > 0
                plugin.Printer.printLine(txt);
            end
        end
        
        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventScope = matlab.unittest.Scope.SharedTestFixture;
            eventLocation = pluginData.Name;
            fixture.addlistener('AssertionFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            fixture.addlistener('FatalAssertionFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            fixture.addlistener('AssumptionFailed', @(~,eventData) plugin.processAssumptionFailedEvent(eventData,eventScope,eventLocation));
            fixture.addlistener('ExceptionThrown', @(~, eventData)plugin.processExceptionThrownEvent(eventData,eventScope,eventLocation));
        end
        
        function testCase = createTestClassInstance(plugin, pluginData)
            testCase = createTestClassInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventScope = matlab.unittest.Scope.TestClass;
            eventLocation = pluginData.Name;
            testCase.addlistener('VerificationFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('AssertionFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('FatalAssertionFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('AssumptionFailed', @(~,eventData) plugin.processAssumptionFailedEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('ExceptionThrown', @(~, eventData)plugin.processExceptionThrownEvent(eventData,eventScope,eventLocation));
        end
        
        function testCase = createTestRepeatLoopInstance(plugin, pluginData)
            testCase = createTestRepeatLoopInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventScope = matlab.unittest.Scope.TestMethod;
            eventLocation = pluginData.Name;
            testCase.addlistener('VerificationFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('AssertionFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('FatalAssertionFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('AssumptionFailed', @(~,eventData) plugin.processAssumptionFailedEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('ExceptionThrown', @(~, eventData)plugin.processExceptionThrownEvent(eventData,eventScope,eventLocation));
        end
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = createTestMethodInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventScope = matlab.unittest.Scope.TestMethod;
            eventLocation = pluginData.Name;
            testCase.addlistener('VerificationFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('AssertionFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('FatalAssertionFailed', @(~,eventData) plugin.processQualificationEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('AssumptionFailed', @(~,eventData) plugin.processAssumptionFailedEvent(eventData,eventScope,eventLocation));
            testCase.addlistener('ExceptionThrown', @(~, eventData)plugin.processExceptionThrownEvent(eventData,eventScope,eventLocation));
        end
    end
    
    methods(Access=private)
        function processQualificationEvent(plugin,eventData,eventScope,eventLocation)
            import matlab.unittest.internal.eventrecords.QualificationEventRecord;
            eventRecord = QualificationEventRecord.fromEventData(eventData,eventScope,eventLocation);
            plugin.Printer.printEmptyLine();
            plugin.Printer.printEventReportDeliminator();
            plugin.Printer.printQualificationEventReport(eventRecord);
            plugin.Printer.printEventReportDeliminator();
        end
        
        function processExceptionThrownEvent(plugin,eventData,eventScope,eventLocation)
            import matlab.unittest.internal.eventrecords.ExceptionEventRecord;
            eventRecord = ExceptionEventRecord.fromEventData(eventData,eventScope,eventLocation);
            plugin.Printer.printEmptyLine();
            plugin.Printer.printEventReportDeliminator();
            plugin.Printer.printExceptionEventReport(eventRecord);
            plugin.Printer.printEventReportDeliminator();
        end
        
        function processAssumptionFailedEvent(plugin,eventData,eventScope,eventLocation)
            import matlab.unittest.internal.eventrecords.QualificationEventRecord;
            eventRecord = QualificationEventRecord.fromEventData(eventData,eventScope,eventLocation);
            plugin.Printer.printEmptyLine();
            plugin.Printer.printEventReportDeliminator();
            plugin.Printer.printAssumptionFailedEventMiniReport(eventRecord);
            plugin.Printer.printEventReportDeliminator();
        end
    end
end

% LocalWords:  unittest mynamespace Formattable Parallelizable strlength eventrecords
