function p = listPackages
    p = [];
    if matlab.internal.feature('mpm')
        list = mpmlist;
        p = [list.Name];
    end
end

%   Copyright 2024 The MathWorks, Inc.
