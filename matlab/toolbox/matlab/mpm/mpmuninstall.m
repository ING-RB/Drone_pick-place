function mpmuninstall(packageSpec, opts)

    arguments
        packageSpec

        % Options: Interactivity
        opts.Prompt (1, 1) logical = true
        opts.Verbosity (1,1) matlab.mpm.Verbosity = matlab.mpm.Verbosity.normal

        % Options: Dependency
        opts.KeepUnusedDependencies (1, 1) logical = false
        opts.Force (1,1) logical = false
    end

    % Rename KeepUnusedDependencies to UninstallUnusedDependencies
    opts.UninstallUnusedDependencies = ~opts.KeepUnusedDependencies;
    opts = rmfield(opts, "KeepUnusedDependencies");

    try
        matlab.mpm.internal.mpmUninstallHelper(opts, packageSpec);
    catch ex
        throw(ex);
    end

    rehash;

end

%   Copyright 2023-2024 The MathWorks, Inc.
