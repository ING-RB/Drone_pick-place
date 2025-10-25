classdef (Hidden) DiagnosticsOutputPlugin < ...
        matlab.buildtool.plugins.BuildRunnerPlugin & ...
        matlab.buildtool.internal.plugins.HasOutputStreamMixin
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % DiagnosticsOutputPlugin - Plugin to direct diagnostics to output stream
    %
    %   The matlab.buildtool.plugins.DiagnosticsOutputPlugin class creates a
    %   plugin to direct diagnostics to an output stream. To configure the type
    %   of diagnostics and detail level that the build tool outputs, add this
    %   plugin to a BuildRunner instance.
    %
    %   DiagnosticsOutputPlugin methods:
    %      DiagnosticsOutputPlugin - Create plugin

    %   Copyright 2021-2024 The MathWorks, Inc.

    properties (Hidden, Access = protected)
        Printer matlab.buildtool.internal.plugins.LinePrinter {mustBeScalarOrEmpty}
        EventRecordFormatter matlab.buildtool.internal.eventrecords.EventRecordFormatter {mustBeScalarOrEmpty}
        EventRecordProcessor matlab.buildtool.internal.plugins.EventRecordProcessor {mustBeScalarOrEmpty}
    end

    properties (Constant, Hidden)
        LinePrefix (1,1) string = "## "
    end

    properties (SetAccess = private)
        LoggingLevel (1,1) matlab.automation.Verbosity = matlab.automation.Verbosity.Concise
        OutputDetail (1,1) matlab.automation.Verbosity = matlab.automation.Verbosity.Concise
    end

    methods
        function plugin = DiagnosticsOutputPlugin(stream, options)
            % DiagnosticsOutputPlugin - Create plugin
            %
            %   P = matlab.buildtool.plugins.DiagnosticsOutputPlugin creates a plugin
            %   that directs diagnostics for failed events and for events logged at the
            %   Verbosity.Concise level to the ToStandardOutput stream.
            %
            %   P = matlab.buildtool.plugins.DiagnosticsOutputPlugin(STREAM) redirects
            %   diagnostics to the specified output stream. STREAM must be a
            %   matlab.automation.streams.OutputStream scalar or empty.
            %   
            %   P = matlab.buildtool.plugins.DiagnosticsOutputPlugin(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a DiagnosticsOutputPlugin that includes diagnostics 
            %   logged at or below LOGGINGLEVEL. LOGGINGLEVEL is specified as a 
            %   numeric value (0, 1, 2, 3 or 4), a matlab.automation.Verbosity
            %   enumeration member, or a string or character vector corresponding to
            %   the name of a matlab.automation.Verbosity enumeration member. 
            %   Setting LOGGINGLEVEL as 0 excludes all logged diagnostics. 
            %   By default, LOGGINGLEVEL is Verbosity.Concise.

            arguments
                stream matlab.automation.streams.OutputStream {mustBeScalarOrEmpty} = matlab.automation.streams.OutputStream.empty()
                options.LoggingLevel (1,1) matlab.automation.Verbosity = matlab.automation.Verbosity.Concise
                options.OutputDetail (1,1) matlab.automation.Verbosity = matlab.automation.Verbosity.Concise
            end

            plugin = plugin@matlab.buildtool.internal.plugins.HasOutputStreamMixin(stream);
            plugin.LoggingLevel = options.LoggingLevel;
            plugin.OutputDetail = options.OutputDetail;
        end
    end

    methods (Access = protected)
        function runTaskGraph(plugin, pluginData)
            plugin.Printer = plugin.createLinePrinter();
            plugin.EventRecordFormatter = plugin.createEventRecordFormatter();
            plugin.EventRecordProcessor = plugin.createEventRecordProcessor();

            runTaskGraph@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);
        end

        function fixture = createBuildFixture(plugin, pluginData)
            fixture = createBuildFixture@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordProcessor.addListenersToBuildFixture(fixture, eventLocation);
        end

        function context = createTaskContext(plugin, pluginData)
            context = createTaskContext@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordProcessor.addListenersToTaskContext(context, eventLocation);
        end
    end

    methods (Access = private)
        function printer = createLinePrinter(plugin)
            import matlab.buildtool.internal.plugins.LinePrinter;
            printer = LinePrinter(plugin.OutputStream);
        end

        function formatter = createEventRecordFormatter(plugin)
            import matlab.buildtool.internal.plugins.StandardEventRecordFormatter;
            formatter = StandardEventRecordFormatter();
            formatter.ReportVerbosity = plugin.OutputDetail;
        end

        function processor = createEventRecordProcessor(plugin)
            import matlab.buildtool.internal.plugins.EventRecordProcessor;
            pluginWeakRef = matlab.lang.WeakReference(plugin);
            processor = EventRecordProcessor(@(record)pluginWeakRef.Handle.processEventRecord(record)); %#ok<CPROP>
            processor.LoggingLevel = plugin.LoggingLevel;
        end

        function processEventRecord(plugin, eventRecord)
            report = eventRecord.getFormattedReport(plugin.EventRecordFormatter);
            if eventRecord.EventName ~= "DiagnosticLogged"
                report = indentIfNonempty(report, plugin.LinePrefix);
            end
            plugin.Printer.printFormatted(appendNewlineIfNonempty(report));
        end
    end
end

% LocalWords:  LOGGINGLEVEL
