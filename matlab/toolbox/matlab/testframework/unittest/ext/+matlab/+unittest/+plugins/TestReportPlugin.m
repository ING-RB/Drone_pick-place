classdef TestReportPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
                            matlab.unittest.plugins.Parallelizable
    % TestReportPlugin - Plugin to create a report of test results
    %
    % Use the TestReportPlugin to configure the TestRunner to produce a
    % test report in '.docx', '.html', or '.pdf' format. This plugin is useful
    % to produce readable, navigable, and archivable test reports.
    %
    %   TestReportPlugin Methods:
    %       producingDOCX - Construct a plugin that produces a '.docx' report
    %       producingHTML - Construct a plugin that produces a '.html' report
    %       producingPDF - Construct a plugin that produces a '.pdf' report
    %
    %   TestReportPlugin Properties:
    %       IncludeCommandWindowText  - Indicator if command window text is included in the report
    %       IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
    %       LoggingLevel              - Maximum verbosity level at which logged diagnostics are included
    %       Title                     - String scalar that customizes the report title
    %
    %   Examples:
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.TestReportPlugin;
    %
    %       % Create a TestSuite array
    %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       % Create a test runner
    %       runner = TestRunner.withTextOutput;
    %
    %       % Add an TestReportPlugin to the TestRunner
    %       docxFile = 'MyTestReport.docx';
    %       plugin = TestReportPlugin.producingDOCX(docxFile);
    %       runner.addPlugin(plugin);
    %
    %       result = runner.run(suite);
    %
    %       open(docxFile);
    %
    %   See Also:
    %       matlab.unittest.plugins.testreport.DOCXTestReportPlugin
    %       matlab.unittest.plugins.testreport.PDFTestReportPlugin
    %       matlab.unittest.plugins.testreport.HTMLTestReportPlugin
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    properties(SetAccess=immutable)
        % IncludeCommandWindowText - Indicator if command window text is included in the report
        %
        %   The IncludeCommandWindowText property is a scalar logical (true or
        %   false) that indicates if the text that appears in the command window
        %   during test execution is included in the report.
        %
        %   If this property is set to true, then hyperlinks will be temporarily
        %   turned off in the command window during test execution.
        IncludeCommandWindowText
        
        % IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
        %
        %   The IncludePassingDiagnostics property is a scalar logical (true or
        %   false) that indicates if diagnostics from passing events are included
        %   in the report.
        IncludePassingDiagnostics
    end
    
    properties(SetAccess=private)
        % LoggingLevel - Maximum verbosity level at which logged diagnostics are included
        %
        %   The LoggingLevel property is a scalar matlab.unittest.Verbosity
        %   instance. The plugin includes logged diagnostics in the report that are
        %   logged at or below the specified level.
        LoggingLevel (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Terse;
    end

    properties(SetAccess=immutable)
        % Title - String scalar that customizes the report title
        %
        %   The Title property customizes the title of the test report. 
        %   You can set the property to a string scalar or character 
        %   vector during construction of the plugin.
        Title string
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
        %   false) that indicates if logged diagnostics are excluded from the
        %   report.
        ExcludeLoggedDiagnostics
    end
    
    properties(Hidden, SetAccess=private)
        ProgressStream
        Clock
    end
    
    properties (GetAccess = protected, SetAccess = private)
        EventRecords
    end
    properties(Access=private)
        EventRecordGatherer
    end
    properties (Access = private, Transient)
        OutputCollector
    end
    
    methods (Hidden, Sealed)
        function tf = supportsParallelThreadPool_(~)
            tf = true;
        end
    end
    
    methods
        function levels = get.Verbosity(plugin)
            levels = matlab.unittest.Verbosity(1:double(plugin.LoggingLevel));
        end
        
        function bool = get.ExcludeLoggedDiagnostics(plugin)
            bool = plugin.LoggingLevel == matlab.unittest.Verbosity.None;
        end
    end
    
    methods(Hidden, Access=protected)
        function plugin = TestReportPlugin(varargin)           
            parser = createArgumentParser();
            parser.parse(varargin{:});
            
            plugin.IncludePassingDiagnostics = parser.Results.IncludingPassingDiagnostics;
            plugin.IncludeCommandWindowText = parser.Results.IncludingCommandWindowText;
            plugin.LoggingLevel = parser.Results.LoggingLevel;
            plugin.Title = parser.Results.Title;
            
            % Undocumented properties:
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
            plugin.ProgressStream = parser.Results.ProgressStream;
            plugin.Clock = parser.Results.Clock_;
        end
    end
    
    methods(Static)
        function plugin = producingDOCX(varargin)
            % producingDOCX - Construct a plugin that produces a '.docx' report
            %
            %   PLUGIN = TestReportPlugin.producingDOCX() returns a plugin that
            %   produces a '.docx' report in the temporary folder. This syntax is
            %   equivalent to TestReportPlugin.producingDOCX([tempname '.docx']).
            %
            %   PLUGIN = TestReportPlugin.producingDOCX(DOCXFILENAME) returns a plugin
            %   that produces a '.docx' report. The output is printed to the file
            %   DOCXFILENAME. Every time the suite is run with this plugin, the file
            %   DOCXFILENAME is overwritten.
            %
            %   PLUGIN = TestReportPlugin.producingDOCX(...,'IncludingCommandWindowText',true)
            %   creates a TestReportPlugin that includes the text that appears in the
            %   command window during test execution in the report.
            %
            %   PLUGIN = TestReportPlugin.producingDOCX(...,'IncludingPassingDiagnostics',true)
            %   creates a TestReportPlugin that includes diagnostics from passing
            %   events in the report.
            %
            %   PLUGIN = TestReportPlugin.producingDOCX(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a TestReportPlugin that includes logged diagnostics that are
            %   logged at or below LOGGINGLEVEL. LOGGINGLEVEL is specified as a
            %   matlab.unittest.Verbosity enumeration object. To exclude logged
            %   diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
            %   LOGGINGLEVEL is Verbosity.Terse.
            %
            %   PLUGIN = TestReportPlugin.producingDOCX(...,'PageOrientation',VALUE)
            %   creates a TestReportPlugin that produces a report with a page
            %   orientation specified by VALUE. VALUE can either be 'portrait'
            %   (default) or 'landscape'.
            %
            %   See also:
            %       matlab.unittest.plugins.testreport.DOCXTestReportPlugin
            %       matlab.unittest.Verbosity
            
            plugin = matlab.unittest.plugins.testreport.DOCXTestReportPlugin(varargin{:});
        end
        
        function plugin = producingHTML(varargin)
            % producingHTML - Construct a plugin that produces a '.html' report
            %
            %   PLUGIN = TestReportPlugin.producingHTML() returns a plugin that
            %   produces a '.html' report, including  multiple files, in the temporary folder.
            %   This syntax is equivalent to TestReportPlugin.producingHTML(tempname).
            %
            %   PLUGIN = TestReportPlugin.producingHTML(location) returns a plugin
            %   that produces a '.html' report at the specified location. 
            %   You can specify location as a file or folder:
            %   - If you specify a file, then the plugin generates a single-file,
            %       standalone report and saves it as the specified file.
            %   - If you specify a folder, then the plugin generates a multi-file report
            %       and saves it to the specified folder with "index.html" as the main
            %       report file.
            %
            %   PLUGIN = TestReportPlugin.producingHTML(...,'IncludingCommandWindowText',true)
            %   creates a TestReportPlugin that includes the text that appears in the
            %   command window during test execution in the report.
            %
            %   PLUGIN = TestReportPlugin.producingHTML(...,'IncludingPassingDiagnostics',true)
            %   creates a TestReportPlugin that includes diagnostics from passing
            %   events in the report.
            %
            %   PLUGIN = TestReportPlugin.producingHTML(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a TestReportPlugin that includes logged diagnostics that are
            %   logged at or below LOGGINGLEVEL. LOGGINGLEVEL is specified as a
            %   matlab.unittest.Verbosity enumeration object. To exclude logged
            %   diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
            %   LOGGINGLEVEL is Verbosity.Terse.
            %
            %   PLUGIN = TestReportPlugin.producingHTML(...,'MainFile',MAINFILENAME)
            %   creates a TestReportPlugin where MAINFILENAME is used as the name of
            %   the main file in the generated multi-file HTML report. 
            %   By default, MAINFILENAME is 'index.html'.
            %
            %   See also:
            %       matlab.unittest.plugins.testreport.HTMLTestReportPlugin
            %       matlab.unittest.Verbosity
            
            plugin = matlab.unittest.plugins.testreport.HTMLTestReportPlugin(varargin{:});
        end
        
        function plugin = producingPDF(varargin)
            % producingPDF - Construct a plugin that produces a '.pdf' report
            %
            %   PLUGIN = TestReportPlugin.producingPDF() returns a plugin that
            %   produces a '.pdf' report in the temporary folder. This syntax
            %   is equivalent to TestReportPlugin.producingPDF([tempname '.pdf']).
            %
            %   PLUGIN = TestReportPlugin.producingPDF(PDFFILENAME) returns a plugin
            %   that produces a '.pdf' report. The output is printed to the file
            %   PDFFILENAME. Every time the suite is run with this plugin, the file
            %   PDFFILENAME is overwritten.
            %
            %   PLUGIN = TestReportPlugin.producingPDF(...,'IncludingCommandWindowText',true)
            %   creates a TestReportPlugin that includes the text that appears in the
            %   command window during test execution in the report.
            %
            %   PLUGIN = TestReportPlugin.producingPDF(...,'IncludingPassingDiagnostics',true)
            %   creates a TestReportPlugin that includes diagnostics from passing
            %   events in the report.
            %
            %   PLUGIN = TestReportPlugin.producingPDF(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a TestReportPlugin that includes logged diagnostics that are
            %   logged at or below LOGGINGLEVEL. LOGGINGLEVEL is specified as a
            %   matlab.unittest.Verbosity enumeration object. To exclude logged
            %   diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
            %   LOGGINGLEVEL is Verbosity.Terse.
            %
            %   PLUGIN = TestReportPlugin.producingPDF(...,'PageOrientation',VALUE)
            %   creates a TestReportPlugin that produces a report with a page
            %   orientation specified by VALUE. VALUE can either be 'portrait'
            %   (default) or 'landscape'.
            %
            %   PDF test reports are generated based on your system locale and the font
            %   families installed on your machine. When generating a report with a
            %   non-English locale, unless your machine has the 'Noto Sans CJK' font
            %   families installed, the report may have pound sign characters (#) in
            %   place of Chinese, Japanese, and Korean characters.
            %
            %   See also:
            %       matlab.unittest.plugins.testreport.PDFTestReportPlugin
            %       matlab.unittest.Verbosity
            
            plugin = matlab.unittest.plugins.testreport.PDFTestReportPlugin(varargin{:});
        end
    end
    
    methods (Hidden, Access=protected)
        function runSession(plugin,pluginData)
            plugin.beforeRun(pluginData);
            finishup = onCleanup(@() plugin.afterRun(pluginData));
            runSession@matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
        end
        
        function runTestSuite(plugin, pluginData)
            plugin.EventRecordGatherer = plugin.createEventRecordGatherer(pluginData);
            clean = onCleanup(@()storeEventRecordGatherer(plugin,pluginData));
            plugin.runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
            function storeEventRecordGatherer(plugin,pluginData)
                plugin.storeIn(pluginData.CommunicationBuffer,plugin.EventRecordGatherer);
            end
        end
        
        function fixture = createSharedTestFixture(plugin,pluginData)
            fixture = plugin.createSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToSharedTestFixture(fixture, eventLocation,...
                pluginData.DetailsLocationProvider);
        end
        
        function testCase = createTestClassInstance(plugin,pluginData)
            testCase = plugin.createTestClassInstance@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToTestClassInstance(testCase, eventLocation, ...
                pluginData.DetailsLocationProvider);
        end
        
        function testCase = createTestMethodInstance(plugin,pluginData)
            testCase = plugin.createTestMethodInstance@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToTestMethodInstance(testCase, eventLocation, ...
                pluginData.DetailsLocationProvider);
        end
        
        function reportFinalizedSuite(plugin, pluginData)
            defaultEventRecordGatherer = plugin.createEventRecordGatherer(pluginData);
            eventRecordGatherer = plugin.retrieveFrom(pluginData.CommunicationBuffer, DefaultData = defaultEventRecordGatherer);
            plugin.EventRecords(pluginData.SuiteIndices) = eventRecordGatherer.EventRecordsCell;
            reportFinalizedSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
        end
    end
    
    methods(Abstract, Hidden, Access=protected)
        validateReportCanBeCreated(plugin)

        reportDocument = createReportDocument(testSessionData)
    end
        
    methods(Access=private)
        function recordGatherer = createEventRecordGatherer(plugin,pluginData)
            import matlab.unittest.Verbosity;
            import matlab.unittest.internal.plugins.EventRecordGatherer;
            recordGatherer = EventRecordGatherer(numel(pluginData.TestSuite)); %#ok<CPROPLC>
            if plugin.IncludePassingDiagnostics
                recordGatherer.addPassingEvents();
            end
            recordGatherer.LoggingLevel = plugin.LoggingLevel;
        end
        
        function generateReport(plugin,suite,results,commandWindowText)
            import matlab.unittest.internal.plugins.testreport.TestReportData;
            import matlab.unittest.internal.TestSessionData;
            
            eventRecordsList = plugin.EventRecords;
            
            testSessionData = TestSessionData(suite,results,...
                'EventRecordsList',eventRecordsList,...
                'CommandWindowText',commandWindowText);
            
            reportDocument = plugin.createReportDocument(testSessionData);
            
            reportDocument.generateReport();
        end
        
        function beforeRun(plugin, pluginData)
            import matlab.unittest.internal.eventrecords.EventRecord;
            import matlab.unittest.internal.plugins.RawOutputCollector;
            plugin.validateReportCanBeCreated();
            
            rawOutputCollector = RawOutputCollector();
            if plugin.IncludeCommandWindowText
                rawOutputCollector.turnCollectingOn();
            end
            plugin.OutputCollector = rawOutputCollector;
            plugin.EventRecords = cell(1, numel(pluginData.TestSuite));
            plugin.EventRecords = repmat({EventRecord.empty(1,0)},1,numel(pluginData.TestSuite));
        end
        
        function afterRun(plugin, pluginData)
            suite = pluginData.TestSuite;
            results = pluginData.TestResult;
            
            plugin.OutputCollector.turnCollectingOff();
            commandWindowText = plugin.OutputCollector.RawOutput;
            
            plugin.generateReport(suite, results, commandWindowText)
        end
    end
end

function parser = createArgumentParser()
import matlab.unittest.Verbosity;
import matlab.unittest.plugins.ToStandardOutput;

parser = matlab.unittest.internal.strictInputParser;
parser.addParameter('IncludingPassingDiagnostics', false, ...
    @(x) validateattributes(x,{'logical'},{'scalar'}));
parser.addParameter('IncludingCommandWindowText', false, ...
    @(x) validateattributes(x,{'logical'},{'scalar'}));
parser.addParameter('LoggingLevel', Verbosity.Terse, @validateVerbosity);
parser.addParameter('Title', ...
    string(getString(message("MATLAB:unittest:TestReportDocument:ReportTitle", ['MATLAB' char(174)]))),...
    @validateTitle);

% Undocumented Parameters:
parser.addParameter('Verbosity', Verbosity.Terse, @validateVerbosity);
parser.addParameter('ExcludingLoggedDiagnostics', false, ...
    @(x)validateattributes(x,{'logical'},{'scalar'}));
parser.addParameter('ProgressStream',ToStandardOutput(),...
    @(x) validateattributes(x,{'matlab.unittest.plugins.OutputStream'},{'scalar'}));
parser.addParameter("Clock_", @datetime);
end

function validateVerbosity(verbosity)
validateattributes(verbosity,{'numeric','string','char','matlab.unittest.Verbosity'},{'nonempty','row'});
if ~ischar(verbosity)
    validateattributes(verbosity, {'numeric','string','matlab.unittest.Verbosity'}, {'scalar'});
end
matlab.unittest.Verbosity(verbosity); % Validate that a value is valid
end

function validateTitle(title)
    arguments
       title {mustBeNonzeroLengthText, mustBeTextScalar} %#ok<INUSA>
    end
end

% LocalWords:  archivable mynamespace testreport DOCXFILENAME PDFFILENAME LOGGINGLEVEL Parallelizable
% LocalWords:  Cancelable CPROPLC unittest plugins HTMLFOLDER MAINFILENAME Noto finishup INUSA
% LocalWords:  CJK eventrecords
