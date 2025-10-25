function updateDependency(package, dependenciesToUpdate, versionRange)
    arguments
        package (1,1) matlab.mpm.Package
        dependenciesToUpdate (1,:) string
        versionRange (1,:) string
    end

    if(~isequal(size(dependenciesToUpdate), ...
                size(versionRange)))
        error(message("mpm:arguments:MustBeSameSize", "Dependency", "Version"));
    end
    if(isempty(package.Dependencies))
        error("mpm:arguments:DependencyUpdateNotSupported", message("mpm:arguments:EmptyDependencies").string());
    end
    if(~ismissing(versionRange))
        for i = 1:length(dependenciesToUpdate)
            index = ismember([package.Dependencies.Name], ...
                             dependenciesToUpdate(i));
            if(index == 0)
                error(message("mpm:arguments:DependencyUpdateNotSupported", ...
                              dependenciesToUpdate(i)));
            else
                package.Dependencies(index).VersionRange = versionRange(i);
            end
        end
    end
end

%   Copyright 2024 The MathWorks, Inc.
