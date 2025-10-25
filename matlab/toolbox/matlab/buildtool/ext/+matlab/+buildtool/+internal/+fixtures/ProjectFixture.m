classdef ProjectFixture < matlab.buildtool.internal.fixtures.Fixture
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        ProjectFolder (1,1) string
    end

    properties (Access = private)
        DidLoadProject (1,1) logical = false
    end

    methods
        function fixture = ProjectFixture(projectFolder)
            import matlab.automation.internal.folderResolver;
            fixture.ProjectFolder = folderResolver(projectFolder);
        end

        function setup(fixture)
            rootProject = matlab.project.rootProject;

            if isempty(rootProject)
                project = openProject(fixture.ProjectFolder);

                fixture.DidLoadProject = true;

                if project.HasStartupErrors
                    error(message("MATLAB:buildtool:ProjectFixture:ProjectHasStartupErrors", project.Name));
                end

                fixture.SetupDescription = string(message("MATLAB:buildtool:ProjectFixture:SetupDescription", project.Name));
            else
                loadedProjects = rootProject;

                if ~strcmp(fixture.ProjectFolder, loadedProjects.RootFolder)
                    projectRefs = listAllProjectReferences(rootProject);
                    loadedProjects = [loadedProjects, projectRefs.Project];
                end

                tf = strcmp(fixture.ProjectFolder, [loadedProjects.RootFolder]);
                if ~any(tf)
                    error(message("MATLAB:buildtool:ProjectFixture:DifferentProjectCurrentlyLoaded", fixture.ProjectFolder, rootProject.Name));
                end
            end
        end

        function teardown(fixture)
            rootProject = matlab.project.rootProject;
            
            if ~isempty(rootProject) && fixture.DidLoadProject && strcmp(fixture.ProjectFolder, rootProject.RootFolder)
                projectName = rootProject.Name;
                rootProject.close();
                fixture.TeardownDescription = string(message("MATLAB:buildtool:ProjectFixture:TeardownDescription", projectName));
            end
        end
    end
end