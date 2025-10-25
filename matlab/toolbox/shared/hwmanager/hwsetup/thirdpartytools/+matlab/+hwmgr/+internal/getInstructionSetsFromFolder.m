function out = getInstructionSetsFromFolder(folder)
% GETINSTRUCTIONSETSFROMFOLDER parses the given folder and extracts
% InstructionSet objects.

% Copyright 2022 The MathWorks, Inc.

out = {};
% all instructionset folders should have .instrset suffix
instrsetFolders = dir(fullfile(folder, '*.instrset'));
for i = 1:numel(instrsetFolders)
    % look for a platform specific file first
    instrset = loc_getPlatformSpecificInstrset(instrsetFolders(i));

    % if a platform specific file not found, look into common folder
    if isempty(instrset)
        instrset = loc_getPlatformIndependentInstrset(instrsetFolders(i));
    end

    if ~isempty(instrset)
        % found a valid instruction set
        out{end+1} = matlab.hwmgr.internal.InstructionSet(instrset); %#ok<AGROW>
    end
end
end

function out = loc_getPlatformSpecificInstrset(instrsetFolder)
out = [];
instrset = fullfile(instrsetFolder.folder, instrsetFolder.name, computer('arch'),...
    [computer('arch'), '.xml']);
if exist(instrset, 'file')
    out = instrset;
end
end

function out = loc_getPlatformIndependentInstrset(instrsetFolder)
out = [];
instrset = fullfile(instrsetFolder.folder, instrsetFolder.name, 'common', 'common.xml');
if exist(instrset, 'file')
    out = instrset;
end
end