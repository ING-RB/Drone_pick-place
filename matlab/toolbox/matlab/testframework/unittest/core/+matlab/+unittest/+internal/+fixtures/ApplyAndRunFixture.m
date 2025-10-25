classdef ApplyAndRunFixture < matlab.unittest.fixtures.Fixture
%

%   Copyright 2024 The MathWorks, Inc.

    properties
        UserFixtures (1,:) matlab.unittest.fixtures.Fixture
    end

    methods
        function fixture = ApplyAndRunFixture(inputFixtures)
            fixture.UserFixtures = inputFixtures;
        end

        function setup(fixture)
            for f = fixture.UserFixtures
                fixture.applyFixture(f);
            end
        end
    end

    methods(Access=protected)
        function bool = isCompatible(~,~)
            bool = true;
        end
    end
end
