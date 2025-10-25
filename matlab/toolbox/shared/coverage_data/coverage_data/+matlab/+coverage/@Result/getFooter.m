%

%   Copyright 2023 The MathWorks, Inc.

function footerStr = getFooter(resObj)

namespace = "matlab.coverage.internal.services";
interfaceClass = ?matlab.coverage.internal.ResultFooterService;

locator = matlab.automation.internal.services.ServiceLocator.forNamespace(meta.package.fromName(namespace));
locatedServiceClasses = locator.locate(interfaceClass);
footerServices = matlab.automation.internal.services.ServiceFactory.create(locatedServiceClasses);
if ~isempty(footerServices)
    % Use only one!
    footerStr = char(footerServices(1).getFooter(resObj, inputname(1)));
else
    footerStr = '';
end

