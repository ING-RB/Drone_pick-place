function fillFileInfo(self, unused) %#ok<INUSD>
% Creates the list of source files generated for the selected subsystem.
% Returns 0 for success else 1 for an error
% returns also the list of folders to add in -I (folders containing sources)

% Copyright 2011-2024 The MathWorks, Inc.

if ~isempty(getenv('DSPACE_ROOT'))
    dspace_root = getenv('DSPACE_ROOT');
elseif ~isempty(getenv('TL_ROOT'))
    dspace_root = getenv('TL_ROOT');
else
    dspaceInfo = which('tl_config');
    if ~isempty(dspaceInfo)
        dspace_root = fullfile(dspaceInfo, '..', '..');
    else
        warning('pslink:tlInstallationProblem', message('polyspace:gui:pslink:tlInstallationProblem').getString());
    end
end

includePathSet = containers.Map('KeyType', 'char', 'ValueType', 'double');
sourceFileSet = containers.Map('KeyType', 'char', 'ValueType', 'logical');

mdlDir = fileparts(self.slModelFileName);

newFileObjects = [];
if exist(which('dsdd_get_sourcefile_list'), 'file')
    mdlrefs =  find_mdlrefs(self.slModelName);
    % dsdd_get_sourcefile_list accepts a list of entries as parameter
    % for tlsubsystems. So we extract the list of mdlrefs and then
    % replace top level model by the selected TL subsystem to analyze
    mdlrefs{end} = ['/Subsystems/',self.cgName];
    newFileObjects = dsdd_get_sourcefile_list('tlsubsystems', mdlrefs);
end

if ~isempty(newFileObjects)
    nbFiles = numel(newFileObjects);
    for k = 1:nbFiles
        fFile = newFileObjects(k).fileFullName;
        [fPath, fName, fExt] = fileparts(fFile);
        % Skip .asm extension
        if ~strcmpi(fExt, '.c')
            continue
        end
        fName = [fName, fExt]; %#ok<AGROW>
        if ~isempty(fPath)
            if ~polyspace.internal.isAbsolutePath(fPath)
                % Start from current directory
                fpath = fullfile(pwd, fPath);
            end
            
            % Get the canonical path for removing any intermediate
            % . or ..
            folderOfFile = polyspace.internal.getAbsolutePath(fpath);
            
            fFile = fullfile(folderOfFile, fName);
            fileFound = exist(fFile, 'file');
            if ~fileFound
                if ~polyspace.internal.isAbsolutePath(fPath)
                    % From the model's directory
                     fpath = fullfile(mdlDir, fPath);
                end
                folderOfFile = polyspace.internal.getAbsolutePath(fpath);

                fFile = fullfile(folderOfFile, fName);
                fileFound = exist(fFile, 'file');
            end
        else
            % Ordered list of folders to search in
            possibleSrcLocationList = { ...
                fullfile(mdlDir, 'TLProj'),...
                fullfile(mdlDir, 'TLBuild'),...
                fullfile(mdlDir, 'TLSim'),...
                fullfile(self.sysDirInfo.CodeGenFolder, 'TLProj'),...
                fullfile(self.sysDirInfo.CodeGenFolder, 'TLBuild'),...
                fullfile(self.sysDirInfo.CodeGenFolder, 'TLSim'),...
                fullfile(mdlDir),...
                fullfile(self.sysDirInfo.CodeGenFolder) ...
                };
            % Check all files exist in current directory or subdirectories
            for ii = 1:numel(possibleSrcLocationList)
                if exist(possibleSrcLocationList{ii}, 'dir') == 7
                    [fileFound, folderOfFile] = searchRecursive(fName, possibleSrcLocationList{ii});
                    if fileFound
                        break
                    end
                end
            end
        end
        if fileFound
            includePathSet(folderOfFile) = length(includePathSet);
            if ~strcmpi(newFileObjects(k).fileKind, 'HeaderFile')
                % Add the path and the full file name in the map (set)
                sourceFileSet(fullfile(folderOfFile, fName)) = 1;
            end
        else
            warning('pslink:sourceFileNotFound', '%s', message('polyspace:gui:pslink:sourceFileNotFound', fFile).getString());
        end
    end
else
    fileObjects = dsdd('find',['/Subsystems/',self.cgName],'ObjectKind','FileInfo');
    nbFiles = numel(fileObjects);
    
    for k = 1:nbFiles
        temp = dsdd('GetAttribute', fileObjects(k), 'hDDParent');
        parentName = dsdd('GetAttribute', temp, 'Name');
        
        if strcmp(parentName, 'ModuleInfo') || strcmp(parentName, 'AdditionalFiles')
            fileName = dsdd('Get', fileObjects(k), 'FileName');
            
            % Check all files exist in current directory or subdirectories
            [fileFound, folderOfFile] = searchRecursive(fileName, mdlDir);
            if ~fileFound
                [fileFound, folderOfFile] = searchRecursive(fileName, self.sysDirInfo.CodeGenFolder);
            end
            if fileFound
                % Only put .c or .C files into source file list
                isSource = regexpi(fileName, '\.c$');
                if isSource
                    % Add the path and the full file name in the map (set)
                    includePathSet(folderOfFile) = length(includePathSet);
                    sourceFileSet(fullfile(folderOfFile, fileName)) = 1;
                end
            else
                warning('pslink:sourceFileNotFound', '%s', message('polyspace:gui:pslink:sourceFileNotFound', fileName).getString());
            end
        end
    end
end

if nbFiles == 0
    return
end

% If a folder TLSim exist, add all subdirectories in -I
includePathSet = searchSubDir(includePathSet, fullfile(self.sysDirInfo.CodeGenFolder,'TLSim'));

