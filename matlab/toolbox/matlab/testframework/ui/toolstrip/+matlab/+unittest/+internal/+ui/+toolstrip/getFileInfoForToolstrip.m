function [isTestFile, isValidFile, isClassBasedTest] = getFileInfoForToolstrip(file)
% This function is undocumented and may change in a future release.

% Note: For performance reasons, this file assumes the file input is a full
% path file name (coming from the editor).

% Copyright 2017-2022 The MathWorks, Inc.
    isClassBasedTest = false;
    isTestFile = false;
    isValidFile = false;

    if ~isfile(file)
        return; % Protect against "Untitled" and when file no longer exists
    end

    [~,~,ext] = fileparts(file);
    if ~any(strcmpi(ext,{'.m','.mlx'}))
        return;
    end

    [isValidFile, isFunctionBasedTest, isClassBasedTest] = ...
        matlab.unittest.internal.getTestFileInfo(convertStringsToChars(file));

    if isValidFile
        isTestFile = isFunctionBasedTest || isClassBasedTest;
    end
end
