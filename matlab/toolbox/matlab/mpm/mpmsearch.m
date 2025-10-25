function pkgout = mpmsearch(keyword, opts)

    arguments
        % Argument
        keyword (1, 1) string = missing;

        % Options: Pattern filters
        opts.Name (1, 1) pattern
        opts.DisplayName (1, 1) pattern

        % Options: Filters
        opts.VersionRange (1, 1) string
        opts.VersionSelectionPolicy (1, 1) matlab.mpm.VersionSelectionPolicy
        opts.ID (1, 1) string
        opts.PackageSpecifier (1, 1) string
        opts.Provider (1, 1) {matlab.mpm.internal.mustBeScalarTextOrType(opts.Provider, "matlab.mpm.Provider")}
        opts.CompatibleWithRelease {matlab.mpm.internal.mustBeScalarTextOrType(opts.CompatibleWithRelease,"matlabRelease")}
        opts.Repository (1, :) {mustBeTextOrRepository}
    end

    % Fail if no arguments are provided
    if (nargin == 0) && isempty(fieldnames(opts))
        error(message("MATLAB:minrhs"));
    end

    if strcmp(keyword,"")
        error(message("mpm:arguments:ValueMustBeNonEmptyScalarText", "keyword"));
    end

    % Set default options for CompatibleWithRelease and VersionSelectionPolicy
    if isfield(opts, "CompatibleWithRelease")
        opts.CompatibleWithRelease = matlab.mpm.internal.convertToReleaseString(opts.CompatibleWithRelease);
    else
        opts.CompatibleWithRelease = matlabRelease.Release;
    end
    if ~isfield(opts, "VersionSelectionPolicy")
        opts.VersionSelectionPolicy = matlab.mpm.VersionSelectionPolicy.highestbyrepo;
    end

    % Ensure repository is string location
    if isfield(opts, "Repository")
        opts.Repository = convertToRepositoryNames(opts.Repository);
    end

    try
        pkg = matlab.mpm.internal.mpmSearchHelper(opts, keyword);
    catch ex
        throw(ex);
    end

    pkg = pkg(matlab.mpm.internal.applyPatternFilters(pkg, opts));

    if nargout == 0
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
                                                         "Version", "Summary"], ["string", "string", "string"]);
    end
end

function values = convertToRepositoryNames(values)
    if isa(values, "matlab.mpm.Repository")
        values = [values.Name];
    end
end

function mustBeTextOrRepository(values)
    if ~isa(values, "matlab.mpm.Repository")
        mustBeText(values)
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
