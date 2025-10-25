function coverageMetricsServices = locateCoverageReportMetricServices
% This function is undocumented and may change in a future release.

% Copyright 2022-2023 The MathWorks, Inc.

import matlab.unittest.internal.services.coverage.MATLABCoverageMetricsService
import matlab.automation.internal.services.ServiceLocator
import matlab.unittest.internal.services.ServiceFactory
namespace = "matlab.unittest.internal.services.coverage.located";
locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
serviceClass = ?matlab.unittest.internal.services.coverage.CoverageMetricsService;
locatedServiceClasses = locator.locate(serviceClass);
locatedServices = ServiceFactory.create(locatedServiceClasses);
coverageMetricsServices = [MATLABCoverageMetricsService(); ...
    locatedServices];

end
