function generateMATLABInterface(definitionFile, outputFolder, varargin)
%   This function is intended to be executed with "MATLAB as a build tool"
%   during the build stage by the downstream components to cppcli to
%   generate MATLAB Interface Libraries from definition files.

%   Copyright 2020-2023 The MathWorks, Inc.

libDefObj = getLibraryDefinition(definitionFile, outputFolder, varargin{:})
targetDir = libDefObj.OutputFolder;

disp('Generating Interface Library.');
eval('build(libDefObj);');

disp(strcat("Moving Interface Library to ", targetDir, '.'));
interfaceLibrary = strcat(libDefObj.PackageName, 'Interface', getExtension);
movefile(fullfile(libDefObj.OutputFolder,libDefObj.PackageName,interfaceLibrary), targetDir);

function libDefObj = getLibraryDefinition(definitionFile, outputFolder, varargin)
    [definitionFileLoc,definitionFileName,~]  = fileparts(definitionFile);
    currentDir = cd(definitionFileLoc);
    finishup = onCleanup(@()(cd(currentDir)));
    eval(['libDefObj =' definitionFileName ';']);

    libDefObj.OutputFolder = fullfile(outputFolder);

    varargCount = numel(varargin);
    if varargCount > 0
        % find index of "RootPaths"
        idxRootPath = find(varargin == "RootPaths");
        if ~isempty(idxRootPath)
            if idxRootPath == varargCount
                error("Key-Values not specified for RootPaths");
            end
            if rem(varargCount-idxRootPath,2) ~= 0
                % odd number of key-value pairs, unmatched
                error("Key-Values specified for RootPaths are not in even number");
            end
            disp('Updating RootPaths in definition object.');
            idx = idxRootPath+1;
            while idx < varargCount
                libDefObj.RootPaths(varargin{idx}) = varargin{idx+1};
                idx = idx + 2;
            end
            libEnd = idxRootPath-1;
        else
            libEnd = varargCount;
        end
        if libEnd >= 1
            % atleast one library specified
            disp('Updating Libraries in definition object.');
            libDefObj.Libraries = varargin(1:libEnd);
        end
    end
end

function ext = getExtension
    if ispc
        ext = '.dll';
    elseif ismac
        ext = '.dylib';
    elseif isunix
        ext = '.so';
    else
        error('Platform not supported.')
    end
end

end