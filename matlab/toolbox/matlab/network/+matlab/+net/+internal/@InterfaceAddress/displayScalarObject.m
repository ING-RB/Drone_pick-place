function displayScalarObject(intfAddress)
%

%   Copyright 2020 The MathWorks, Inc.

    fprintf("%s - %s\n", matlab.mixin.CustomDisplay.getClassNameForHeader(intfAddress), string(intfAddress));
end
