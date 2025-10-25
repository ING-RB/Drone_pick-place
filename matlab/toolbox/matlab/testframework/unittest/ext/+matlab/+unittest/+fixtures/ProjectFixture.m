classdef ProjectFixture < matlab.unittest.fixtures.Fixture
    % ProjectFixture - Fixture for loading a project.
    %
    %   ProjectFixture is a fixture for loading a project during execution of a 
    %   test suite. When the fixture is set up, the project is loaded if not
    %   loaded already. When the fixture is torn down, the project is closed if 
    %   the fixture loaded it, otherwise the project remains loaded. Only the 
    %   test framework constructs this class directly.
    %
    %   When the fixture is set up, no other project can be loaded. If another
    %   project is loaded when the fixture is set up, the fixture throws an
    %   error.
    %
    %   ProjectFixture properties:
    %       ProjectFolder - Character vector containing the root folder of the project to load.
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties(SetAccess=immutable)
        % ProjectFolder - String scalar containing the root folder of the project to load.
        %
        %   The ProjectFolder property is a string scalar representing the
        %   absolute path to the root folder of the project that is loaded when
        %   the fixture is set up.
        ProjectFolder
    end
    
    properties(Access=private)
        DidLoadProject
    end
    
    methods(Hidden)
        function fixture = ProjectFixture(projectFolder)
            import matlab.unittest.internal.projectFolderResolver;
            fixture.ProjectFolder = projectFolderResolver(projectFolder);
            fixture.DidLoadProject = false;
        end
        
        function setup(fixture)
            rootProject = matlab.project.rootProject;
            
            if isempty(rootProject)
                oldpath = path;
                fixture.addTeardown(@path, oldpath);
                
                project = openProject(fixture.ProjectFolder);
                fixture.DidLoadProject = true;

                if project.HasStartupErrors
                    error(message('MATLAB:unittest:ProjectFixture:ProjectHasStartupErrors', project.Name));
                end
                
                msg = message('MATLAB:unittest:ProjectFixture:SetupDescription', project.Name);
            else
                loadedProjects = rootProject;

                if ~strcmp(fixture.ProjectFolder, loadedProjects.RootFolder)
                    projectRefs = listAllProjectReferences(rootProject);
                    loadedProjects = [loadedProjects, projectRefs.Project];
                end
                
                tf = strcmp(fixture.ProjectFolder, [loadedProjects.RootFolder]);
                if ~any(tf)
                    error(message('MATLAB:unittest:ProjectFixture:DifferentProjectCurrentlyLoaded', fixture.ProjectFolder, rootProject.Name));
                end
                
                project = loadedProjects(find(tf,1));
                msg = message('MATLAB:unittest:ProjectFixture:NoSetupDescription', project.Name);
            end
            
            fixture.SetupDescription = getString(msg);
        end
        
        function teardown(fixture)
            rootProject = matlab.project.rootProject;
            
            if fixture.DidLoadProject && ~isempty(rootProject) && strcmp(fixture.ProjectFolder, rootProject.RootFolder)
                msg = message('MATLAB:unittest:ProjectFixture:TeardownDescription', rootProject.Name);
                rootProject.close();
            else
                msg = message('MATLAB:unittest:ProjectFixture:NoTeardownDescription');
            end
            
            fixture.TeardownDescription = getString(msg);
        end
    end
    
    methods(Hidden, Access=protected)
        function bool = isCompatible(fixture, other)
            bool = strcmp(fixture.ProjectFolder, other.ProjectFolder);
        end
    end
end
