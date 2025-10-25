classdef EnableCommandWindowErrorsFixture < matlab.unittest.fixtures.Fixture
    %

    % Copyright 2024 The MathWorks, Inc.

    methods
        function setup(fixture)
            matlab.internal.regfwk.enableCommandWindowUserLogs(true);
        end

        function teardown(fixture)
            matlab.internal.regfwk.enableCommandWindowUserLogs(false);
        end
    end
end

