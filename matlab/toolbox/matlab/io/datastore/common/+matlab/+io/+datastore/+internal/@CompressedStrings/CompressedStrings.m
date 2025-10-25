classdef CompressedStrings < handle
%COMPRESSEDSTRINGS Applies Huffman-encoding to create compressed filenames

%   Copyright 2019-2022 The MathWorks, Inc.
    properties
        EncodedStrings
        SchemaVersion (1,1) double = 1;
    end
    
    methods
        function obj = CompressedStrings(names, folders, ext, origFileSep)
            import matlab.io.datastore.internal.fileset.HuffmanPaths;
            if nargin < 1
                obj.EncodedStrings = [];
                return;
            end

            % create a FileSet with these file names using the internal API
            numFiles = numel(names);
            names = (names + ext);
            fullStruct = getFoldersFilesStruct(names, folders);
            paths = HuffmanPaths('files', fullStruct);
            if numFiles == 1
                fullStruct{1, 1} = iSplitFullFile(fullStruct{1, 1}, origFileSep);
            else
                fullStruct(:, 1) = cellfun(@(x)iSplitFullFile(x, origFileSep), ...
                    fullStruct(:, 1), 'UniformOutput', false);
            end
            paths.addPaths(fullStruct(:, 1), fullStruct(:, 2));
            % Set the property on the object
            obj.EncodedStrings = paths;
        end

        function str = getCompressedString(obj, index, origFileSep)
            str = getPaths(obj.EncodedStrings, index, origFileSep);
        end
        
        function S = saveobj(obj)
            S = struct();
            [S.StringTree, S.PathTree] = serialize(obj.EncodedStrings);
            S.Frequencies = obj.EncodedStrings.Frequencies;
            S.SchemaVersion = obj.SchemaVersion;
        end
    end

    methods (Static)
        function obj = loadobj(s)
            st = s.StringTree;
            pt = s.PathTree;
            freq = s.Frequencies;
            obj = matlab.io.datastore.internal.CompressedStrings();
            obj.EncodedStrings = matlab.io.datastore.internal.fileset.HuffmanPaths('tree',...
                st, pt, freq);
            obj.SchemaVersion = s.SchemaVersion;
        end
    end
end

function pth = iSplitFullFile(pth, originalFileSep)
    %ISPLITFULLFILE Split a full file using the given filesep so the compression
    % ratio for the InternalPaths object is better.

    % strsplit has an option to collapse delimiters by default,
    % whereas string.split does not have such option.
    originalFileSep = regexptranslate('escape',originalFileSep);
    delim = ['(?:', originalFileSep, ')+'];
    [pth,m] = regexp(pth, delim, 'split', 'match');
    if ~isempty(m)
        % Add filesep to the root
        % This adds any UNC root separators or WIN drive roots
        % or IRI scheme file separators to the root.
        pth{1} = [pth{1}  m{1}];
    end
    % string split returns a column vector for a row vector input
    pth = pth(:)';
    if ~isempty(pth) && isempty(pth{end})
        % remove any trailing empty characters
        pth(end) = [];
    end
end

function fullStruct = getFoldersFilesStruct(files, folders)
% Create the following associated structure that follows the input order:
% {folders, {files associated with individual folder}}
% Duplicated folders not contiguous in the input "names" will be treated as
% separate entries to avoid messing up the input order:
% {folder1, {files associated with first set of folder1}}
% {folder2, {files associated with first set of folder2}}
% {folder1, {files associated with second set of folder1}}
numFiles = numel(files);
groupedFilesList = cell(numFiles, 1);
groupedFoldersList = cell(numFiles, 1);

filesIdx = 1;
while filesIdx <= numFiles

    % Get folder entries one by one and its correspoding files.
    groupedFoldersList{filesIdx} = folders{filesIdx};
    currentFoldersIdx = filesIdx;
    while currentFoldersIdx + 1 <= numFiles && strcmp(folders{currentFoldersIdx}, folders{currentFoldersIdx+1})
        % Continue until we encounter a different folder name.
        currentFoldersIdx = currentFoldersIdx + 1;
    end

    % Group the files in the current folder entry to a cell.
    tmpGroupedFiles = convertStringsToChars(files(filesIdx : currentFoldersIdx));
    % Add the grouped files for the current folder entry to the
    % current namesIdx in "files" list.
    groupedFilesList(filesIdx) = {tmpGroupedFiles};
    % Wrap if only a single item in tmpGroupedFiles to a {} to use with
    % HuffmanPaths later.
    if numel(groupedFilesList(filesIdx)) == 1 && iscellstr(groupedFilesList(filesIdx))
        groupedFilesList(filesIdx) = {groupedFilesList(filesIdx)};
    end

    % Jump to the next folder entry.
    filesIdx = currentFoldersIdx + 1;
end

% Remove empty rows between namesIdx and nextFoldersIdx from each loop
% above in "files" and "foldersGrouped" lists.
groupedFilesList = groupedFilesList(~cellfun('isempty', groupedFilesList));
groupedFoldersList = groupedFoldersList(~cellfun('isempty', groupedFoldersList));

% Form the {folders, {files associated with individual folder}} associated structure.
fullStruct = [groupedFoldersList, groupedFilesList];
end