function services = codeIssuesResultsExtensionServices()
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023 The MathWorks, Inc.

import matlab.buildtool.internal.services.codeanalysis.SARIFResultsService
import matlab.buildtool.internal.services.codeanalysis.MATFileResultsService

services = [SARIFResultsService MATFileResultsService];
end

