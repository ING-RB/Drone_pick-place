function setDebugProjectDoc(value)
%

%   Copyright 2022 The MathWorks, Inc.

    s = settings;
    debugProjectDoc = s.matlab.help.DebugProjectDoc;

    if (value)
        debugProjectDoc.TemporaryValue = true;
    elseif debugProjectDoc.hasTemporaryValue
        debugProjectDoc.clearTemporaryValue;
    end
end