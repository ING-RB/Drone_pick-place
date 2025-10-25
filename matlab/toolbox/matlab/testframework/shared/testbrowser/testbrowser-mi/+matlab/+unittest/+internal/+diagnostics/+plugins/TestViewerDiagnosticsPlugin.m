classdef TestViewerDiagnosticsPlugin < matlab.unittest.plugins.DiagnosticsRecordingPlugin 
    
    % TestViewerDiagnosticsPlugin - This Plugin supports recording diagnostics on test
    % results for Test Browser and Test Manager.
    %
    %   The TestViewerDiagnosticsPlugin can be added to the TestRunner to record
    %   diagnostics on test results.The TestViewerDiagnosticsPlugin adds records
    %   for qualification failures and Exception events.
    %
    %   TestViewerDiagnosticsPlugin methods:
    %       TestViewerDiagnosticsPlugin - Class constructor
    %
   
    %
    % Copyright 2021-2023 The MathWorks, Inc.

    properties(Hidden, Access=private)
        LinePrinter;
        EventRecordFormatter;
    end

    properties(SetAccess=private)
        % ReportDetail - Verbosity for test diagnostics report format.
        %
        %   The ReportDetail property is a scalar matlab.unittest.Verbosity
        %   instance. This property is read-only and is set through the constructor.
        ReportDetail (1,1) matlab.unittest.Verbosity 

        % SummaryDetail - Verbosity level that defines amount of
        % diagnostics recorded for summary.
        % This property is read-only and is set through the constructor.
        SummaryDetail (1,1) matlab.unittest.Verbosity 
    end
    
    properties (Constant, Access = private)
        DetailsLabel = 'TestBrowserDiagnosticRecords';
    end
    
    methods
        function plugin = TestViewerDiagnosticsPlugin(options)
            arguments
                options.IncludingPassingDiagnostics (1,1) logical = false;
                options.LoggingLevel (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Terse;
                options.OutputDetail  (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Detailed;
                options.ReportDetail (1,1) matlab.unittest.Verbosity 
                options.SummaryDetail (1,1) matlab.unittest.Verbosity 
            end
            % TestViewerDiagnosticsPlugin - Class constructor
            %
            %   PLUGIN = TestViewerDiagnosticsPlugin creates a
            %   TestViewerDiagnosticsPlugin instance and returns it in PLUGIN. 
            %
            %   PLUGIN = TestViewerDiagnosticsPlugin(...,'IncludingPassingDiagnostics',true)
            %   creates a TestViewerDiagnosticsPlugin that records diagnostics from
            %   passing events on test results.
            %
            %   PLUGIN = TestViewerDiagnosticsPlugin(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a TestViewerDiagnosticsPlugin that records logged diagnostics
            %   that are logged at or below LOGGINGLEVEL. LOGGINGLEVEL is specified as
            %   a matlab.unittest.Verbosity enumeration object. To exclude logged
            %   diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
            %   LOGGINGLEVEL is Verbosity.Terse.
            %
            %   See also:
            %       matlab.unittest.Verbosity
            %       matlab.unittest.plugins.DiagnosticsRecordingPlugin 

            plugin = plugin@matlab.unittest.plugins.DiagnosticsRecordingPlugin(IncludingPassingDiagnostics = ...
                options.IncludingPassingDiagnostics, LoggingLevel = options.LoggingLevel, OutputDetail = ...
                options.OutputDetail);

            plugin.ReportDetail = plugin.OutputDetail;
            plugin.SummaryDetail = plugin.OutputDetail;


            if isfield(options, 'ReportDetail')
                 plugin.ReportDetail = options.ReportDetail;
            end

            if isfield(options, 'SummaryDetail')
                plugin.SummaryDetail = options.SummaryDetail;
            end     
        end
    end
    
    methods(Access=protected)
        function runTestSuite(plugin, pluginData)
            import matlab.unittest.internal.diagnostics.plugins.TestViewerRecord;

            emptyRecord = TestViewerRecord.empty(1,0);
            pluginData.ResultDetails.append(plugin.DetailsLabel,emptyRecord);
            
            plugin.runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
        end

        function processor = createEventRecordProducer(plugin,resultDetails)
           import matlab.unittest.internal.diagnostics.plugins.TestViewerEventRecordProcessor;

            processor = TestViewerEventRecordProcessor(...
                @(eventRecord)processEventRecord(eventRecord, resultDetails, plugin));

            if plugin.IncludePassingDiagnostics
                processor.addPassingEvents();
            end
            processor.LoggingLevel = plugin.LoggingLevel;
            processor.OutputDetail = plugin.OutputDetail;

            processor.SummaryDetail = plugin.SummaryDetail;
            processor.ReportDetail = plugin.ReportDetail;
        end
    end
end

function processEventRecord(record, resultDetails, plugin)
import matlab.unittest.internal.diagnostics.plugins.TestViewerLogRecord;

loggedEventRecord = 'matlab.unittest.internal.eventrecords.LoggedDiagnosticEventRecord';
if  strcmpi(class(record),loggedEventRecord)
    resultDetails.append(plugin.DetailsLabel,...
        TestViewerLogRecord(record, plugin.ReportDetail));
else
    resultDetails.append(plugin.DetailsLabel, record);
end
end
