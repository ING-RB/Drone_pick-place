classdef CurrentFolderFixture < matlab.unittest.fixtures.Fixture
    % CurrentFolderFixture - Fixture for changing the current working folder.
    %
    %   CurrentFolderFixture(FOLDER) constructs a fixture for changing the
    %   current working folder to FOLDER. When the fixture is set up, the
    %   working folder is changed to FOLDER. When the fixture is torn down,
    %   the working folder is restored to its previous state.
    %
    %   CurrentFolderFixture methods:
    %       CurrentFolderFixture - Class constructor.
    %
    %   CurrentFolderFixture properties:
    %       Folder            - Character vector containing the folder to make the current working folder.
    %       StartingFolder    - Original folder location.
    %
    %   Example:
    %       classdef (SharedTestFixtures={matlab.unittest.fixtures.CurrentFolderFixture('helperFiles')}) ...
    %               testFoo < matlab.unittest.TestCase
    %           methods(Test)
    %               function test1(testCase)
    %                   % Test for Foo
    %               end
    %           end
    %       end
    %
    %   See also: PathFixture
    
    %  Copyright 2012-2023 The MathWorks, Inc.
    
    properties(SetAccess = immutable)
        % Folder - Character vector containing the folder to make the current working folder.
        %
        %   The Folder property is a character vector representing the absolute
        %   path to the folder that becomes the current working folder when the
        %   fixture is set up.
        Folder
    end
    
    properties(SetAccess = private)
        % StartingFolder - Character vector containing the original folder's location.
        %
        %   The StartingFolder property is a character vector representing the absolute
        %   path to the folder that is the original folder when the fixture is set up.
        StartingFolder = '';
    end
    
    methods
        function fixture = CurrentFolderFixture(folder)
            % CurrentFolderFixture - Class constructor.
            %
            %   FIXTURE = CurrentFolderFixture(FOLDER) constructs a fixture for making
            %   FOLDER the current working folder. FOLDER may refer to a relative or
            %   absolute path.
            
            import matlab.unittest.internal.fixtures.FolderScope;
            
            import matlab.unittest.internal.folderResolver;
            fixture.Folder = folderResolver(folder);
            fixture.FolderScope = FolderScope.Within;
        end
    end

    methods(Hidden)
        function setup(fixture)
            fixture.StartingFolder = cd(fixture.Folder);
            
            fixture.SetupDescription = getString(message('MATLAB:unittest:CurrentFolderFixture:SetupDescription', ...
                fixture.Folder));
        end
        
        function teardown(fixture)
            cd(fixture.StartingFolder);
            
            fixture.TeardownDescription = getString(message('MATLAB:unittest:CurrentFolderFixture:TeardownDescription', ...
                fixture.StartingFolder));
        end
    end
    
    methods (Hidden, Access=protected)
        function bool = isCompatible(fixture, other)
            bool = strcmp(fixture.Folder, other.Folder); 
        end
    end
end
