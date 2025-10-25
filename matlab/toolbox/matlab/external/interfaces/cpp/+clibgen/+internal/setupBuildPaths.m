function parsedResults = setupBuildPaths(parsedResults)
% Set build environment using absolute paths

%   Copyright 2024 The MathWorks, Inc.

% Set the absolute paths
if iscellstr(parsedResults.SupportingSourceFiles)
    for index = 1: length(parsedResults.SupportingSourceFiles)
        [status, value] = fileattrib(char(parsedResults.SupportingSourceFiles{index}));
        if status
            parsedResults.SupportingSourceFiles{index} = value.Name;
        end
    end
else
    if ~isempty(parsedResults.SupportingSourceFiles)
        [status, value] = fileattrib(char(parsedResults.SupportingSourceFiles));
        if status
           parsedResults.SupportingSourceFiles = value.Name;
        end
    end
end

% Infer name of library if Libraries values is '' and only one header is
% provided under InterfaceGenerationFiles option and SupportingSourceFiles
% option is empty
if isempty(parsedResults.Libraries) && isscalar(parsedResults.HeaderFiles)
    [Directory,filename,ext] = fileparts(parsedResults.HeaderFiles{1});
    if ispc
        libraryFile = strcat(fullfile(char(Directory),char(filename)), ".lib");
    else
        if ismac
            libraryFile = strcat(fullfile(char(Directory),char(filename)), ".dylib");
        else
            libraryFile = strcat(fullfile(char(Directory),['lib', char(filename)]), ".so");
        end
    end
    if (strcmp(ext,'.h')  || strcmp(ext,'.hpp') || strcmp(ext,'.hxx'))
        if isfile(char(libraryFile))
            if isempty(parsedResults.SupportingSourceFiles)
                parsedResults.Libraries = libraryFile;
            end
        end
    end
end

% check the compiler configuration if the user has provided DLL file under
% Libraries option
if ~isempty(parsedResults.Libraries)
    parsedResults.Libraries = cellstr(convertStringsToChars(parsedResults.Libraries));
end

% Set the output folder if it is not empty to address g1596357
if parsedResults.OutputFolder ~=""
    content= dir(char(parsedResults.OutputFolder));
    % Avoid index exceeds array bounds if content is empty
    if ~isempty(content)
        parsedResults.OutputFolder = content(1).folder;
    end
end

% Check if output folder is writable
testDir = ['deleteMe_', num2str(floor(rand*1e12))];
isWritable = mkdir(parsedResults.OutputFolder, testDir);
if isWritable == 1
    rmdir(fullfile(parsedResults.OutputFolder, testDir));
else
    error(message('MATLAB:CPP:AccessDenied',parsedResults.OutputFolder));
end

% Normalize the output folder (Remove any trailing slash)
% Ensure there is no trailing slash so that cl and link command
% works
if ~isempty(parsedResults.OutputFolder)
    [status, value]= fileattrib(char(parsedResults.OutputFolder));
    if status
        parsedResults.OutputFolder = value.Name;
    end
end

end
