% Comapres two matlab.mpm.Package scalar objects for equality.
%
%   Two Package objects are equal if either they both have same PackageRoot
%   or if PackageRoot is missing, they both have same ID and Version and
%   comes from same Repository.

% Copyright 2024 The MathWorks, Inc.

function isEq = eq(pkg, otherPkg)
    pkgClass = 'matlab.mpm.Package';
    pkgType = whos('pkg').class;
    if strcmp(pkgType, pkgClass) ~= 1
        error(message('mpm:core:ComparisonNotDefined', pkgType, pkgClass));
    end
    otherPkgType = whos('otherPkg').class;
    if strcmp(otherPkgType, pkgClass) ~= 1
        error(message('mpm:core:ComparisonNotDefined', otherPkgType, pkgClass));
    end

    isScalarPkg = isscalar(pkg); isScalarOther = isscalar(otherPkg);

    if (isScalarPkg  && isScalarOther)
        isEq = compareScalar(pkg,otherPkg);
    elseif (isScalarPkg && ~isScalarOther)
        isEq = compareNonScalarWithScalar(otherPkg, pkg);
    elseif(isScalarOther && ~isScalarPkg)
        isEq = compareNonScalarWithScalar(pkg, otherPkg);
    elseif (size(pkg) == size(otherPkg))
        isEq = false(size(pkg));
        for i = 1:numel(pkg)
            isEq(i) = compareScalar(pkg(i), otherPkg(i));
        end
    else
        error(message('MATLAB:sizeDimensionsMustMatch'));
    end
end

function r = compareScalar(pkg, otherPkg)
    if ~ismissing(pkg.PackageRoot) || ~ismissing(otherPkg.PackageRoot)
        r = pkg.PackageRoot == otherPkg.PackageRoot;
    elseif ~isempty(pkg.Repository) || ~isempty(otherPkg.Repository)
        r = (pkg.ID == otherPkg.ID && pkg.Version == otherPkg.Version ...
        && pkg.Repository.Location == otherPkg.Repository.Location);
    else
        r = false;
    end
end

function r = compareNonScalarWithScalar(nonScalar, scalar)
    r = false(size(nonScalar));
    for i = 1:numel(nonScalar)
        r(i) = compareScalar(nonScalar(i), scalar);
    end
end 


