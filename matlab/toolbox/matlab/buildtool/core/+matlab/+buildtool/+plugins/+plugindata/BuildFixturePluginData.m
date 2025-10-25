classdef (Hidden) BuildFixturePluginData < matlab.buildtool.plugins.plugindata.PluginData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = ?matlab.buildtool.BuildRunner)
        Description (1,1) string
    end

    properties (Access = ?matlab.buildtool.BuildRunner)
        Fixture matlab.buildtool.internal.fixtures.Fixture {mustBeScalarOrEmpty}
    end

    methods (Access = {?matlab.buildtool.BuildRunner, ?matlab.buildtool.plugins.plugindata.BuildFixturePluginData})
        function data = BuildFixturePluginData(name, description, fixture)
            arguments
                name (1,1) string
                description (1,1) string
                fixture (1,1) matlab.buildtool.internal.fixtures.Fixture
            end

            data@matlab.buildtool.plugins.plugindata.PluginData(name);

            data.Description = description;
            data.Fixture = fixture;
        end
    end
end

