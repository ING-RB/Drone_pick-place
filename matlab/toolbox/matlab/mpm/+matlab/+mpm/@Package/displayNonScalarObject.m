function displayNonScalarObject(obj)
    disp(getHeader(obj))
    matlab.mixin.CustomDisplay.displayPropertyGroups(obj, getPropertyGroups(obj));
    disp(getFooter(obj, inputname(1)));
end

%   Copyright 2024 The MathWorks, Inc.
