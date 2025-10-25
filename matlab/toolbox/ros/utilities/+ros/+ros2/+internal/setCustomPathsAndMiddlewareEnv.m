function [resetEnvs, resetCustomAmentPrefPath, resetCustomPath, resetCustomSitePackagesPath, resetCustomLdLibraryPath] = setCustomPathsAndMiddlewareEnv(amentPrefixPath)
% setCustomPathsAndMiddlewareEnv - Set the ament prefix paths, library
% paths to generate message artifacts for the available rmw
% implementations.

% Copyright 2022 The MathWorks, Inc.

    % Append custom RMW registry list paths to PATH,
    % LD_LIBRARY_PATH, AMENT_PREFIX_PATH, PYTHONPATH
    % environment variables
    if nargin<1
        customAmentPrefixPath = '';
    else
        customAmentPrefixPath = amentPrefixPath;
    end
    customPath = '';
    customSitePackagesPath = '';
    customLDLibraryPath = '';

    customRMWReg = ros.internal.CustomRMWRegistry.getInstance();
    customRMWRegList = customRMWReg.getRMWList();
    for i=1:numel(customRMWRegList)
        rmwInfo = customRMWReg.getRMWInfo(customRMWRegList{i});
        if ~isempty(rmwInfo.installDir)
            customAmentPrefixPath = [rmwInfo.installDir, pathsep, customAmentPrefixPath]; %#ok<AGROW>
            customPath = [fullfile(rmwInfo.installDir,'bin'), pathsep, customPath]; %#ok<AGROW>
            if ispc
                customSitePackagesPath = [fullfile(rmwInfo.installDir,'lib','site-packages'), pathsep, customSitePackagesPath]; %#ok<AGROW>
            else
                customPath = [fullfile(rmwInfo.installDir,'lib'), pathsep, customPath]; %#ok<AGROW>
                customLDLibraryPath = [fullfile(rmwInfo.installDir,'lib'), pathsep, customLDLibraryPath]; %#ok<AGROW>
                customSitePackagesPath = [fullfile(rmwInfo.installDir,'lib','python3.9','site-packages'), pathsep, customSitePackagesPath]; %#ok<AGROW>
            end
        end
    end

    % Append middleware installation paths to PATH,
    % LD_LIBRARY_PATH, AMENT_PREFIX_PATH
    % environment variables. Here AMENT_PREFIX_PATH is useful, when
    % middleware installations are done using colcon build.
    middlewareEnvInstance = ros.internal.MiddlewareEnvironment.getInstance;
    middlewareInstallationBinDir = {};
    middlewareInstallationLibDir = {};
    resetEnvs = {};
    middlewareInstallations = {};
    if ~isempty(middlewareEnvInstance.MiddlewareRoot)
        middlewareInstallations = middlewareEnvInstance.MiddlewareRoot.keys;
    end

    for iKey = 1:numel(middlewareInstallations)
        middlewareInstallationBinDir{iKey} = fullfile(middlewareInstallations{iKey},'bin'); %#ok<AGROW>
        middlewareInstallationLibDir{iKey} = fullfile(middlewareInstallations{iKey},'lib'); %#ok<AGROW>
        customPath = [middlewareInstallationBinDir{iKey}, pathsep, customPath]; %#ok<AGROW>
        customAmentPrefixPath = [middlewareInstallations{iKey}, pathsep, customAmentPrefixPath]; %#ok<AGROW>
        if ~ispc
            customLDLibraryPath = [middlewareInstallationLibDir{iKey}, pathsep, customLDLibraryPath]; %#ok<AGROW>
        end

        % set middleware specific environment variables
        userEnvVars = middlewareEnvInstance.MiddlewareRoot(middlewareInstallations{iKey}).keys();
        userEnvValues = middlewareEnvInstance.MiddlewareRoot(middlewareInstallations{iKey}).values();
        for i=1:length(userEnvVars)
            if isequal(userEnvVars{i},'PATH')
                customPath = [userEnvValues{i}, pathsep, customPath]; %#ok<AGROW>
                resetEnvs{i} = []; %#ok<AGROW>
            elseif ismember(userEnvVars{i}, {'LD_LIBRARY_PATH', 'DYLD_LIBRARY_PATH'})
                customLDLibraryPath = [userEnvValues{i}, pathsep, customLDLibraryPath]; %#ok<AGROW>
                resetEnvs{i} = []; %#ok<AGROW>
            else
                setenv(userEnvVars{i},userEnvValues{i});
                resetEnvs{i} = onCleanup(@()unsetenv(userEnvVars{i})); %#ok<AGROW>
            end
        end
    end

    setenv('CUSTOM_AMENT_PREFIX_PATH', customAmentPrefixPath);
    resetCustomAmentPrefPath = onCleanup(@()unsetenv('CUSTOM_AMENT_PREFIX_PATH'));

    setenv('CUSTOM_PATH', customPath);
    resetCustomPath = onCleanup(@()unsetenv('CUSTOM_PATH'));

    setenv('CUSTOM_SITE_PACKAGES_PATH', customSitePackagesPath);
    resetCustomSitePackagesPath = onCleanup(@()unsetenv('CUSTOM_SITE_PACKAGES_PATH'));

    resetCustomLdLibraryPath = [];
    if isunix
        setenv('CUSTOM_LD_LIBRARY_PATH', customLDLibraryPath);
        resetCustomLdLibraryPath = onCleanup(@()unsetenv('CUSTOM_LD_LIBRARY_PATH'));
    end

end