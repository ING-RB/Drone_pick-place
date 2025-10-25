classdef Shortcut
%Shortcut  Information about shortcuts in the current project
%    Return information about a shortcut in the currently loaded
%    project.
%
%    Example:
%
%    % Open the project Airframe example:
%    openExample("simulink/AirframeProjectExample")
%
%    % Get the project:
%    project = currentProject;
%
%    % Get the shortcuts:
%    shortcuts = project.Shortcuts

 
%   Copyright 2010-2023 The MathWorks, Inc.

    methods
    end
    properties
        Delegate;

        % Full path to the file associated with this shortcut
        File;

        % Group that this shortcut is in
        Group;

        % Name of this shortcut which is displayed on the toolstrip
        Name;

        % Determine if this shortcut runs at project shutdown
        RunAtShutdown;

        % Determine if this shortcut runs at project startup
        RunAtStartup;

    end
end
