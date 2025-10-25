classdef SharedTestFixtureSetup
    % This class is undocumented and subject to change in a future release

    % Copyright 2023 The MathWorks, Inc.

    methods(Static)
        function testCase = applySharedTestFixtures(testCase)
            meta = metaclass(testCase);
            fixtures = matlab.unittest.internal.determineSharedTestFixturesFor(meta);
            for idx = 1:numel(fixtures)
                testCase.applyFixture(fixtures(idx));
            end

            % Set SharedTestFixtures_ on the testCase object so that
            % getSharedTestFixtures doesn't return empty
            testCase.SharedTestFixtures_ = fixtures;
        end
    end
end