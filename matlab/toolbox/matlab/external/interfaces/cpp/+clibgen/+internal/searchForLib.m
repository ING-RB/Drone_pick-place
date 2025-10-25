function [libraries,librariesAddedForDlls] = searchForLib(libFilename,libraries, headerFiles)
% Search for ".lib" file in current directory, directory from where DLL
% files and header files are provided

%   Copyright 2024 The MathWorks, Inc.

    librariesAddedForDlls = false;
    % search in the current folder
    libInCurrFolder = searchForLibraryInFolders('', libFilename);
    if ~isempty(libInCurrFolder)
        libraryFile = cellstr(convertStringsToChars(libInCurrFolder));
        libraries{end+1} = libraryFile;
        return;
    end
    % search for .lib file in the DLL file provided folder
    for index = 1:length(libraries)
        [directory,~,ext] = fileparts(libraries{index});
        if strcmpi(ext,'.dll')
            fullLibFile = strcat(fullfile(char(directory)),char(filesep));
            libInDllPath = searchForLibraryInFolders(fullLibFile, libFilename);
            if ~isempty(libInDllPath)
                fullLibFile = strcat(fullfile(char(directory)),char(filesep),char(libInDllPath));
                libraries{end+1} = convertStringsToChars(fullLibFile);
                return;
            end
        end
    end
    % search for .lib file in the header file provided folder
    for index = 1:length(headerFiles)
        [directory,~,~] = fileparts(headerFiles{index});
        fullLibFile = strcat(fullfile(char(directory)),char(filesep));
        libInHeaderPath = searchForLibraryInFolders(fullLibFile, libFilename);
        if ~isempty(libInHeaderPath)
            fullLibFile = strcat(fullfile(char(directory)),char(filesep),char(libInHeaderPath));
            libraries{end+1} = convertStringsToChars(fullLibFile);
            return;
        end
    end

    % Search for .lib files with dll file name in the provided directory
    function libraryForDll = searchForLibraryInFolders(directory, libName)
       libraryForDll = '';
       % For current folder "directory" will be empty
       if ~isempty(directory)
           fullFile = strcat(directory, libName, '.*');
           filesInDir = dir(char(fullFile));
           match = strcmpi({filesInDir.name},[libName, '.lib']);
           if find(match) ~= 0
               libraryForDll = filesInDir(match).name;
           end
       else
           filesInCurr = dir(char([libName, '.*']));
           match = strcmpi({filesInCurr.name},[libName, '.lib']);
           if find(match) ~= 0
               libraryForDll = filesInCurr(match).name;
           end
       end
    end

end
