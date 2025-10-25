function type = getTypeFromPackageInfoUrl(identifier,addOnVersion)
% An internal function that returns the add-on type of the update from
% packageUrl using FileExchangeRepositoryClient API

% Copyright 2020-2022 The MathWorks, Inc.


    fileExchangerepoUrlGenerator = matlab.addons.repositories.FileExchangeRepositoryUrlGenerator;
    packageUrl = fileExchangerepoUrlGenerator.addonPackagesUrl(identifier, addOnVersion);
    fileExchangeRepositoryClient = matlab.internal.addons.updates.fileexchangeaddon.getFileExchangeRepositoryClient;
    try
        packageMetadata = fileExchangeRepositoryClient.get(packageUrl);
    catch exception
        % Do not throw any exception since it shows up on cmd on MATLAB
        % startup: Ref: g2398851
        % Figure out if there is a way to log the exception in a log file.
        type = '';
        return;
    end

    if ~isfield(packageMetadata, "packages")
        % Do not throw any exception since it shows up on cmd on MATLAB
        % startup: Ref: g2398851
        % Figure out if there is a way to log the exception in a log file.
        type = '';
        return;
    end

    packages = packageMetadata.packages;

    if isempty(packages)
        % There are no installable packages for the given id and version
        type = '';
        return;
    end

    if  ~isfield(packages, "type") || ~isfield(packages, "url")
        % Do not throw any exception since it shows up on cmd on MATLAB
        % startup: Ref: g2398851
        % Figure out if there is a way to log the exception in a log file.
        type = '';
        return;
    end
        
    % If there exist package metadata with type set to "mltbx", return
    % "toolbox" as the type
    tbx = packages(strcmp({packages.type}, "mltbx"));
    if ~isempty(tbx)
        type = 'toolbox';
    else
        type = packages.type;
    end    
end
