function generateDOCXReportUsingTestSessionData(testSessionData, fileName, options)
%

%   Copyright 2024 The MathWorks, Inc.

arguments
    testSessionData matlab.unittest.internal.TestSessionData
    fileName string {mustBeTextScalar} = [tempname() '.docx'];
    options.PageOrientation string {mustBeTextScalar,mustBeMember(options.PageOrientation,{'landscape','portrait'})} = 'portrait';
    options.Title
end
import matlab.unittest.internal.plugins.testreport.DOCXTestReportDocument;
import matlab.unittest.internal.newFileResolver;

reportFile = newFileResolver(fileName,'.docx');
reportArgs = namedargs2cell(options);
reportDocument = DOCXTestReportDocument(reportFile, testSessionData, reportArgs{:});
reportDocument.generateReport();
end
