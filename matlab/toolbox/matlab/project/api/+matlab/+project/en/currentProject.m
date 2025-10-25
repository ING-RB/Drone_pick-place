%currentProject Get current project
%    project = matlab.project.currentProject returns the currently loaded
%    project object. When a shortcut, start up or shutdown file is being
%    run for a referenced project this function will return an object for
%    the referenced project.
%
%    Use matlab.project.rootProject if the open root project in the
%    currently open referenced project hierarchy is required.
%
%    An empty array is returned if no project is loaded.
%
%    The returned object, project, can be used to query and modify the
%    currently loaded project.
%
%    See also matlab.project.loadProject

 

%  Copyright 2012-2022 The MathWorks, Inc.

