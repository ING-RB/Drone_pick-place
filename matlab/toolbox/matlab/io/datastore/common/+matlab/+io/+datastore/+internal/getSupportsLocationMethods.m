function supportsLocationMethods = getSupportsLocationMethods(packagedDatastoreName)
% getSupportsLocationMethods   This function returns the name of the
% supportsLocation function for each provided datastoreName/fileBased pair.

%   Copyright 2022 The MathWorks, Inc.

    supportsLocationMethods = cell(1, length(packagedDatastoreName));

    % File based datastores contain supportsLocation methods directly in
    % the classes.
    supportsLocationMethods = strcat(packagedDatastoreName, '.supportsLocation');

    % DatabaseDatastore validation exists in:
    % matlab.io.datastore.internal.validators.DatabaseDatastore.supportsLocation
    % to prevent checking out a Datastore Toolbox license when validating 
    % locations.
    databaseDatastoreIndex = contains(packagedDatastoreName, 'DatabaseDatastore');
    supportsLocationMethods{databaseDatastoreIndex} = ...
        'matlab.io.datastore.internal.validators.DatabaseDatastore.supportsLocation';
end