function [result, errorMsg] = addCustomPackageRepositoryConnection(model)
%

%   Copyright 2024 The MathWorks, Inc.
    try
        name = model.('mw_customPackageRepositoryConnectionType_fields_Name');
        location = model.('mw_customPackageRepositoryConnectionType_fields_Path');
        repo = mpmAddRepository(name, location);
        matlab.internal.addons.Sidepanel.addPackagesFromCustomRepositoriesToPanel();
        result = repo.Name;
        errorMsg = '';
    catch ME
        result = '';
        errorMsg = '';
        if ~isempty(ME.cause)
            switch ME.cause{1}.identifier
                case 'mpm:repository:RepositoryNameAlreadyExists'
                    errorMsg = getString(message('matlab_addons:customRepositoryConnection:repositoryNameAlreadyExistsError'));
                case 'mpm:repository:RepositoryLocationAlreadyExists'
                    errorMsg = getString(message('matlab_addons:customRepositoryConnection:repositoryLocationAlreadyExistsError'));
                otherwise
                    errorMsg = ME.cause{1}.message;
            end
        else
            switch ME.identifier
                case 'mpm:arguments:MustBeFolder'
                    errorMsg = getString(message('matlab_addons:customRepositoryConnection:repositoryPathInvalidError'));
                otherwise
                    errorMsg = ME.message;
            end
        end
    end
end