classdef PackageSpecifier < matlab.mpm.PackageSpecifierBase

    methods
        function obj = PackageSpecifier(packageSpec, opts)
            arguments
                packageSpec (1,1) string {mustBeNonmissing}
                opts.VersionRange (1,1) string {mustBeNonmissing}
                opts.ID (1,1) string {mustBeNonmissing}
            end

            specParts = strsplit(packageSpec, "@", CollapseDelimiters=false);

            if (numel(specParts) > 3 || numel(specParts) < 1)
                error(message("mpm:arguments:InvalidPackageSpecifier", ...
                              packageSpec, "The package specifier must be in name@version-range@id format."));
            end

            specParts = resize(specParts, [1,3], FillValue="");

            if (isfield(opts, "VersionRange"))
                if specParts(2) ~= "" && opts.VersionRange ~= specParts(2)
                    error("MATLAB:PackageSpecifier:ConflictingVersionRange", "Conflicting VersionRange in specified string with NV arg");
                end
                specParts(2) = opts.VersionRange;
            end

            if (isfield(opts, "ID"))
                if specParts(3) ~= "" && opts.ID ~= specParts(3)
                    error("MATLAB:PackageSpecifier:ConflictingID", "Conflicting ID in specified string with NV arg");
                end
                specParts(3) = opts.ID;
            end
            obj@matlab.mpm.PackageSpecifierBase(strjoin(specParts, "@"));
        end
    end
end

%   Copyright 2024 The MathWorks, Inc.
