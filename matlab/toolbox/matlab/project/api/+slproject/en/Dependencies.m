classdef Dependencies
%DEPENDENCIES Project dependency information
%   Dependencies between project files.

 
%   Copyright 2016-2023 The MathWorks, Inc.

    methods
        function out=update(~) %#ok<STOUT>
            %update Update project dependency graph
            %    Run a dependency analysis to update the known
            %    dependencies between project files.
            %
            %    Usage:
            %    update(project.Dependencies)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    update(project.Dependencies);
        end

    end
    properties
        % The graph of dependencies between project files
        Graph;

        Project;

    end
end
