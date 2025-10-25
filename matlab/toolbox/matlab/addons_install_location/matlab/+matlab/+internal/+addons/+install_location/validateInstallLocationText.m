function [isValid,errorMsg] = validateInstallLocationText(installLocationText)
%VALIDATEINSTALLLOCATIONTEXT Validates install location text field value in
% the preference panel

% Copyright 2022 The MathWorks Inc.

if ~isAbsolute(installLocationText)
    isValid = false;
    errorMsg = string(message('matlab_addons:installLocation:genericError'));
    return;
end

% check for valid unc and Drive on windows
if ispc

    if isUNC(installLocationText)
        if ~isValidUNC(installLocationText)
            isValid = false;
            errorMsg = string(message('matlab_addons:installLocation:genericError'));
            return;
        end
    end
    if ~doesTheDriveExist(installLocationText)
        isValid = false;
        errorMsg = string(message('matlab_addons:installLocation:genericError'));
        return;
    end
end

if isPrivateFolder(installLocationText)
    isValid = false;
    errorMsg = string(message('matlab_addons:installLocation:privateFolderError'));
    return;
end

if ~isPathAFolder(installLocationText)
    isValid = false;
    errorMsg = string(message('matlab_addons:installLocation:mustBeFolder'));
    return;
end

isValid = true;
errorMsg = "";

%   ISABSOLUTE returns true if FILE is an absolute filepath.
    function status = isAbsolute(file)
        if ispc
            status = ~isempty(regexp(file,'^[a-zA-Z]*:\/','once')) ...
                || ~isempty(regexp(file,'^[a-zA-Z]*:\\','once')) ...
                || strncmp(file,'\\',2) ...
                || strncmp(file,'//',2);
        else
            status = strncmp(file,'/',1);
        end
    end

    function status = doesTheDriveExist(filePath)
        cellArrayOfFileParts = regexp(filePath,'\','split');
        drive = strcat(cellArrayOfFileParts{ 1},filesep);
        status = exist(drive, 'dir');
    end

    function status = isUNC(filepath)
        status = startsWith(filepath,"//");
    end

    function status = isValidUNC(filepath)
        filePathParts = strsplit(filepath,filesep);
        status = exist(strcat("\\", filePathParts(2)), 'dir');
    end

    function status = isPrivateFolder(filepath)
        [~,name,~] = fileparts(filepath);
        status = strcmp(string(name), "private");
    end

    function status = isPathAFolder(filepath)
        if exist(filepath, 'dir')
            status = true;
        else
            [~,~,ext] = fileparts(filepath);
            status = isempty(ext);
        end
    end

end