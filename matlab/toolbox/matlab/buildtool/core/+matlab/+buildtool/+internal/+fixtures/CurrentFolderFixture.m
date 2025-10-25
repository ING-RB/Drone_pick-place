classdef CurrentFolderFixture < matlab.buildtool.internal.fixtures.Fixture
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Folder (1,1) string
    end

    properties (SetAccess = private)
        StartingFolder (1,1) string
    end

    methods
        function fixture = CurrentFolderFixture(folder)
            import matlab.automation.internal.folderResolver;
            fixture.Folder = folderResolver(folder);
        end

        function setup(fixture)
            fixture.StartingFolder = cd(fixture.Folder);
        end

        function teardown(fixture)
            cd(fixture.StartingFolder);
        end
    end
end