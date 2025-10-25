classdef CurrentProject< Simulink.ModelManagement.Project.ProjectManager
%CurrentProject  Provides access to the currently loaded Simulink Project.
%
% This function will be removed in a future release. Use currentProject
% and related functions instead.

 
%   Copyright 2010-2022 The MathWorks, Inc.

    methods
        function out=CurrentProject
        end

        function out=close(~) %#ok<STOUT>
        end

        function out=getCurrentProject(~) %#ok<STOUT>
        end

        function out=isProjectLoaded(~) %#ok<STOUT>
        end

        function out=loadProject(~) %#ok<STOUT>
            % This method loads the current project by specifying its fully
            % qualified, or partial, folder location.
            %
            % projectLocation - a string specifying the location
            % of the project, e.g. 'C:/projects/project1/'.
        end

    end
end
