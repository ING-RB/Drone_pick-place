function generatePDFReportUsingTestSessionData(testSessionData, fileName, options)
%

%   Copyright 2024 The MathWorks, Inc.

arguments
    testSessionData matlab.unittest.internal.TestSessionData
    fileName string {mustBeTextScalar} = [tempname() '.pdf'];
    options.PageOrientation string {mustBeTextScalar,mustBeMember(options.PageOrientation,{'landscape','portrait'})} = 'portrait';
    options.Title
end
import matlab.unittest.internal.plugins.testreport.PDFTestReportDocument;
import matlab.unittest.internal.newFileResolver;
reportFile = newFileResolver(fileName,'.pdf');
reportArgs = namedargs2cell(options);
reportDocument = PDFTestReportDocument(reportFile, testSessionData, reportArgs{:});
reportDocument.generateReport();
end
