function generateHTMLReportUsingTestSessionData(testSessionData,fileOrFolder,options)
%

%   Copyright 2024 The MathWorks, Inc.

arguments
    testSessionData matlab.unittest.internal.TestSessionData
    fileOrFolder {mustBeTextScalar} = tempname()
    options.MainFile {mustBeTextScalar}
    options.Title
end
import matlab.unittest.internal.plugins.testreport.HTMLTestReportDocument;
reportArgs = namedargs2cell(options);
[reportArgs, mainFileArgs, remainingArgs] = matlab.unittest.internal.resolveStandaloneReportInputs(fileOrFolder, reportArgs{:});
reportDocument = HTMLTestReportDocument(reportArgs.reportFolder, testSessionData, ...
                                        reportArgs.standaloneTestReport, mainFileArgs{:}, ...
                                        remainingArgs{:});
reportDocument.generateReport();
end
