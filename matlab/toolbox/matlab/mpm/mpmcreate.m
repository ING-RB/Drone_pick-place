function pkg = mpmcreate(name,location,opts)

    arguments
        name {mustBeTextScalar, mustBeNonzeroLengthText};
        location {mustBeTextScalar, mustBeNonzeroLengthText};
        opts.DisplayName {mustBeTextScalar};
        opts.Version {matlab.mpm.internal.mustBeScalarTextOrType(opts.Version, "matlab.mpm.Version")} = "1.0.0";
        opts.ID {mustBeTextScalar};
        opts.Provider (1,1) matlab.mpm.Provider = matlab.mpm.Provider();
        opts.Summary  {mustBeTextScalar}= "";
        opts.Description {mustBeTextScalar}= "";
        opts.ReleaseCompatibility {matlab.mpm.internal.mustBeScalarTextOrType(opts.ReleaseCompatibility,"matlabRelease")} = "";
        opts.IncludeSubFolders (1,1) logical = true;
        opts.Install (1,1) logical = true;
    end

    opts.Name = name;
    if ~isfield(opts,"DisplayName")
        opts.DisplayName = opts.Name;
    end

    if isa(opts.ReleaseCompatibility, "matlabRelease")
        opts.ReleaseCompatibility = matlab.mpm.internal.convertToReleaseString(opts.ReleaseCompatibility);
    end

    try
        matlab.mpm.internal.createPackageHelper(location, opts)
    catch ex
        throw(ex);
    end

    if opts.Install
        try
            pkg = mpminstall(location,Authoring=true, Prompt=false, Verbosity="quiet");
        catch ME
            warning(message("mpm:create:CreationSucceededInstallFailed",fullfile(location,"resources")));
            pkg = matlab.mpm.Package(location);
        end
    else
        pkg = matlab.mpm.Package(location);
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
