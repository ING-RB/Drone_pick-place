function installed = isInstalled
%

%   Copyright 2023 The MathWorks, Inc.


if matlab.internal.doc.services.DocLocation.getActiveLocation == matlab.internal.doc.services.DocLocation.INSTALLED
    installed = true;
else
    docCenterDomain = matlab.internal.doc.getDocCenterDomain;
    baseURL = matlab.net.URI(docCenterDomain);
    p = (textBoundary("start") | ".") + "mathworks.com" + textBoundary("end");
    installed = ~contains(baseURL.Host, p);
end
