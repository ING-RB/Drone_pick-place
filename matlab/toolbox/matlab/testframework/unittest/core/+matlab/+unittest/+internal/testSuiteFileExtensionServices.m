function services = testSuiteFileExtensionServices()
% This function is undocumented and may change in a future release.

% Copyright 2018-2023 The MathWorks, Inc.

import matlab.unittest.internal.services.fileextension.MLXFileExtensionService;
import matlab.unittest.internal.services.fileextension.PFileExtensionService;
import matlab.unittest.internal.services.fileextension.MFileExtensionService;
import matlab.unittest.internal.services.fileextension.FileExtensionLiaison;

namespace = "matlab.unittest.internal.services.fileextension.located";
interfaceClass = ?matlab.unittest.internal.services.fileextension.FileExtensionService;
locatedServices = locateAndCreateServices(namespace,interfaceClass);

services = [MFileExtensionService; PFileExtensionService; MLXFileExtensionService; locatedServices];
end

function services = locateAndCreateServices(namespace, interfaceClass)
import matlab.automation.internal.services.ServiceLocator;
import matlab.unittest.internal.services.ServiceFactory;
locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
locatedServiceClasses = locator.locate(interfaceClass);
services = ServiceFactory.create(locatedServiceClasses);
end

% LocalWords:  fileextension MLX PFile MFile
