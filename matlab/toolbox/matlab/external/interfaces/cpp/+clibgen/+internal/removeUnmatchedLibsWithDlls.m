function dllsWithOutLibs = removeUnmatchedLibsWithDlls(librariesWithDlls)
% Identified ".lib" files count should match the provided DLL files

%   Copyright 2024 The MathWorks, Inc.

    dllNames = {};
    libNames = {};
    dllsWithOutLibs = librariesWithDlls;
    % Get the names of all the provided DLL files
    for index = 1:length(librariesWithDlls)
        [~,filename,ext] = fileparts(librariesWithDlls{index});
        if strcmpi(ext,'.dll')
            dllNames{end+1} = [filename ext]; %#ok
        end
    end
   % Get the names of all the identified ".lib" files
    for index = 1:length(librariesWithDlls)
        [~,filename,ext] = fileparts(librariesWithDlls{index});
        if strcmpi(ext,'.lib')
            if (find(strcmpi(dllNames,[char(filename) '.dll'])) ~= 0)
               libNames{end+1} = [filename ext]; %#ok
            end
        end
    end
    % Remove all identified ".lib" files if count of DLL files and ".lib"
    % files doesn't match
    if length(dllNames) ~= length(libNames)
        libsUpdated = false;
        for index = 1:length(librariesWithDlls)
            [~,filename,ext] = fileparts(librariesWithDlls{index});
            if strcmpi(ext,'.lib')
                if (find(strcmpi(dllNames,[char(filename) '.dll'])) ~= 0)
                   librariesWithDlls{index} = '';
                   libsUpdated = true;
                end
            end
        end
        % Remove empty spaces of the updated Library
        if libsUpdated
            dllsWithOutLibs = {};
            for i = 1:length(librariesWithDlls)
                if ~isempty(librariesWithDlls{i})
                    dllsWithOutLibs{end+1} = librariesWithDlls{i}; %#ok
                end
            end
        end
    end
end

