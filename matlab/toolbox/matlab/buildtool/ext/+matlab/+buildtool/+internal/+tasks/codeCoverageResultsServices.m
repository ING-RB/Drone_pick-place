function services = codeCoverageResultsServices()
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023-2024 The MathWorks, Inc.

import matlab.buildtool.internal.services.codecoverage.CoberturaFormatService
import matlab.buildtool.internal.services.codecoverage.CoverageResultService
import matlab.buildtool.internal.services.codecoverage.HTMLCoverageReportService

services = [CoverageResultService CoberturaFormatService HTMLCoverageReportService locateCoverageResultsServices()];

end

function locatedServices = locateCoverageResultsServices()
arguments (Output)
    locatedServices (1,:)
end

import matlab.automation.internal.services.ServiceLocator;
import matlab.automation.internal.services.ServiceFactory;

namespace = "matlab.buildtool.internal.services.codecoverage.located";
locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
serviceClass = ?matlab.buildtool.internal.services.coverage.CoverageResultsService;

locatedServiceClasses = locator.locate(serviceClass);
locatedServices = ServiceFactory.create(locatedServiceClasses);
locatedServices = [matlab.buildtool.internal.services.coverage.CoverageResultsService.empty() locatedServices];
end
