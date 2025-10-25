function addInteractiveListeners(testCase,varargin)
% This function is undocumented and may change in a future release.

% Copyright 2015-2023 The MathWorks, Inc.

parser = createParser();
parser.parse(varargin{:});
options = parser.Results;

options.OutputDetail = matlab.automation.Verbosity(options.OutputDetail); % To allow for strings
options.LoggingLevel = matlab.automation.Verbosity(options.LoggingLevel); % To allow for strings

qualificationCallback = @(~,eventData) processQualificationEvent(eventData,options);
logCallback = @(~,eventData) processDiagnosticLoggedEvent(eventData,options);

% Add passing listeners
testCase.addlistener('VerificationPassed', qualificationCallback);
testCase.addlistener('AssertionPassed', qualificationCallback);
testCase.addlistener('FatalAssertionPassed', qualificationCallback);
testCase.addlistener('AssumptionPassed', qualificationCallback);

% Add failing listeners
testCase.addlistener('VerificationFailed', qualificationCallback);
testCase.addlistener('AssertionFailed', qualificationCallback);
testCase.addlistener('FatalAssertionFailed', qualificationCallback);
testCase.addlistener('AssumptionFailed', qualificationCallback);

% Add diagnostic logging listener
testCase.addlistener('DiagnosticLogged', logCallback);

% Apply shared test fixtures
if options.ApplySharedTestFixtures
    matlab.unittest.internal.SharedTestFixtureSetup.applySharedTestFixtures(testCase);
end
end


function parser = createParser()
import matlab.unittest.internal.strictInputParser;
import matlab.unittest.Verbosity;
parser = strictInputParser();
parser.addParameter('IncludingPassingDiagnostics',false,...
    @(x) validateattributes(x,{'logical'},{'scalar'}));
parser.addParameter('LoggingLevel',Verbosity.Verbose,@validateVerbosity);
parser.addParameter('OutputDetail',Verbosity.Detailed,@validateVerbosity);
parser.addParameter('ApplySharedTestFixtures',false,...
    @(x) validateattributes(x,{'logical'},{'scalar'}));
end


function processQualificationEvent(eventData,options)
import matlab.unittest.internal.eventrecords.QualificationEventRecord;
import matlab.unittest.internal.plugins.EventReportPrinter;

printer = EventReportPrinter.withVerbosity(options.OutputDetail);

if ~options.IncludingPassingDiagnostics && contains(eventData.EventName,"Passed")
    % Currently we print a message like "Verification passed." even though
    % users have not opted to include passing diagnostics. We may decide to
    % change this behavior in the future.
    if options.OutputDetail > 0
        printer.printLine(sprintf('%s.',getString(message(...
            ['MATLAB:unittest:EventReportPrinter:' eventData.EventName 'EventDescriptionStart']))));
    end
    return;
end

eventScope = matlab.unittest.Scope.TestMethod;
eventLocation = "";
record = QualificationEventRecord.fromEventData(eventData,eventScope,eventLocation,...
    'Verbosity',options.OutputDetail);
printer.printQualificationEventReport(record);
end


function processDiagnosticLoggedEvent(eventData,options)
import matlab.unittest.internal.eventrecords.LoggedDiagnosticEventRecord;
import matlab.unittest.internal.plugins.EventReportPrinter;

if options.LoggingLevel < eventData.Verbosity
    return;
end

printer = EventReportPrinter.withVerbosity(options.OutputDetail);

eventScope = matlab.unittest.Scope.TestMethod;
eventLocation = "";
record = LoggedDiagnosticEventRecord.fromEventData(eventData,eventScope,eventLocation,...
    'Verbosity',options.OutputDetail);
printer.printLoggedDiagnosticEventReport(record);
end


function validateVerbosity(verbosity)
validateattributes(verbosity,{'numeric','string','char','matlab.unittest.Verbosity'},{'nonempty','row'});
if ~ischar(verbosity)
    validateattributes(verbosity, {'numeric','string','matlab.unittest.Verbosity'}, {'scalar'});
end
matlab.unittest.Verbosity(verbosity); % Validate that a value is valid
end