function packagedName = makePackagedName(packageName, className)
    if packageName == ""
        packagedName = className;
    else
        packagedName = append(packageName, '.', className);
    end
end

%   Copyright 2007-2020 The MathWorks, Inc.
