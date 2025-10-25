% generateHTMLReport - Generate HTML report from test results
%
% generateHTMLReport(results) generates an HTML report from the test
% results and stores it in a temporary folder with "index.html" as the main
% file.
%
% generateHTMLReport(results,location) saves the report to the specified
% location. You can specify location as a file or folder:
% - If you specify a file, then the method generates a single-file,
%   standalone report and saves it as the specified file.
% - If you specify a folder, then the method generates a multi-file report
%   and saves it to the specified folder with "index.html" as the main
%   report file.
%
% generateHTMLReport(...,MainFile=Value) generates a multi-file report with
% the specified name for the main HTML file:
% - If you specify a report folder using an optional positional argument,
%   then the method saves the report to the specified folder.
% - If you do not specify a report folder, then the method saves the report
%   to a temporary folder.
%
% generateHTMLReport(...,Title=Value) generates a report with the
% specified title. You can specify Title as a string scalar or character vector.
% By default, the method generates a report with "MATLAB Test Report"
% as the title. You can use any of the input argument combinations in the
% previous syntaxes.
%
% Examples:
%
%     runner = testrunner; 
%     results = runner.run(suite);
%     generateHTMLReport(results)
%
%     runner = testrunner;
%     results = runner.run(suite);
%     generateHTMLReport(results,"report.html")
%
%     runner = testrunner; 
%     results = runner.run(suite);
%     generateHTMLReport(results,"myResults",MainFile="report.html")

% Copyright 2021-2024 The MathWorks, Inc.
function generateHTMLReport(results,fileOrFolder,fileArgs)
arguments 
    results matlab.unittest.TestResult
    fileOrFolder {mustBeTextScalar} = tempname()
    fileArgs.MainFile {mustBeTextScalar}
    fileArgs.Title
end 
testSessionData = matlab.unittest.internal.createTestSessionData(results);
fileArgsCell = namedargs2cell(fileArgs);
    matlab.unittest.internal.generateHTMLReportUsingTestSessionData(testSessionData,fileOrFolder, ...
        fileArgsCell{:});
end
