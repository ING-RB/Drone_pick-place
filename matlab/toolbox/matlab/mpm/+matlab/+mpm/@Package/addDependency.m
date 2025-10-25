function addDependency(package, dependencies)
    arguments
        package (1,1) matlab.mpm.Package
        dependencies (1,:) {matlab.mpm.internal.mustBeValidDependencyType}
    end

    try
        matlab.mpm.internal.addDependenciesToPackage(package, dependencies);
    catch ex
        throw(ex);
    end

end

%   Copyright 2024 The MathWorks, Inc.
