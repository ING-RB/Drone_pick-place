% generateDOCXReport - Generate DOCX report from test results
%
% generateDOCXReport(results) generates a DOCX report from the test results
% and stores it in a temporary folder.
%
% generateDOCXReport(results,docxFile) saves the report to the file
% docxFile.
%
% generateDOCXReport(...,PageOrientation=Value) generates a report with the
% specified orientation. You can specify PageOrientation as "portrait" or
% "landscape". By default, the method generates a report with portrait
% orientation.
%
% generateDOCXReport(...,Title=Value) generates a report with the
% specified title. You can specify Title as a string scalar or character vector.
% By default, the method generates a report with "MATLAB Test Report"
% as the title. You can use any of the input argument combinations in the
% previous syntaxes.
%
% Examples:
%
%     runner = testrunner;
%     results = runner.run(suite);
%     generateDOCXReport(results)
%
%     runner = testrunner;
%     results = runner.run(suite);
%     generateDOCXReport(results,"report.docx")
%
%     runner = testrunner;
%     results = runner.run(suite);
%     generateDOCXReport(results,"report.docx",PageOrientation="landscape")

% Copyright 2021-2024 The MathWorks, Inc
function generateDOCXReport(results,fileName,namedArgs)
arguments
    results matlab.unittest.TestResult
    fileName string {mustBeTextScalar} = [tempname() '.docx'];
    namedArgs.PageOrientation string {mustBeTextScalar,mustBeMember(namedArgs.PageOrientation,{'landscape','portrait'})} = 'portrait';
    namedArgs.Title
end

testSessionData = matlab.unittest.internal.createTestSessionData(results);
namedArgsCell = namedargs2cell(namedArgs);
matlab.unittest.internal.generateDOCXReportUsingTestSessionData(testSessionData,fileName,...
    namedArgsCell{:});
end
