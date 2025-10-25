classdef SharedTestFixtureAttribute < matlab.unittest.internal.selectors.SelectionAttribute
    % SharedTestFixtureAttribute - Attribute for TestSuite element shared test fixture.
    
    % Copyright 2013-2022 The MathWorks, Inc.
    
    methods
        function attribute = SharedTestFixtureAttribute(data)
            arguments
                data (1, :) cell
            end
            attribute@matlab.unittest.internal.selectors.SelectionAttribute(data);
        end

        function result = acceptsSharedTestFixture(attribute, selector)
            fixtureSets = attribute.Data;
            result = true(1, numel(fixtureSets));
            for setIdx = 1:numel(fixtureSets)
                result(setIdx) = selector.containsMatchingFixture(fixtureSets{setIdx});
            end
        end
    end
end
