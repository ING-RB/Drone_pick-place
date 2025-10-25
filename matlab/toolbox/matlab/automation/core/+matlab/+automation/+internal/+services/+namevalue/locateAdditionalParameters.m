function nameValueLiaison = locateAdditionalParameters(interface, packageNames, parser)
% This function is undocumented and may change in a future release.

% locateAdditionalParameters - Dynamically locate parameters to be added to inputParser
%
%   locateAdditionalParameters(INTERFACE, PACKAGENAME, PARSER) locates
%   only those parameters provided by services deriving from the specified
%   INTERFACE and residing under the specified PACKAGENAME.
%
% See also: matlab.automation.services.namevalue.NameValueProviderService

% Copyright 2018-2023 The MathWorks, Inc.

import matlab.automation.internal.services.ServiceLocator
import matlab.automation.internal.services.ServiceFactory
import matlab.automation.internal.services.namevalue.NameValueProviderLiaison;

nameValueLiaison = NameValueProviderLiaison(parser);

for pkgName = packageNames
    package = meta.package.fromName(pkgName);
    serviceClassesWithInterface = ServiceLocator.forNamespace(package).locate(interface);
    nameValueServices = ServiceFactory().create(serviceClassesWithInterface);
    nameValueServices.fulfill(nameValueLiaison);
end
end

% LocalWords:  PACKAGENAME
