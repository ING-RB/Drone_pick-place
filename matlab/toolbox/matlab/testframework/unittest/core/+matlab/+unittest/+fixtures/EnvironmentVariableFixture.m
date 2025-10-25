classdef EnvironmentVariableFixture < matlab.unittest.fixtures.Fixture
    % EnvironmentVariableFixture - Fixture for setting environment variable
    %
    %   EnvironmentVariableFixture(NAME,VALUE) creates a fixture for
    %   setting the value of the environment variable NAME to VALUE. When
    %   the testing framework sets up the fixture, if NAME exists as an
    %   environment variable, then the framework replaces its current value
    %   with VALUE. If NAME does not exist, then the framework creates an
    %   environment variable called NAME and assigns VALUE to it. When the
    %   framework tears down the fixture, it restores the operating system
    %   environment variable list to its previous state.
    %
    %   EnvironmentVariableFixture methods:
    %       EnvironmentVariableFixture - Class constructor
    %
    %   EnvironmentVariableFixture properties:
    %       Name - Environment variable name
    %       Value - Environment variable value
    %
    %   Example:
    %   classdef ExampleTest < matlab.unittest.TestCase
    %       methods (Test)
    %           function test1(testCase)
    %               import matlab.unittest.fixtures.EnvironmentVariableFixture
    %               % Create a fixture
    %               f = EnvironmentVariableFixture("Name","Alex");
    %               disp("Initial value of the environment variable " + f.Name + ": " + getenv(f.Name))
    %               % Apply the fixture
    %               testCase.applyFixture(f)
    %               disp("Updated value of the environment variable " + f.Name + ": " + getenv(f.Name))
    %           end
    %       end
    %   end

    %  Copyright 2022 The MathWorks, Inc.

    properties(SetAccess=immutable)
        % Name - Environment variable name
        %
        %   Environment variable name, returned as string scalar. Specify
        %   the value of this property during creation of the fixture.
        Name (1,1) string;

        % Value - Environment variable value
        %
        %   Environment variable value, returned as string scalar. Specify
        %   the value of this property during creation of the fixture.
        Value (1,1) string;
    end

    properties (Constant, Access=private)
        Catalog = matlab.internal.Catalog("MATLAB:unittest:EnvironmentVariableFixture");
    end

    methods
        function fixture = EnvironmentVariableFixture(name, value)
            % EnvironmentVariableFixture - Class constructor
            %
            %   FIXTURE = matlab.unittest.fixtures.EnvironmentVariableFixture(NAME,VALUE)
            %   creates a fixture for setting the value of the environment
            %   variable NAME to VALUE. Specify the name and value of the
            %   environment variable as string scalars.

            % Check input arguments
            arguments
                name  {mustBeNonempty, mustBeTextScalar, mustBeNonmissing, mustBeNonzeroLengthText};
                value {mustBeTextScalar, mustBeNonmissing};
            end

            % Set the environment variable to a new value on fixture setup
            fixture.Name = name;
            fixture.Value = value;
        end
    end

    methods (Hidden)
        function setup(fixture)
            if isenv(fixture.Name)
                initialName = lookupInitialName(fixture.Name);
                initialValue = getenv(fixture.Name);
                fixture.addTeardown(@setenv, initialName, initialValue);
                fixture.SetupDescription = fixture.Catalog.getString("SetupDescription", fixture.Name, initialValue, fixture.Value);
                fixture.TeardownDescription = fixture.Catalog.getString("TeardownDescriptionRestore", initialName, fixture.Value, initialValue);
            else
                fixture.addTeardown(@unsetenv, fixture.Name);
                fixture.SetupDescription = fixture.Catalog.getString("SetupDescriptionInitializeValue", fixture.Name, fixture.Value);
                fixture.TeardownDescription = fixture.Catalog.getString("TeardownDescriptionUnset", fixture.Name);
            end

            setenv(fixture.Name, fixture.Value);
        end
    end

    methods (Hidden, Access=protected)
        function bool = isCompatible(fixture, otherFixture)
            bool = strcmp(fixture.Name, otherFixture.Name) && ...
                strcmp(fixture.Value, otherFixture.Value) ;
        end
    end
end

function name = lookupInitialName(name)
if ispc
    allNames = getenv().keys;
    index = find(strcmpi(allNames, name), 1, "first");
    name = allNames(index);
end
end

% LocalWords:  Nonmissing isenv unsetenv oss
