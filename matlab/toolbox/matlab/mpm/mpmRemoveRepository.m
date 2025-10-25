function mpmRemoveRepository(location)

    arguments
        location (1,:)
    end

    if ~isa(location, 'matlab.mpm.Repository')
        location = convertCharsToStrings(location);
    end

    try
        matlab.mpm.internal.removePackageRepositoryHelper(location);
    catch exception
        throw(exception);
    end

end

%   Copyright 2023-2024 The MathWorks, Inc.
