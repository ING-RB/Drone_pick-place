%getCurrentProject  Get the current project
%    project = slproject.getCurrentProject returns the currently loaded
%    project. An error is thrown if no project is currently loaded.
%    Starting in R2019a, use currentProject or openProject instead.
%
%    The returned object, project, can be used to query and modify the
%    currently loaded project. For example:
%
%    % Open the Airframe example project:
%    openExample("simulink/AirframeProjectExample")
%
%    % Get the project:
%    project = currentProject
%
%    % Get the location of the project root folder:
%    root = project.RootFolder;
%
%    % Get the files in the currently loaded project:
%    allProjectFiles = project.Files;
%
%    See also currentProject, openProject

 

%  Copyright 2012-2023 The MathWorks, Inc.

