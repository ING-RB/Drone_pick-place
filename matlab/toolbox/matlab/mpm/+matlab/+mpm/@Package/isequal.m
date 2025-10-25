%

%   Copyright 2024 The MathWorks, Inc.
function ret = isequal(pkg, otherPkg)
    if ~isequal(size(pkg), size(otherPkg))
        ret = false;
        return;
    end

    pkgClass = 'matlab.mpm.Package';
    pkgType = whos('pkg').class;
    if strcmp(pkgType, pkgClass) ~= 1
        ret = false;
        return;
    end
    otherPkgType = whos('otherPkg').class;
    if strcmp(otherPkgType, pkgClass) ~= 1
        ret = false;
        return;
    end

    ret = all(eq(pkg, otherPkg));
end
