classdef Selector < matlab.unittest.internal.selectors.Modifier
    
    % Selector - Interface for TestSuite selection.
    
    % Copyright 2013-2024 The MathWorks, Inc.

    methods (Hidden, Abstract)
        % uses - Returns a boolean indicating whether the selector uses a specified attribute.
        %
        %   The uses method provides the selector the opportunity to specify which
        %   attributes it uses when filtering a suite.
        bool = uses(selector, attributeClass)
        
        % select - Filter suite elements.
        %
        %   The select method returns the result of filtering a suite. It
        %   is passed a matlab.unittest.internal.selectors.AttributeSet
        %   representing data of interest for a number of TestSuite array
        %   elements. The select method must return a logical array
        %   containing true (select) or false (filter) for each suite
        %   element. When passed the full attribute set, this method must
        %   definitively determine whether the suite element is to be
        %   included or not.
        bool = select(selector, attributeSet)
        
        % reject - Filter suite elements.
        %
        %   The reject method returns the result of filtering a suite based
        %   on a matlab.unittest.internal.selectors.AttributeSet containing
        %   a subset of used attributes. It returns an array of logical
        %   where true indicates the selector can use the supplied
        %   attributes to definitively reject (filter) a suite element. If
        %   it is possible to select the suite element in the presence of
        %   additional attributes, this method must return false.
        bool = reject(selector, attributeSet)
    end
    
    methods (Abstract)
        % not - Logical negation of a selector.
        %
        %   not(selector) returns a selector that is the boolean complement of the
        %   selector provided. This is a means to specify that a suite element
        %   should be retained if it does not satisfy a selection criterion.
        %
        %   Typically, the NOT method is not called directly, but the MATLAB "~"
        %   operator is used to denote the negation of any given selector.
        %
        %   Examples:
        %
        %       import matlab.unittest.TestSuite;
        %       import matlab.unittest.selectors.HasSharedTestFixture;
        %       import matlab.unittest.selectors.HasParameter;
        %       import matlab.unittest.fixtures.PathFixture;
        %
        %       % Create a TestSuite to filter
        %       suite = TestSuite.fromNamespace('mynamespace');
        %
        %       % Select suite elements that are not parameterized.
        %       newSuite = suite.selectIf(~HasParameter);
        %
        %       % Select suite elements that do not use a PathFixture.
        %       newSuite = suite.selectIf(~HasSharedTestFixture(PathFixture(pwd)));
        %
        %   See also: and, or
        notSelector = not(selector);
    end
    
    methods (Hidden)
        function bool = negatedReject(~, attributeSet)
            % bool = negatedReject(selector, attributeSet) returns true if the negated
            % selector rejects the attributes.
            bool = false(1, attributeSet.AttributeDataLength);
        end
    end
    
    methods (Sealed)
        function andSelector = and(firstSelector, secondSelector)
            % and - Logical conjunction of two selectors.
            %
            %   and(selector1, selector2) returns a selector which is the boolean
            %   conjunction of selector1 and selector2. This is a means to specify that
            %   a suite element must satisfy two selection criteria.
            %
            %   Typically, the AND method is not called directly, but the MATLAB "&"
            %   operator is used to denote the conjunction of any two selector objects.
            %
            %   Example:
            %
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.selectors.HasSharedTestFixture;
            %       import matlab.unittest.selectors.HasParameter;
            %       import matlab.unittest.fixtures.PathFixture;
            %
            %       % Create a TestSuite to filter
            %       suite = TestSuite.fromNamespace('mynamespace');
            %
            %       % Select suite elements that are parameterized AND use a PathFixture.
            %       newSuite = suite.selectIf(HasParameter & HasSharedTestFixture(PathFixture(pwd)));
            %
            %   See also: or, not

            andSelector = andWithSelector(secondSelector, firstSelector);
        end

        function orSelector = or(firstSelector, secondSelector)
            % or - Logical disjunction of two selectors.
            %
            %   or(selector1, selector2) returns a selector which is the boolean
            %   disjunction of selector1 and selector2. This is a means to specify that
            %   a suite element must satisfy either of two selection criteria.
            %
            %   Typically, the OR method is not called directly, but the MATLAB "|"
            %   operator is used to denote the disjunction of any two selectors
            %   objects.
            %
            %   Example:
            %
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.selectors.HasSharedTestFixture;
            %       import matlab.unittest.selectors.HasParameter;
            %       import matlab.unittest.fixtures.PathFixture;
            %
            %       % Create a TestSuite to filter
            %       suite = TestSuite.fromNamespace('mynamespace');
            %
            %       % Select suite elements that are parameterized OR use a PathFixture.
            %       newSuite = suite.selectIf(HasParameter | HasSharedTestFixture(PathFixture(pwd)));
            %
            %   See also: and, not

            orSelector = orWithSelector(secondSelector, firstSelector);
        end
    end

    methods (Hidden, Sealed)
        function selected = apply(selector, suite)
            selected = suite.selectIfCore_(selector);

            % Retain shape if possible
            if numel(selected) == numel(suite)
                selected = reshape(selected, size(suite));
            end
        end

        function rejector = getRejector(selector)
            import matlab.unittest.internal.selectors.RejectorDecorator;
            rejector = RejectorDecorator(selector);
        end
    end

    methods (Hidden, Sealed, Access=protected)
        function andSelector = andWithSelector(secondSelector, firstSelector)
            import matlab.unittest.selectors.AndSelector;
            andSelector = AndSelector(firstSelector, secondSelector);
        end

        function orSelector = orWithSelector(secondSelector, firstSelector)
            import matlab.unittest.selectors.OrSelector;
            orSelector = OrSelector(firstSelector, secondSelector);
        end

        function combined = andWithModifier(secondSelector, firstModifier)
            combined = andWithSelector(firstModifier, secondSelector);
        end
    end
end

% LocalWords:  mynamespace
