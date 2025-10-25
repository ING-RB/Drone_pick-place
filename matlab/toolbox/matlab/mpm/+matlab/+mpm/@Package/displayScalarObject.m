function displayScalarObject(obj)
    if ~obj.IsValid
        matlab.mpm.internal.displayInaccessiblePackage(obj);
        return;
    end
    propGroups = getPropertyGroupsForDisplay(obj);
    disp(getHeader(obj))
    matlab.mixin.CustomDisplay.displayPropertyGroups(obj, propGroups);
    disp(getFooter(obj, inputname(1)))
end

%   Copyright 2024 The MathWorks, Inc.
