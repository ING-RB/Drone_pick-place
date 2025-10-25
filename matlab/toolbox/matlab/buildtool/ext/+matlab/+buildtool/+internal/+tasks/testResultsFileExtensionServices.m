function services = testResultsFileExtensionServices()
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023 The MathWorks, Inc.

import matlab.buildtool.internal.services.testresult.MATFileTestResultsExtensionService
import matlab.buildtool.internal.services.testresult.JUnitXMLTestResultsExtensionService
import matlab.buildtool.internal.services.testresult.PDFTestReportExtensionService
import matlab.buildtool.internal.services.testresult.HTMLTestReportExtensionService
import matlab.buildtool.internal.services.testresult.MLDATXTestResultsExtensionService

services = [MATFileTestResultsExtensionService JUnitXMLTestResultsExtensionService PDFTestReportExtensionService HTMLTestReportExtensionService MLDATXTestResultsExtensionService];

end
