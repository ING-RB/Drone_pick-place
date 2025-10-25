function pkgs = mpminstall(packageSpec, opts)

    arguments
        % Argument
        packageSpec

        % Options: Interactivity
        opts.Prompt (1, 1) logical = true
        opts.Verbosity (1,1) matlab.mpm.Verbosity = matlab.mpm.Verbosity.normal

        % Options: Dependency
        opts.InstallDependencies (1,1) logical = true
        opts.Force (1,1) logical = false

        % Options: Conflict
        opts.AllowVersionReplacement (1,1) logical = false

        % Options : Access control
        opts.Temporary (1,1) logical = false

        % Options: Authoring
        opts.Authoring (1,1) logical
        opts.InPlace (1,1) logical
        opts.Editable (1,1) logical
        opts.PathPosition (1,1) matlab.mpm.internal.PositionChoices

    end   

    % Convert Temporary flag to AccessLevel
    opts.AccessLevel = matlab.mpm.internal.AccessLevel.User;
    if opts.Temporary
        opts.AccessLevel = matlab.mpm.internal.AccessLevel.Temporary;
    end
    opts = rmfield(opts, "Temporary");


    if isfield(opts, "Authoring")
        % Error if Authoring is used with any of InPlace, Editable, or PathPosition
        if isfield(opts, "InPlace") || isfield(opts, "Editable") || isfield(opts, "PathPosition")
            error(message("mpm:arguments:UnsupportedAuthoringOption"));
        end
    else
        opts.Authoring = false;
    end

    if opts.Authoring
        % Set authoring flags
        opts.InPlace = true;
        opts.Editable = true;
        opts.PathPosition = matlab.mpm.internal.PositionChoices("beginning");
    end

    % Delete Authoring
    opts = rmfield(opts, "Authoring");

    % Set defaults for InPlace, Editable and PathPosition
    opts = SetDefaultOption(opts, "InPlace", false);
    opts = SetDefaultOption(opts, "Editable", false);
    opts = SetDefaultOption(opts, "PathPosition", matlab.mpm.internal.PositionChoices("end"));

    % Convert string to enum
    opts.PathPosition = matlab.mpm.internal.Position(opts.PathPosition.Flag);

    try
        out = matlab.mpm.internal.mpmInstallHelper(opts, packageSpec);
    catch ex
        throw(ex);
    end

    if nargout ~= 0
        pkgs = out;
    end

    rehash;

end

function opts = SetDefaultOption(opts, name, value)

    if ~isfield(opts, name)
        opts.(name) = value;
    end

end

%   Copyright 2023-2024 The MathWorks, Inc.
