function registerFactoryFile(...
    resourcesFolder, factorySettingsTree, settingsFileUpgraders, ...
    createSettingsInfoJSONFile, fullPath)
% registerFactoryFile  Saves the factory settings tree and the array
%    of personal settings upgraders in the factory settings file.  
%
%    Technically, serves as a wrapper around the registerFactoryFile 
%    C++ function.
	
%    Copyright 2019-2020 The MathWorks, Inc.
	
    % Convert resourcesFolder to string 
    if (ischar(resourcesFolder))
         resourcesFolder = convertCharsToStrings(resourcesFolder);
    end
    
    if (~isstring(resourcesFolder))
        error(message('MATLAB:settings:config:ParameterMustBeString', ... 
            'resourcesFolder', 'registerFactoryFile'));
    end
    
    % Check that the resourcesFolder is not empty
    if (isequal(resourcesFolder, ""))
        error(message('MATLAB:settings:config:EmptyToolboxName', ...
            'registerFactoryFile'));
    end

    status = mkdir(resourcesFolder);
    if (~status)
        error(message('MATLAB:settings:config:EmptyToolboxName', ...
            'registerFactoryFile'));
    end
        
    [fileStatus, fileValues] = fileattrib(resourcesFolder);
	
    if (fileStatus)
        if isequal(fileValues.UserWrite, 0)
            error(message('MATLAB:settings:config:NoWritePermissionOnFactoryFile', ... 
                resourcesFolder));
        end
    end
    
    pathNames = split(resourcesFolder, filesep);
    
    % Check pathNames(0).  If it is a drive name on Windows, it will 
    % contain a colon at the end.
    numPathNames = numel(pathNames);

    possibleDriveName = pathNames(1);
        
    if numPathNames > 1
        if endsWith(possibleDriveName, ":")
            %possibleDriveName = possibleDriveName{1:numel(possibleDriveName)-1};       
            possibleDriveName = extractBefore(possibleDriveName, strlength(possibleDriveName));
        end
    end
        
    startIndex = regexp(possibleDriveName, '[\[\]/\*:?"<>|]', 'once');
    if ~isempty(startIndex)
        error(message('MATLAB:settings:config:IllegalFilePath', ... 
            resourcesFolder));
    end
    
    for i = 2 : numel(pathNames) 
        startIndex = regexp(pathNames(i), '[/\*:?"<>|]', 'once');
        if ~isempty(startIndex)
            error(message('MATLAB:settings:config:IllegalFilePath', ... 
                resourcesFolder));
        end
    end
    
    [dirPath, name, ext] = fileparts(resourcesFolder);
    
    if (~isempty(dirPath))
        [dirStatus, dirValues] = fileattrib(dirPath);
	
        if (dirValues.UserWrite == 0)
	        error(message('MATLAB:settings:config:NoWritePermissionOnFilePath', ... 
                dirPath));
        end
    end
	
    % Check the factorySettingTree
    if (~isa(factorySettingsTree, 'matlab.settings.FactoryGroup'))
        error(message('MATLAB:settings:config:ParameterMustBeFactoryGroup', ... 
            'factorySettingsTree', 'registerFactoryFile'));
    end
	
    % Check the settingsFileUpgraders
    if (~isa(settingsFileUpgraders, 'matlab.settings.SettingsFileUpgrader'))
        error(message(...
            'MATLAB:settings:config:ParameterMustBeSettingsFileUpgrader', ... 
            'settingsFileUpgraders', 'registerFactoryFile'));
    end
    
    if (nargin < 4)
        createSettingsInfoJSONFile = true;
    end
    if (nargin < 5)
        fullPath = '';
    end
    
    % Finally, call registerFactoryFileImpl
    matlab.settings.internal.registerFactoryFileImpl(resourcesFolder, ...
        factorySettingsTree, settingsFileUpgraders, createSettingsInfoJSONFile, fullPath);
end

