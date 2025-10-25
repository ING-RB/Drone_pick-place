function repo = mpmAddRepository(name, location, nameValue)

    arguments
        name (:, 1)
        location (:, 1) string  = string(missing)
        nameValue.Position (1, 1) matlab.mpm.internal.PositionChoices = matlab.mpm.internal.PositionChoices("end")
    end 

    % mpmAddRepository accepts one argument if arg is matlab.mpm.Repository, otherwise two arguments
    if ~isa(name, "matlab.mpm.Repository") & any(ismissing(location))
        error(message("mpm:repository:RepositoryLocationRequired"));
    end

    name = convertCharsToStrings(name);

    % Convert string to enum
    nameValue.Position = matlab.mpm.internal.Position(nameValue.Position.Flag);

    try
        repo = matlab.mpm.internal.addPackageRepositoryHelper(name, location, nameValue);
    catch exception
        throw(exception);
    end

    if nargout == 0
        matlab.mpm.internal.displayReposAsTable(repo);
        clear repo;
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
