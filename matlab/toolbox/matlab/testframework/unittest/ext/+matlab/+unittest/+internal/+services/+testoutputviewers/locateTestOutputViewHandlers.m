function liaison = locateTestOutputViewHandlers(options)
% This function is undocumented and may change in a future release.

% locateTestOutputViewHandlers - Dynamically locate UI runners to run tests instead of
% the CLI
%
%   locateTestOutputViewHandlers(INTERFACE, NAMESPACE, PARSER) locates
%   only those Test Output View Handlers provided by services deriving from the specified
%   INTERFACE and residing under the specified NAMESPACE.
%
% See also: matlab.unittest.internal.services.testoutputviewers.TestOutputViewService

% Copyright 2023 The MathWorks, Inc.

import matlab.automation.internal.services.ServiceLocator
import matlab.automation.internal.services.ServiceFactory
import matlab.unittest.internal.services.testoutputviewers.TestOutputViewLiaison;

liaison = TestOutputViewLiaison(options);

interface = ?matlab.unittest.internal.services.testoutputviewers.TestOutputViewService;
namespace = "matlab.unittest.internal.services.testoutputviewers.runtests";

namespaceMetadata = meta.package.fromName(namespace);
serviceClassesWithInterface = ServiceLocator.forNamespace(namespaceMetadata).locate(interface);
services = ServiceFactory().create(serviceClassesWithInterface);
services.fulfill(liaison);

end