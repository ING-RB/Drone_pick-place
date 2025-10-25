function debugProjectDoc = isDebugProjectDoc
%

%   Copyright 2022 The MathWorks, Inc.

    s = settings;
    debugProjectDoc = s.matlab.help.DebugProjectDoc.ActiveValue;
end
