classdef PathFixture < matlab.unittest.fixtures.Fixture
    % PathFixture - Fixture for adding folders to the MATLAB path.
    %
    %   PathFixture(FOLDERS) constructs a fixture for adding FOLDERS to the
    %   MATLAB path. When the fixture is set up, FOLDERS is added to the path.
    %   When the fixture is torn down, the MATLAB path is restored to its
    %   previous state.
    %
    %   PathFixture methods:
    %       PathFixture - Class constructor.
    %
    %   PathFixture properties:
    %       Folders - String array containing the folders to be added to the path.
    %       IncludeSubfolders - Boolean that specifies whether the subfolders are added to path.
    %       Position - Character vector that specifies whether the folder is added at the beginning or end of the path.
    %
    %   Name/Value Options:
    %       Name                  Value
    %       ----                  -----
    %       IncludingSubfolders   False or true (logical 0 or 1) that specifies
    %                             whether subfolders are added to the
    %                             path. Default value is false.
    %       Position              Character vector ('begin' or 'end') that
    %                             specifies whether the folder is added at
    %                             the beginning or end of the path.
    %                             Default value is 'begin'.
    %
    %   Example:
    %       % Use PathFixture as a shared test fixture
    %       classdef (SharedTestFixtures={matlab.unittest.fixtures.PathFixture('helperFiles')}) ...
    %               testFoo < matlab.unittest.TestCase
    %           methods(Test)
    %               function test1(testCase)
    %                   % Test for Foo
    %               end
    %           end
    %       end
    %
    %   See also: CurrentFolderFixture
    
    %  Copyright 2012-2023 The MathWorks, Inc.
    
    properties(SetAccess=private)
        
        % Folders - String array containing the folders to be added to the path.
        %
        %   The Folders property is a String array representing the absolute
        %   paths to the folders that are added to the MATLAB path when the fixture is
        %   set up.
        Folders(1,:) string{mustBeNonempty} = missing;
    end
    
    properties(SetAccess=immutable)

        % IncludeSubfolders - Boolean that specifies whether the subfolders are added to path.
        %
        %   The IncludeSubfolders property is a boolean (true or false)
        %   that specifies whether the subfolders of the given folders
        %   are added to the path. This property is read only and can be
        %   set only through the constructor.
        IncludeSubfolders = false;
        
        % Position - Character vector that specifies whether the folders is added at the beginning or end of the path.
        %
        %   The Position property is a character vector specified as 'begin' or
        %   'end' that indicates whether the folders are added to the beginning or
        %   the end of the path.
        Position = 'begin';
    end
    
    properties(SetAccess=immutable,Dependent,Hidden)
        % Folder - Character vector containing the folder to be added to the path.
        %
        %   The Folder property is a character vector representing the absolute
        %   path to the folder that is added to the MATLAB path when the fixture is
        %   set up.
        Folder
    end
    
    
    properties(Access=private)
        StartPath
        
    end
    
    methods
        function fixture = PathFixture(folders, options)
            % PathFixture - Class constructor.
            %
            %   FIXTURE = PathFixture(FOLDERS) constructs a fixture for adding FOLDERS to
            %   the MATLAB path. Folders might be specified using relative or absolute paths.
            %
            %   FIXTURE = PathFixture(FOLDERS, 'IncludingSubfolders', true) constructs
            %   a fixture for adding FOLDERS and their subfolders to the MATLAB path.
            %
            %   FIXTURE = PathFixture(FOLDERS, 'Position', POSITION) constructs
            %   a fixture for adding FOLDERS to the specified POSITION on
            %   the path. The value of POSITION can be either 'begin' or
            %   'end'. 'begin' adds FOLDERS to the top of the path 
            %   and 'end' adds them to the bottom of the path. If this option 
            %   is used with 'IncludingSubfolders', FOLDERS and their subfolders 
            %   are added to the top or bottom of the path as a single 
            %   block with FOLDERS on top.
            arguments
                folders string {mustBeNonempty, mustBeNonzeroLengthText}
                options.IncludingSubfolders (1,1) logical
                options.IncludeSubfolders (1,1) logical
                options.Position (1,1) string {mustBeMember(options.Position,["begin","end"]), matlab.unittest.internal.mustBeTextScalar} = "begin";
            end

            import matlab.unittest.internal.folderResolver;
            import matlab.unittest.internal.resolveAliasedLogicalParameters;

            fixture.Folders = string(cellfun(@folderResolver,folders,'UniformOutput', false));
            fixture.Folders = unique(fixture.Folders,'stable');
            fixture.IncludeSubfolders = resolveAliasedLogicalParameters(options, ...
                ["IncludingSubfolders", "IncludeSubfolders"]);
            fixture.Position = char(options.Position);
        end
               
        function folder = get.Folder(fixture)
            folder = fixture.Folders{1};
        end
        
        function set.Folder(fixture, folder)    
            fixture.Folders = string(folder);
        end
    end

    methods(Hidden)                            
        function setup(fixture)
            
            if fixture.IncludeSubfolders
                pathsToBeAdded = strjoin((arrayfun(@genpath, fixture.Folders,'UniformOutput',false)),'');
                cellSetupDescription = arrayfun(@(x) getString(message('MATLAB:unittest:PathFixture:SetupDescriptionSubfolders'...
                    ,x)),fixture.Folders,'UniformOutput',false);
            else
                pathsToBeAdded = strjoin(fixture.Folders,pathsep);
                cellSetupDescription = arrayfun(@(x) getString(message('MATLAB:unittest:PathFixture:SetupDescription'...
                    ,x)),fixture.Folders,'UniformOutput',false);
            end
            fixture.SetupDescription = strjoin(cellSetupDescription, newline);
            fixture.StartPath = addpath(pathsToBeAdded, ['-' fixture.Position]);
        end
        
        function teardown(fixture)
            path(fixture.StartPath);
            
            fixture.TeardownDescription = getString(message('MATLAB:unittest:PathFixture:TeardownDescription'));
        end
    end
    
    methods (Hidden, Access=protected)
        function bool = isCompatible(fixture, other)
            bool = isequal(sort(fixture.Folders),sort(other.Folders)) && isequal(fixture.IncludeSubfolders, other.IncludeSubfolders) ...
                                                        && strcmp(fixture.Position, other.Position);
        end
    end
end
