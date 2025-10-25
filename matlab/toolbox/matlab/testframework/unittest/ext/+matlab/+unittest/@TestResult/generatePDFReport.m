% generatePDFReport - Generate PDF report from test results
%
% generatePDFReport(results) generates a PDF report from the test results
% and stores it in a temporary folder.
%
% generatePDFReport(results,pdfFile) saves the report to the file
% pdfFile.
%
% generatePDFReport(...,PageOrientation=Value) generates a report with the
% specified orientation. You can specify PageOrientation as "portrait" or
% "landscape". By default, the method generates a report with portrait
% orientation.
%
% generatePDFReport(...,Title=Value) generates a report with the
% specified title. You can specify Title as a string scalar or character vector.
% By default, the method generates a report with "MATLAB Test Report"
% as the title. You can use any of the input argument combinations in the
% previous syntaxes.
%
% Examples:
%
%     runner = testrunner;
%     results = runner.run(suite);
%     generatePDFReport(results)
%
%     runner = testrunner; 
%     results = runner.run(suite);
%     generatePDFReport(results,"report.pdf")
%
%     runner = testrunner; 
%     results = runner.run(suite);
%     generatePDFReport(results,"report.pdf",PageOrientation="landscape")

% Copyright 2021-2024 The MathWorks, Inc
function generatePDFReport(results,fileName,namedArgs)
arguments
    results  matlab.unittest.TestResult
    fileName string {mustBeTextScalar} = [tempname() '.pdf'];
    namedArgs.PageOrientation string {mustBeTextScalar,mustBeMember(namedArgs.PageOrientation,{'landscape','portrait'})} = 'portrait';
    namedArgs.Title
end
testSessionData = matlab.unittest.internal.createTestSessionData(results);
namedArgsCell = namedargs2cell(namedArgs);
matlab.unittest.internal.generatePDFReportUsingTestSessionData(testSessionData,fileName,...
    namedArgsCell{:});
end
