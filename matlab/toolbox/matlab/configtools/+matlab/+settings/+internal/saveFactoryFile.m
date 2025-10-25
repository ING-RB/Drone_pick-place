function saveFactoryFile(...
    toolboxName, factorySettingsTree, settingsFileUpgraders)
% saveFactoryFile  Saves the factory settings tree and the array
%    of personal settings upgraders in the factory settings file.  
%
%    Technically, serves as a wrapper around the saveFactoryFile 
%    C++ function.
	
%    Copyright 2019 The MathWorks, Inc.
	
    % Convert toolboxName to string 
    if (ischar(toolboxName))
         toolboxName = convertCharsToStrings(toolboxName);
    end
    
    if (~isstring(toolboxName))
        error(message('MATLAB:settings:config:ParameterMustBeString', ... 
            'toolboxName', 'saveFactoryFile'));
    end
    
    % Check that the toolboxName is not empty
    if (isequal(toolboxName, "") || ismissing(toolboxName))
        error(message('MATLAB:settings:config:EmptyToolboxName', ...
            'saveFactoryFile'));
    end
	
	[fileStatus, fileValues] = fileattrib(toolboxName);
	
    if (fileStatus)
        if isequal(fileValues.UserWrite, 0)
            error(message('MATLAB:settings:config:NoWritePermissionOnFactoryFile', ... 
                toolboxName));
        end
    end
    
    pathNames = split(toolboxName, filesep);
    
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
            toolboxName));
    end
    
    for i = 2 : numel(pathNames) 
        startIndex = regexp(pathNames(i), '[/\*:?"<>|]', 'once');
        if ~isempty(startIndex)
            error(message('MATLAB:settings:config:IllegalFilePath', ... 
                toolboxName));
        end
    end
    
    [dirPath, name, ext] = fileparts(toolboxName);
    
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
            'factorySettingsTree', 'saveFactoryFile'));
    end
	
    % Check the settingsFileUpgraders
    if (~isa(settingsFileUpgraders, 'matlab.settings.SettingsFileUpgrader'))
        error(message(...
            'MATLAB:settings:config:ParameterMustBeSettingsFileUpgrader', ... 
            'settingsFileUpgraders', 'saveFactoryFile'));
    end
    
    % Finally, call saveFactoryFileImpl
    matlab.settings.internal.saveFactoryFileImpl(toolboxName, ...
        factorySettingsTree, settingsFileUpgraders);
end

