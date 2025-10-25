classdef DiagnosticsOutputPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
                                   matlab.unittest.internal.plugins.HasOutputStreamMixin & ...
                                   matlab.unittest.plugins.Parallelizable
    % DiagnosticsOutputPlugin - Plugin to show diagnostics to an output stream
    %
    %   The DiagnosticsOutputPlugin enables configuration of a TestRunner to
    %   show diagnostics to an output stream. The plugin can be configured to
    %   specify the output stream, which events are included, and the level of
    %   detail for displaying them.  By default, DiagnosticsOutputPlugin uses
    %   the ToStandardOutput stream, excludes diagnostics from passing events,
    %   and only includes logged diagnostics at level Verbosity.Terse.
    %
    %   DiagnosticsOutputPlugin properties:
    %       ExcludeFailureDiagnostics - Indicator if diagnostics are excluded for failing events
    %       IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
    %       LoggingLevel              - Maximum verbosity level at which logged diagnostics are included
    %       OutputDetail              - Verbosity level that defines amount of displayed information
    %
    %   DiagnosticsOutputPlugin methods:
    %       DiagnosticsOutputPlugin - Class constructor
    %
    %   See also:
    %       matlab.unittest.TestRunner
    %       matlab.unittest.plugins.OutputStream
    %       matlab.unittest.plugins.ToStandardOutput
    %       matlab.unittest.Verbosity

    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties(SetAccess=immutable)
        % ExcludeFailureDiagnostics - Indicator if diagnostics are excluded for failing events
        %
        %   The ExcludeLoggedDiagnostics property is a scalar logical (true or
        %   false) that indicates if diagnostics from failing events are excluded
        %   from the output. This property is read-only and is set through the
        %   constructor.
        ExcludeFailureDiagnostics (1,1) logical = false;
        
        % IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
        %
        %   The IncludePassingDiagnostics property is a scalar logical (true or
        %   false) that indicates if diagnostics from passing events are included
        %   in the output. This property is read-only and is set through the
        %   constructor.
        IncludePassingDiagnostics (1,1) logical = false;
    end
    
    properties(SetAccess=private)
        % LoggingLevel - Maximum verbosity level at which logged diagnostics are included
        %
        %   The LoggingLevel property is a scalar matlab.unittest.Verbosity
        %   instance. The plugin includes logged diagnostics in the output that are
        %   logged at or below the specified level. This property is read-only and
        %   is set through the constructor.
        LoggingLevel (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Terse;
        
        % OutputDetail - Verbosity level that defines amount of displayed information
        %
        %   The OutputDetail property is a scalar matlab.unittest.Verbosity
        %   instance that defines the amount of detail displayed in the output for
        %   passing, failing, and logged events. This property is read-only and is
        %   set through the constructor.
        OutputDetail (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Detailed;
    end
    
    properties(Hidden, Access=protected)
        LinePrinter;
        EventRecordFormatter;
        EventRecordProcessor;
    end
    
    methods (Hidden, Sealed)
        function tf = supportsParallelThreadPool_(plugin)
            tf = plugin.OutputStream.supportsParallelThreadPool_;
        end
    end
    
    methods
        function plugin = DiagnosticsOutputPlugin(stream, namedargs)
            %DiagnosticsOutputPlugin - Class constructor
            %
            %   PLUGIN = DiagnosticsOutputPlugin creates a DiagnosticsOutputPlugin
            %   instance and returns it in PLUGIN. This plugin can be added to a
            %   TestRunner instance to show failure diagnostics and logged diagnostics
            %   that are logged at level Verbosity.Terse.
            %
            %   PLUGIN = DiagnosticsOutputPlugin(STREAM) creates a
            %   DiagnosticsOutputPlugin and redirects the text produced to the
            %   OutputStream STREAM. If STREAM is not supplied, a ToStandardOutput
            %   stream is used.
            %
            %   PLUGIN = DiagnosticsOutputPlugin(...,'ExcludingFailureDiagnostics',true)
            %   creates a DiagnosticsOutputPlugin that excludes diagnostics from
            %   failing events.
            %
            %   PLUGIN = DiagnosticsOutputPlugin(...,'IncludingPassingDiagnostics',true)
            %   creates a DiagnosticsOutputPlugin that includes diagnostics from
            %   passing events.
            %
            %   PLUGIN = DiagnosticsOutputPlugin(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a DiagnosticsOutputPlugin that includes logged diagnostics that
            %   are logged at or below LOGGINGLEVEL. LOGGINGLEVEL is specified as a
            %   numeric value (0, 1, 2, 3, or 4), a matlab.unittest.Verbosity
            %   enumeration member, or a string or character vector corresponding to
            %   the name of a matlab.unittest.Verbosity enumeration member. To exclude
            %   logged diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
            %   LOGGINGLEVEL is Verbosity.Terse.
            %
            %   PLUGIN = DiagnosticsOutputPlugin(...,'OutputDetail',OUTPUTDETAIL)
            %   creates a DiagnosticsOutputPlugin that displays events with the amount
            %   of output detail specified by OUTPUTDETAIL. OUTPUTDETAIL is specified
            %   as a numeric value (0, 1, 2, 3, or 4), a matlab.unittest.Verbosity
            %   enumeration member, or a string or character vector corresponding to
            %   the name of a matlab.unittest.Verbosity enumeration member. By default,
            %   events are displayed at the Verbosity.Detailed level.
            %
            %   Example:
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.plugins.DiagnosticsOutputPlugin;
            %       import matlab.unittest.Verbosity;
            %
            %       % Create a TestSuite array and create a TestRunner with no plugins
            %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       runner = TestRunner.withNoPlugins();
            %
            %       % Create an instance of DiagnosticsOutputPlugin with a terse output detail level
            %       plugin = DiagnosticsOutputPlugin('OutputDetail',Verbosity.Terse);
            %
            %       % Add the plugin to the TestRunner and run the suite
            %       runner.addPlugin(plugin);
            %       result = runner.run(suite)
            
            arguments
                stream = {};
                namedargs.ExcludingFailureDiagnostics (1,1) logical = false;
                namedargs.IncludingPassingDiagnostics (1,1) logical = false;
                namedargs.LoggingLevel (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Terse;
                namedargs.OutputDetail (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Detailed;
            end
            
            if nargin == 1
                stream = {stream};
            end
            plugin = plugin@matlab.unittest.internal.plugins.HasOutputStreamMixin(stream{:});
            
            plugin.ExcludeFailureDiagnostics = namedargs.ExcludingFailureDiagnostics;
            plugin.IncludePassingDiagnostics = namedargs.IncludingPassingDiagnostics;
            plugin.LoggingLevel = namedargs.LoggingLevel;
            plugin.OutputDetail = namedargs.OutputDetail;
        end
    end
    
    methods (Hidden, Access=protected)
        function runTestSuite(plugin, pluginData)
            import matlab.unittest.internal.plugins.getFailureSummaryTableText;
            plugin.LinePrinter = plugin.createLinePrinter();
            plugin.EventRecordFormatter = plugin.createEventRecordFormatter();
            plugin.EventRecordProcessor = plugin.createEventRecordProcessor();
            
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            
            if ~plugin.ExcludeFailureDiagnostics && plugin.OutputDetail > 1
                txt = getFailureSummaryTableText(pluginData.TestResult);
                if strlength(txt) > 0
                    plugin.LinePrinter.printLine(txt);
                end
            end
        end
        
        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            unusedAffectedIndex = matlab.unittest.internal.plugins.NullDetailsLocationProvider;
            plugin.EventRecordProcessor.addListenersToSharedTestFixture(fixture, eventLocation, unusedAffectedIndex);
        end
        
        function testCase = createTestClassInstance(plugin, pluginData)
            testCase = createTestClassInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            unusedAffectedIndex = matlab.unittest.internal.plugins.NullDetailsLocationProvider;
            plugin.EventRecordProcessor.addListenersToTestClassInstance(testCase, eventLocation, unusedAffectedIndex);
        end
        
        function testCase = createTestRepeatLoopInstance(plugin, pluginData)
            testCase = createTestRepeatLoopInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            unusedAffectedIndex = matlab.unittest.internal.plugins.NullDetailsLocationProvider;
            plugin.EventRecordProcessor.addListenersToTestMethodInstance(testCase, eventLocation, unusedAffectedIndex);
        end
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = createTestMethodInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            unusedAffectedIndex = matlab.unittest.internal.plugins.NullDetailsLocationProvider;
            plugin.EventRecordProcessor.addListenersToTestMethodInstance(testCase, eventLocation, unusedAffectedIndex);
        end

    end
    
    methods(Access=private)
        function printer = createLinePrinter(plugin)
            import matlab.unittest.internal.plugins.LinePrinter;
            printer = LinePrinter(plugin.OutputStream); %#ok<CPROP>
        end
        
        function formatter = createEventRecordFormatter(plugin)
            import matlab.unittest.internal.plugins.StandardEventRecordFormatter;
            formatter = StandardEventRecordFormatter();
            formatter.AddDeliminatorsToExceptionEventReport = true;
            formatter.AddDeliminatorsToQualificationEventReport = true;
            formatter.UseAssumptionFailedEventMiniReport = true;
            formatter.ReportVerbosity = plugin.OutputDetail;
        end
        
        function processor = createEventRecordProcessor(plugin)
            import matlab.unittest.internal.plugins.EventRecordProcessor;
            import matlab.unittest.Verbosity;

            pluginWeakRef = matlab.lang.WeakReference(plugin);
            processor = EventRecordProcessor(@(eventRecord) pluginWeakRef.Handle.processEventRecord(eventRecord)); %#ok<CPROP>
            if plugin.ExcludeFailureDiagnostics
                processor.removeFailureEvents();
            end
            if plugin.IncludePassingDiagnostics
                processor.addPassingEvents();
            end
            processor.LoggingLevel = plugin.LoggingLevel;
            processor.OutputDetail = plugin.OutputDetail;
        end
        
        function processEventRecord(plugin,eventRecord)
            reportStr = eventRecord.getFormattedReport(plugin.EventRecordFormatter);
            plugin.LinePrinter.printFormatted(appendNewlineIfNonempty(prependNewlineIfNonempty(reportStr)));
        end
    end
end
            
% LocalWords:  unittest plugins LOGGINGLEVEL OUTPUTDETAIL mynamespace nv Parallelizable namedargs
% LocalWords:  strlength CPROP formatter Deliminators
