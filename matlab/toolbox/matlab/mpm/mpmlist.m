function pkgout = mpmlist(keyword, opts)

    arguments
        % Argument
        keyword (1, 1) string = missing;

        % Options: Pattern filter(s)
        opts.Name (1, 1) pattern
        opts.DisplayName (1, 1) pattern

        % Options: Filters
        opts.VersionRange (1, 1) string
        opts.ID (1, 1) string
        opts.PackageSpecifier (1, 1) string
        opts.Provider (1, 1) {matlab.mpm.internal.mustBeScalarTextOrType(opts.Provider, "matlab.mpm.Provider")}
        opts.CompatibleWithRelease {matlab.mpm.internal.mustBeScalarTextOrType(opts.CompatibleWithRelease,"matlabRelease")}
        opts.Location (1, 1) string {mustBeFolder}
    end

    if strcmp(keyword,"")
        error(message("mpm:arguments:ValueMustBeNonEmptyScalarText", "keyword"));
    end

    if isfield(opts, "CompatibleWithRelease")
        opts.CompatibleWithRelease = matlab.mpm.internal.convertToReleaseString(opts.CompatibleWithRelease);
    end

    try
        pkg = matlab.mpm.internal.mpmListHelper(opts, keyword);
    catch ex
        throw(ex);
    end

    pkg = pkg(matlab.mpm.internal.applyPatternFilters(pkg, opts));

    if (nargout == 0)
        createDisplay(pkg);
    else
        pkgout = pkg;
    end

end

function createDisplay(pkg)
    if numel(pkg) == 0
        disp(message("mpm:resolution:NoMatchingPackages").string())
    else
        matlab.mpm.internal.displayPackagesAsTable(pkg, ["Name", ...
                                                         "Version", "Editable", "InstalledAsDependency"], ...
                                                   ["string", "string", "logical", "logical"]);
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
