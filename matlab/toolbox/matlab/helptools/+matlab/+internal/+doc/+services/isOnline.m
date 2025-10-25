function online = isOnline
    docCenterLocation = matlab.internal.doc.services.DocLocation.getActiveLocation;
    online = (string(docCenterLocation) == "WEB");
end

% Copyright 2021-2022 The MathWorks, Inc.
