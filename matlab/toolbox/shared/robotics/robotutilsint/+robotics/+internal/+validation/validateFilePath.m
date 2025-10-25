function absPath = validateFilePath(filePath, functionName, varName)
%This class is for internal use only. It may be removed in the future.

%validateFilePath Validate a relative or absolute file path
%   This function ensures that a given file path refers to an
%   existing file and will change any relative path to an
%   absolute one.
%
%   ABSPATH = robotics.internal.validation.validateFilePath('FILEPATH')
%   checks if the input FILEPATH refers to a valid file. If it
%   does, return the absolute path to this file in ABSPATH.
%   If the file does not exist, or if it refers to a folder
%   instead, this function will throw an error.
%
%   Examples:
%       % Returns absolute path for file test.txt
%       absPath = robotics.internal.validation.validateFilePath('test.txt');

%   Copyright 2018-2023 The MathWorks, Inc.

% Validate inputs

% Set default function name and variable name used for validation
    if nargin == 1
        functionName = 'validateFilePath';
        varName = 'filePath';
    end

    validateattributes(convertStringsToChars(filePath), {'char'}, {'nonempty'}, functionName, varName);

    % Check if file exists and throw an error if it does not
    [status, fileStruct] = fileattrib(filePath);
    if ~status
        error(message('shared_robotics:validation:FileNotExist', filePath));
    end

    % Throw an error if this is a directory
    if fileStruct.directory
        error(message('shared_robotics:validation:FilePathIsDir', filePath));
    end

    % Recover absolute path to file
    absPath = fileStruct.Name;
end
