function stack = trimStackEnd(stack)
% This function is undocumented.

%  Copyright 2013-2023 The MathWorks, Inc.

import matlab.automation.internal.services.ServiceLocator;
import matlab.unittest.internal.services.ServiceFactory;
import matlab.unittest.internal.services.stacktrimming.StackTrimmingLiaison;
import matlab.unittest.internal.services.stacktrimming.CoreFrameworkStackTrimmingService;

namespace = "matlab.unittest.internal.services.stacktrimming.located";
locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
cls = ?matlab.unittest.internal.services.stacktrimming.StackTrimmingService;
locatedServiceClasses = locator.locate(cls);
locatedServices = ServiceFactory.create(locatedServiceClasses);

% Trim the stack from below the desired frame(s)
liaison  = StackTrimmingLiaison(stack);
services = [CoreFrameworkStackTrimmingService; locatedServices];
trimEnd(services, liaison);
stack = liaison.Stack;

end

% LocalWords:  stacktrimming cls
