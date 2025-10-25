% Return the header display string for matlab.mpm.Repository

%   Copyright 2024 The MathWorks, Inc.
function ret = getHeader(obj, offList)
    if nargin == 2 && offList
        ret = replace(getHeader@matlab.mixin.CustomDisplay(obj), "Repository", "Off-List Repository");
    else
        ret = getHeader@matlab.mixin.CustomDisplay(obj);
    end
end

