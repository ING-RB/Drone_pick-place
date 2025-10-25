% Return the footer display string for matlab.mpm.Repository

%   Copyright 2024 The MathWorks, Inc.
function ret = getFooter(obj, offList)
    if nargin == 2 && offList
        ret = "  Add a repository with Location """ + obj.Location + """ to use this object.";
    else
        ret = getFooter@matlab.mixin.CustomDisplay(obj);
    end
end

