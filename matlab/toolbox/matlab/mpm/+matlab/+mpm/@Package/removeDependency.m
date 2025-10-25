function removeDependency(pkg, deps)
    arguments
        pkg (1,1) matlab.mpm.Package
        deps (1,:) {matlab.mpm.internal.mustBeValidDependencyType}
    end

    try
        matlab.mpm.internal.removeDependenciesFromPackage(pkg, deps);
    catch ex
        throw(ex);
    end

end

%   Copyright 2024 The MathWorks, Inc.
