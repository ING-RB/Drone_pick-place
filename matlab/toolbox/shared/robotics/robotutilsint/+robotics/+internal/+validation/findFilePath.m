function absFilePath = findFilePath(filePath, varargin)
%This function is for internal use only. It may be removed in the future.

%findFilePath Find file according to filePath and return the absolute path
%   ABSFILEPATH = findFilePath(FILEPATH) searches for the file name
%   FILEPATH on the MATLAB path and returns the absolute path to the file
%   in ABSFILEPATH.
%
%   FILEPATH can also be specified as a relative path (relative to current
%   directory) or an absolute path. This function validates the existence
%   of the file and returns the absolute path to it in ABSFILEPATH.
%
%   See also validateFilePath.

%   Copyright 2017-2023 The MathWorks, Inc.

% Find file anywhere on the MATLAB path
    filePathToTest = which(filePath);
    if isempty(filePathToTest)
        % File is not on MATLAB path, but path might still be valid.
        % Keep the user input verbatim.
        filePathToTest = filePath;
    end

    % Validate existence of file and change relative to absolute path
    absFilePath = robotics.internal.validation.validateFilePath(filePathToTest, varargin{:});

end
