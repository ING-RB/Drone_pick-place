classdef (Sealed) HasSharedTestFixture < matlab.unittest.internal.selectors.SingleAttributeSelector
    % HasSharedTestFixture - Select TestSuite elements that use a shared test fixture.
    %
    %   The HasSharedTestFixture selector filters TestSuite array elements
    %   based on the shared test fixtures used.
    %
    %   HasSharedTestFixture methods:
    %       HasSharedTestFixture - Class constructor
    %
    %   HasSharedTestFixture properties:
    %       ExpectedFixture - Shared test fixture that must be used.
    %
    %   Examples:
    %
    %       import matlab.unittest.selectors.HasSharedTestFixture;
    %       import matlab.unittest.fixtures.PathFixture;
    %       import matlab.unittest.fixtures.CurrentFolderFixture;
    %
    %       % Create a TestSuite to filter
    %       suite = TestSuite.fromNamespace('mynamespace');
    %
    %       % Select TestSuite array elements that use a PathFixture.
    %       newSuite = suite.selectIf(HasSharedTestFixture(PathFixture('helpers')));
    %
    %       % Select TestSuite array elements that do not use a PathFixture but
    %       % do use a CurrentFolderFixture.
    %       newSuite = suite.selectIf(~HasSharedTestFixture(PathFixture('helpers')) & ...
    %           HasSharedTestFixture(CurrentFolderFixture));
    %
    %   See also: matlab.unittest.TestSuite/selectIf
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties (SetAccess=private)
        % ExpectedFixture - Shared test fixture that must be used.
        %
        %   The ExpectedFixture property is a matlab.unittest.fixtures.Fixture
        %   instance that specifies a shared test fixture. In order to be retained,
        %   a TestSuite array element must use a fixture compatible with this property.
        ExpectedFixture (1,1) matlab.unittest.fixtures.Fixture = ...
            matlab.unittest.fixtures.EmptyFixture;
    end
    
    properties (Constant, Hidden, Access=protected)
        AttributeClassName = "matlab.unittest.internal.selectors.SharedTestFixtureAttribute";
        AttributeAcceptMethodName = "acceptsSharedTestFixture";
    end
    
    methods
        function selector = HasSharedTestFixture(fixture)
            % HasSharedTestFixture - Class constructor
            %
            %   selector = HasSharedTestFixture(FIXTURE) creates a selector that
            %   filters TestSuite array elements based on the fixtures used. FIXTURE
            %   can be any matlab.unittest.fixtures.Fixture instance. A TestSuite array
            %   element must use a fixture compatible with the specified fixture 
            %   in order to be retained.
            
            selector.ExpectedFixture = fixture;
        end
    end

    methods (Hidden)
        function result = containsMatchingFixture(selector, actualFixtures)
            result = containsEquivalentFixture(actualFixtures, selector.ExpectedFixture);
        end
    end
end

% LocalWords:  mynamespace