% If a folder TLBuild exist, add all subdirectories in -I
includePathSet = searchSubDir(includePathSet, fullfile(self.sysDirInfo.CodeGenFolder,'TLBuild'));

% Add CodeGenFolder in -I as well
includePathSet(self.sysDirInfo.CodeGenFolder) = length(includePathSet);

% dSpace includes not listed in the DSDD file (because not needed on target host)
% This list is valid for version 3.4 of TargetLink and newer.
if exist(fullfile(dspace_root, 'matlab', 'TL', 'srcfiles', 'Generic'), 'dir') == 7
    % Always required. Sources for the generic TargetLink fixed point library
    includePathSet(fullfile(dspace_root, 'matlab', 'TL', 'srcfiles', 'Generic')) = length(includePathSet);
end
if exist(fullfile(dspace_root, 'matlab', 'TL', 'ApplicationBuilder', 'generic'), 'dir') == 7
    % Always required. Contains AUTOSAR include files and some parts of simulation frame
    includePathSet(fullfile(dspace_root, 'matlab', 'TL', 'ApplicationBuilder', 'generic')) = length(includePathSet);
end
% Compiler specific includes
compilerInclude = '';
cc = mex.getCompilerConfigurations('c', 'selected');
if ~isempty(cc) && isprop(cc, 'ShortName')
    if strncmpi(cc.ShortName, 'ms', 2)
        if strcmpi(computer('arch'), 'win32')
            % 32 Bit systems using MS Compiler
            compilerInclude = fullfile(dspace_root, 'matlab', 'TL', 'ApplicationBuilder', 'BoardPackages', 'HostPC32', 'MSVC');
        else
            % 64 Bit systems using MS Compiler
            compilerInclude = fullfile(dspace_root, 'matlab', 'TL', 'ApplicationBuilder', 'BoardPackages', 'HostPC64', 'MSVC');
        end
    elseif strncmpi(cc.ShortName, 'lcc', 3)
        % 32 Bit systems using LCC compiler
        compilerInclude = fullfile(dspace_root, 'matlab', 'TL', 'ApplicationBuilder', 'BoardPackages', 'HostPC32', 'LCC');
    end
    if exist(compilerInclude, 'dir') == 7
        includePathSet(compilerInclude) = length(includePathSet);
    end
end

% MATLAB include
includePathSet(fullfile(matlabroot, 'extern', 'include')) = length(includePathSet);
includePathSet(fullfile(matlabroot, 'simulink', 'include')) = length(includePathSet);

% Add the stubs!
if ~isempty(self.stubFile)
    for ii = 1:size(self.stubFile, 1)
        sourceFileSet(self.stubFile{ii, 2}) = 1;
        includePathSet(fileparts(self.stubFile{ii, 1})) = length(includePathSet);
    end
end

% Historic customers are using prefs while others are using session flag
if (evalin('base','exist(''PolyspaceCustomBehaviour'')')==true && evalin('base','PolyspaceCustomBehaviour')==true) ...
        || (ispref('PolySpace', 'PolySpaceCustomBehaviour') && getpref('PolySpace', 'PolySpaceCustomBehaviour')==1)
    % Hook for adding sources files and includes folders
    [customSourcesList, customIncludeFolders] = customFileInfo(self.slSystemName, self.slModelName, self.cgName);
    % Make the entries unique
    customSourcesList = unique(customSourcesList);
    customIncludeFolders = unique(customIncludeFolders);
    for ll = 1:numel(customSourcesList)
        isSource = regexpi(customSourcesList{ll}, '\.c$');
        if isSource
            sourceFileSet(customSourcesList{ll}) = 1;
        end
    end
    for mm = 1:numel(customIncludeFolders)
        includePathSet(customIncludeFolders{mm}) = length(includePathSet);
    end
end

% files and paths are the keys!
self.fileInfo.source = sourceFileSet.keys();
includeKeys = includePathSet.keys();
includeVals = includePathSet.values();
[~,idx] = sort([includeVals{:}]);
self.fileInfo.include = includeKeys(idx);

%--------------------------------------------------------------------------
function includePathSet = searchSubDir(includePathSet, currentFolder)
% Add all sub folders of currentFolder in includePathSet

files = dir(currentFolder);
for k = 1:numel(files)
    currentFile = files(k).name;
    if files(k).isdir
        if strcmp(currentFile,'.') || strcmp(currentFile,'..')
            % go on
        else
            nextDir = fullfile(currentFolder,currentFile);
            includePathSet(nextDir) = length(includePathSet);
            includePathSet = searchSubDir(includePathSet, nextDir);
        end
    end
end

%--------------------------------------------------------------------------
function [fileFound, folderOfFile] = searchRecursive(fileName, currentDir)
% Search the file fileName recursively in current directory and in its subdirectories.
% Return the couple [fileFound, folderOfFile]
% fileFound = 1 if file is found  , folderOfFile is the path where the file was found

fileFound = false;
folderOfFile = '';
files = dir(currentDir);
fSize = size(files);

for k = 1:fSize
    currentFile = files(k).name;
    if strcmp(currentFile,'.') || strcmp(currentFile,'..') || strcmp(currentFile,'C-ALL') || strcmp(currentFile,'ALL')
        % go on
    else
        if files(k).isdir
            nextDir = fullfile(currentDir,currentFile);
            [fileFound, folderOfFile] = searchRecursive(fileName,nextDir);
        else
            % search in a non case-sensitive mode
            if strcmpi(currentFile,fileName)
                fileFound = true;
                folderOfFile = currentDir;
            end
        end
        if fileFound
            return
        end
    end
end

% LocalWords:  DSPACE dsdd sourcefile tlsubsystems pslink srcfiles libsrc linux
% LocalWords:  TCC polyspace eroy
