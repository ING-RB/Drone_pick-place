function propgroup = getPropertyGroupsForDisplay(obj)
% Return matlab.mixin.util.PropertyGroup for display

% Copyright 2024 The MathWorks, Inc.

    if ~obj.IsValid
        propgroup = matlab.mixin.util.PropertyGroup.empty;
        return;
    end

    packageDefTitle = "<strong>Package Definition</strong>";
    packageDefProperties = struct("Name", obj.Name, "DisplayName", obj.DisplayName, ...
        "Version", obj.Version, "Summary", obj.Summary, "Description", obj.Description, ...
        "Provider", obj.Provider, "Folders", obj.Folders, ...
        "Dependencies", matlab.mpm.internal.getDependenciesDisplayString(obj.Dependencies, false), ...
        "ReleaseCompatibility", obj.ReleaseCompatibility, "FormerNames", obj.FormerNames, ...
        "ID", obj.ID);

    installInfoTitle = "<strong>Package Installation</strong>";
    installInfoProperties = struct("Installed", obj.Installed, "Editable", obj.Editable, ...
        "InstalledAsDependency", obj.InstalledAsDependency, "PackageRoot", obj.PackageRoot, ...
        "InstalledDependencies", ...
        matlab.mpm.internal.getDependenciesDisplayString(obj.InstalledDependencies, true), ...
        "MissingDependencies", ...
        matlab.mpm.internal.getDependenciesDisplayString(obj.MissingDependencies, false));

    repoInfoTitle = "<strong>Repository</strong>";
    repoInfoProperties = ["Repository"];


    packageDefGrp = matlab.mixin.util.PropertyGroup(packageDefProperties, packageDefTitle);
    installInfoGrp = matlab.mixin.util.PropertyGroup(installInfoProperties, installInfoTitle);
    repoInfoGrp = matlab.mixin.util.PropertyGroup(repoInfoProperties, repoInfoTitle);

    propgroup = [packageDefGrp, installInfoGrp, repoInfoGrp];
end

