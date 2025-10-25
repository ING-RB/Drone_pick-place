function suiteHandlers = getInformalSuiteHandlers
% getInformalSuiteHandlers - Returns the array of handlers for informal suite creation
%   The function is responsible for locating specialized handlers using
%   services and then constructing the ordered array of handlers.
%
%   See also: Handler, HandlerService, HandlerLiaison

% Copyright 2022-2023 The MathWorks, Inc.

import matlab.automation.internal.services.ServiceLocator;
import matlab.unittest.internal.services.ServiceFactory;
import matlab.unittest.internal.services.informalsuite.HandlerLiaison;
import matlab.unittest.internal.services.informalsuite.NameHandler;
import matlab.unittest.internal.services.informalsuite.ParentNameProcedureNameHandler;
import matlab.unittest.internal.services.informalsuite.ParentNameHandler;
import matlab.unittest.internal.services.informalsuite.MATLABCodeFileHandler;
import matlab.unittest.internal.services.informalsuite.NamespaceHandler;
import matlab.unittest.internal.services.informalsuite.FolderHandler;

% Locate any specialized suite handlers
namespace = "matlab.unittest.internal.services.informalsuite";
interface = ?matlab.unittest.internal.services.informalsuite.HandlerService;
classes = ServiceLocator.forNamespace(meta.package.fromName(namespace)).locate(interface);
liaison = HandlerLiaison;
ServiceFactory.create(classes).fulfill(liaison);
locatedHandlers = liaison.Handlers;

% Add the base handlers
allHandlers = [locatedHandlers, ...
    NameHandler, ...
    ParentNameProcedureNameHandler, ...
    ParentNameHandler, ...
    MATLABCodeFileHandler, ...
    NamespaceHandler, ...
    FolderHandler];

% Sort the located handlers into the right places within the base handlers
precedence = [allHandlers.Precedence];
[~, idx] = sort(precedence);
suiteHandlers = allHandlers(idx);
end
