classdef Shortcut< handle
%Shortcut  Information about shortcuts in the current project
%    Return information about a shortcut in the currently loaded
%    project.
%
%    Example:
%
%    % Get the currently open project:
%    project = currentProject;
%
%    % Get the shortcuts:
%    shortcuts = project.Shortcuts

 
%   Copyright 2010-2023 The MathWorks, Inc.

    methods
    end
    properties
        % Full path to the file associated with this shortcut
        File;

        % Group that this shortcut is in
        Group;

        % Name of this shortcut which is displayed on the toolstrip
        Name;

    end
end
