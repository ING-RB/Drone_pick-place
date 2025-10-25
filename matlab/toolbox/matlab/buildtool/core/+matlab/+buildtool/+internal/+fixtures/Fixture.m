classdef Fixture < ...
        matlab.buildtool.internal.BuildContent & ...
        matlab.mixin.Heterogeneous
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = protected)
        SetupDescription (1,1) string
        TeardownDescription (1,1) string
    end

    methods (Abstract)
        setup(fixture)
    end
    
    methods
        function teardown(fixture) %#ok<MANU>
        end
    end
end