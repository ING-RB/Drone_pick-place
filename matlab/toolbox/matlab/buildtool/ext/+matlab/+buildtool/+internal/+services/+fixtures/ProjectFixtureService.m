classdef ProjectFixtureService < matlab.buildtool.internal.services.fixtures.FixtureService
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2023-2024 The MathWorks, Inc.

    methods
        function fixtures = provideFixtures(~, rootFolder)
            arguments
                ~
                rootFolder (1,1) string
            end

            import matlab.project.isUnderProjectRoot;
            import matlab.buildtool.internal.fixtures.Fixture;
            import matlab.buildtool.internal.fixtures.ProjectFixture;

            [underProject, projectRoot] = isUnderProjectRoot(fullfile(rootFolder,"*")); % g3429350
            if underProject
                fixtures = ProjectFixture(projectRoot);
            else
                fixtures = Fixture.empty();
            end
        end
    end
end
