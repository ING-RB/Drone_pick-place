classdef DiagnosticsRecordingPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
                                      matlab.unittest.plugins.Parallelizable
    % DiagnosticsRecordingPlugin - Plugin to record diagnostics on test results
    %
    %   The DiagnosticsRecordingPlugin can be added to the TestRunner to record
    %   diagnostics on test results. These diagnostics are recorded as
    %   DiagnosticRecord arrays. Each of the DiagnosticRecords corresponds to
    %   events in individual tests. The DiagnosticsRecordingPlugin adds records
    %   for qualification failures and logged events by default.
    %
    %   DiagnosticsRecordingPlugin methods:
    %       DiagnosticsRecordingPlugin - Class constructor
    %
    %   DiagnosticsRecordingPlugin properties:
    %       IncludePassingDiagnostics - Indicator if diagnostics are recorded for passing events
    %       LoggingLevel              - Maximum verbosity level at which logged diagnostics are recorded
    %       OutputDetail              - Verbosity level that defines amount of information recorded
    %
    %   Examples:
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.DiagnosticsRecordingPlugin;
    %
    %       % Create a TestSuite array
    %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       % Create a TestRunner with no plugins
    %       runner = TestRunner.withNoPlugins;
    %
    %       % Add a new plugin to the TestRunner
    %       runner.addPlugin(DiagnosticsRecordingPlugin);
    %
    %       % Run the suite to see diagnostics recorded on test results
    %       result = runner.run(suite)
    %
    %       % Inspect recorded diagnostics
    %       for resultIdx = 1:numel(result)
    %           fprintf('Displaying diagnostics for result: %d\n', resultIdx);
    %           diagnosticRecord = result(resultIdx).Details.DiagnosticRecord;
    %           for recordIdx = 1:numel(diagnosticRecord)
    %               fprintf('Result: %d, Record: %d\n', resultIdx, recordIdx);
    %               fprintf('%s in %s\n',diagnosticRecord(recordIdx).Event,...
    %                   diagnosticRecord(recordIdx).Scope);
    %               fprintf('%s\n', diagnosticRecord(recordIdx).Report);
    %           end
    %       end
    %
    %       % Select records for failed events within the first test
    %       diagnosticRecords = result(1).Details.DiagnosticRecord;
    %       failedRecords     = selectFailed(diagnosticRecords);
    %
    %       % Select records for incomplete events within the first test
    %       diagnosticRecords = result(1).Details.DiagnosticRecord;
    %       incompleteRecords = selectIncomplete(diagnosticRecords);
    %
    %       % Select records for filtered events within the first test
    %       diagnosticRecords = result(1).Details.DiagnosticRecord;
    %       incompleteRecords = selectIncomplete(diagnosticRecords);
    %       failedRecords     = selectFailed(diagnosticRecords);
    %       filteredRecords   = setdiff(incompleteRecords, failedRecords);
    %
    %   See also:
    %       matlab.unittest.plugins.diagnosticrecord.DiagnosticRecord
    %
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    properties(SetAccess=immutable)
        % IncludePassingDiagnostics - Indicator if diagnostics are recorded for passing events
        %
        %   The IncludePassingDiagnostics property is a scalar logical (true or
        %   false) that indicates if diagnostics from passing events are recorded
        %   on test results. This property is read-only and is set through the
        %   constructor.
        IncludePassingDiagnostics (1,1) logical = false;
    end
    
    properties(SetAccess=private)
        % LoggingLevel - Maximum verbosity level at which logged diagnostics are recorded
        %
        %   The LoggingLevel property is a scalar matlab.unittest.Verbosity
        %   instance. The plugin records logged diagnostics that are logged at or
        %   below the specified level on test results. This property is read-only
        %   and is set through the constructor.
        LoggingLevel (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Terse;
        
        % OutputDetail - Verbosity level that defines amount of information recorded
        %
        %   The OutputDetail property is a scalar matlab.unittest.Verbosity
        %   instance that defines the amount of detail recorded on test results
        %   for passing, failing, and logged events. This property is read-only and
        %   is set through the constructor.
        OutputDetail (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Detailed;
    end
    
    properties (Constant, Access = private)
        DetailsLabel = 'DiagnosticRecord';
    end
    
    properties (Hidden, Dependent, SetAccess = private)
        % Verbosity - Verbosity is not recommended. Use LoggingLevel instead.
        %
        %   The Verbosity property is an array of matlab.unittest.Verbosity
        %   instances. The plugin only reacts to diagnostics that are logged at a
        %   level listed in this array.
        Verbosity;
        
        % ExcludeLoggedDiagnostics - ExcludeLoggedDiagnostics is not recommended. Use LoggingLevel instead.
        %
        %   The ExcludeLoggedDiagnostics property is a scalar logical (true or
        %   false) that indicates if logged diagnostics are recorded on test
        %   results.
        ExcludeLoggedDiagnostics;
    end
    
    methods (Hidden, Sealed)
        function tf = supportsParallelThreadPool_(~)
            tf = true;
        end
    end
    
    methods
        function plugin = DiagnosticsRecordingPlugin(varargin)
            % DiagnosticsRecordingPlugin - Class constructor
            %
            %   PLUGIN = DiagnosticsRecordingPlugin creates a
            %   DiagnosticsRecordingPlugin instance and returns it in PLUGIN. To record
            %   diagnostics on test results when failure conditions and logged events
            %   occur, add this plugin to a TestRunner instance.
            %
            %   PLUGIN = DiagnosticsRecordingPlugin(...,'IncludingPassingDiagnostics',true)
            %   creates a DiagnosticsRecordingPlugin that records diagnostics from
            %   passing events on test results.
            %
            %   PLUGIN = DiagnosticsRecordingPlugin(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a DiagnosticsRecordingPlugin that records logged diagnostics
            %   that are logged at or below LOGGINGLEVEL. LOGGINGLEVEL is specified as
            %   a matlab.unittest.Verbosity enumeration object. To exclude logged
            %   diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
            %   LOGGINGLEVEL is Verbosity.Terse.
            %
            %   PLUGIN = DiagnosticsRecordingPlugin(...,'OutputDetail',OUTPUTDETAIL)
            %   creates a DiagnosticsRecordingPlugin that records diagnostics from
            %   events with the amount of output detail specified by OUTPUTDETAIL.
            %   OUTPUTDETAIL is specified as a matlab.unittest.Verbosity enumeration
            %   object. By default, events are displayed at the Verbosity.Detailed
            %   level.
            %
            %   Example:
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.plugins.DiagnosticsRecordingPlugin;
            %
            %       % Create a TestSuite array
            %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       % Create a TestRunner with no plugins
            %       runner = TestRunner.withNoPlugins;
            %
            %       % Create an instance of DiagnosticsRecordingPlugin
            %       plugin = DiagnosticsRecordingPlugin;
            %
            %       % Add the plugin to the TestRunner
            %       runner.addPlugin(plugin);
            %
            %       % Run the suite to see diagnostics recorded on test results
            %       result = runner.run(suite)
            %
            %       Inspect recorded diagnostics
            %       diagnosticRecord = result(1).Details.DiagnosticRecord;
            %
            %   See also:
            %       matlab.unittest.Verbosity
            %       matlab.unittest.plugins.DiagnosticsOutputPlugin
            parser = createParser();
            parser.parse(varargin{:});
            
            plugin.IncludePassingDiagnostics = parser.Results.IncludingPassingDiagnostics;
            plugin.LoggingLevel = parser.Results.LoggingLevel;
            plugin.OutputDetail = parser.Results.OutputDetail;
            
            if ~ismember('Verbosity',parser.UsingDefaults) && ismember('LoggingLevel',parser.UsingDefaults)
                % Support old 'Verbosity' n/v pair if supplied, but only
                % apply it if 'LoggingLevel' n/v pair was not also supplied.
                plugin.LoggingLevel = parser.Results.Verbosity;
            end
            if parser.Results.ExcludingLoggedDiagnostics && ismember('LoggingLevel',parser.UsingDefaults)
                % Support old 'ExcludingLoggedDiagnostics' n/v pair if
                % supplied, but only apply it if 'LoggingLevel' n/v pair
                % was not also supplied.
                plugin.LoggingLevel = matlab.unittest.Verbosity.None;
            end
        end
        
        function levels = get.Verbosity(plugin)
            levels = matlab.unittest.Verbosity(1:double(plugin.LoggingLevel));
        end
        
        function bool = get.ExcludeLoggedDiagnostics(plugin)
            bool = plugin.LoggingLevel == matlab.unittest.Verbosity.None;
        end
    end
    
    methods(Hidden, Access=protected)
        function runTestSuite(plugin, pluginData)
            import matlab.unittest.plugins.diagnosticrecord.DiagnosticRecord;
            emptyRecord = DiagnosticRecord.empty(1,0);
            pluginData.ResultDetails.append(plugin.DetailsLabel,emptyRecord);
            
            plugin.runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
        end
        
        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            eventRecordProducer = plugin.createEventRecordProducer(pluginData.ResultDetails);
            unusedAffectedIndex = matlab.unittest.internal.plugins.NullDetailsLocationProvider;
            eventRecordProducer.addListenersToSharedTestFixture(fixture, eventLocation, unusedAffectedIndex);
        end
        
        function testCase = createTestClassInstance(plugin, pluginData)
            testCase = plugin.createTestClassInstance@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
            eventLocation = pluginData.Name;            
            eventRecordProducer = plugin.createEventRecordProducer(pluginData.ResultDetails);
            unusedAffectedIndex = matlab.unittest.internal.plugins.NullDetailsLocationProvider;
            eventRecordProducer.addListenersToTestClassInstance(testCase, eventLocation, unusedAffectedIndex);
       end
        
        function testCase = createTestRepeatLoopInstance(plugin, pluginData)
            testCase = plugin.createTestRepeatLoopInstance@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
            eventLocation = pluginData.Name;
            eventRecordProducer = plugin.createEventRecordProducer(pluginData.ResultDetails);
            unusedAffectedIndex = matlab.unittest.internal.plugins.NullDetailsLocationProvider;
            eventRecordProducer.addListenersToTestRepeatLoopInstance(testCase, eventLocation, unusedAffectedIndex);
        end
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = plugin.createTestMethodInstance@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
            eventLocation = pluginData.Name;
            eventRecordProducer = plugin.createEventRecordProducer(pluginData.ResultDetails);
            unusedAffectedIndex = matlab.unittest.internal.plugins.NullDetailsLocationProvider;
            eventRecordProducer.addListenersToTestMethodInstance(testCase, eventLocation, unusedAffectedIndex);
        end
   
        function processor = createEventRecordProducer(plugin, resultDetails)
            import matlab.unittest.internal.plugins.EventRecordProcessor;
            processor = EventRecordProcessor(@(eventRecord) resultDetails.append(plugin.DetailsLabel,...
                eventRecord.toDiagnosticRecord(plugin.OutputDetail))); 
            if plugin.IncludePassingDiagnostics
                processor.addPassingEvents();
            end
            processor.LoggingLevel = plugin.LoggingLevel;
            processor.OutputDetail = plugin.OutputDetail;            
        end
    end
end

function parser = createParser()
import matlab.unittest.Verbosity;
parser = matlab.unittest.internal.strictInputParser;
parser.addParameter('IncludingPassingDiagnostics', false, ...
    @(x)validateattributes(x,{'logical'},{'scalar'}));
parser.addParameter('LoggingLevel', Verbosity.Terse, @validateVerbosity);
parser.addParameter('OutputDetail', Verbosity.Detailed, @validateVerbosity);
parser.addParameter('Verbosity', Verbosity.Terse, @validateVerbosity);
parser.addParameter('ExcludingLoggedDiagnostics',false, ...
    @(x)validateattributes(x,{'logical'},{'scalar'}));
end

function validateVerbosity(verbosity)
validateattributes(verbosity,{'numeric','string','char','matlab.unittest.Verbosity'},{'nonempty','row'});
if ~ischar(verbosity)
    validateattributes(verbosity, {'numeric','string','matlab.unittest.Verbosity'}, {'scalar'});
end
matlab.unittest.Verbosity(verbosity); % Validate that a value is valid
end

% LocalWords:  mynamespace diagnosticrecord evd LOGGINGLEVEL OUTPUTDETAIL Parallelizable
