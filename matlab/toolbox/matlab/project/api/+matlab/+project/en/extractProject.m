%extractProject Extract project from archive
%
%   project = matlab.project.extractProject(archiveName) extracts the
%   project archive to a new folder in the default project folder.
%   matlab.project.extractProject opens the extracted project and returns a
%   matlab.project.Project object.
%
%   project = matlab.project.extractProject(archiveName, destination)
%   extracts the project archive to the specified destination folder.
%   If the destination folder exists, it must be empty. Otherwise,
%   extractProject creates the destination folder before extracting the
%   project.
%
%   archiveName - Archive file name or path, specified as a character
%                 vector or string scalar (.mlproj, .zip).
%   destination - New project destination, specified as a character
%                 vector or string scalar.
%
%   Example:
%      % Create a copy of the currently opened project in the default project folder
%      proj = currentProject;
%      export(proj,"myarchive.mlproj");
%      copy = matlab.project.extractProject("myarchive.mlproj");

% Copyright 2022-2023 The MathWorks, Inc.
