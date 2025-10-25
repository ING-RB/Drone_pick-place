% Break off all implicit dirs from a directory
function [parentDir, implicitDirs] = separateImplicitDirs(sourceDir)
    % To implement a new implicit directory pattern, add it to this list.

%   Copyright 2013-2024 The MathWorks, Inc.

    implicitDirList = {'private', '[+@][^\\/]++'};

    % Build the Regular Expression
    assertBeginOfDirName = '(?<=[\\/]|^)';
    implicitDirList = append(implicitDirList{1}, sprintf('|%s', implicitDirList{2:end}));
    matchEndOfDirName = '([\\/]|$)';
    implicitDirPattern = append(assertBeginOfDirName, '((', implicitDirList, ')', matchEndOfDirName, ')*+$');
    
    [implicitDirs, split] = regexp(sourceDir, implicitDirPattern, 'match', 'split', 'once');
    parentDir = split{1};
end

