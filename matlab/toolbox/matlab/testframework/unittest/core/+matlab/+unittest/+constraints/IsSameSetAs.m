classdef IsSameSetAs < matlab.unittest.internal.constraints.SubsetSupersetConstraint & ...
                       matlab.unittest.internal.mixin.RespectingCountMixin
    % IsSameSetAs - Constraint specifying a set that contains the same elements as another set
    %
    %   The IsSameSetAs constraint produces a qualification failure for any
    %   actual value that is not the same set as the expected set. An actual
    %   value is considered the same set as the expected set if
    %   ismember(actual,expected) and ismember(expected,actual) both return
    %   arrays that contain all true values and one of the following conditions
    %   is met:
    %       * The actual value and the expected set are of the same class.
    %       * The actual value is an object.
    %       * The expected set is an object.
    %
    %   IsSameSetAs methods:
    %       IsSameSetAs - Class constructor
    %
    %   IsSameSetAs properties:
    %       ExpectedSet - Set to compare to the actual value
    %       RespectCount - Whether to respect element count
    %
    %   Examples:
    %       import matlab.unittest.constraints.IsSameSetAs;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat(["b","c","b"], IsSameSetAs(["c","b","c"]));
    %
    %       testCase.fatalAssertThat(zeros(3,4,2), IsSameSetAs(zeros(1,3)));
    %
    %       % Test while respecting the element count
    %       testCase.verifyThat(["b","c","b","c"], ...
    %       IsSameSetAs(["c","b","c","b"],RespectingCount=true));
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.assertThat({'a';'d'}, IsSameSetAs({'a','b','c'}));
    %
    %       testCase.verifyThat(20:40, IsSameSetAs(25:35));
    %
    %       testCase.assumeThat(single(1:3), IsSubsetOf(1:3));
    %
    %       % Test while respecting the element count
    %       testCase.verifyThat(["b","c","b"], ...
    %       IsSameSetAs(["c","b","c"],RespectingCount=true));
    %
    %   See also:
    %       ISSUBSETOF
    %       ISSUPERSETOF
    %       ISMEMBER
    
    %  Copyright 2017-2023 The MathWorks, Inc.
    
    properties(Dependent, SetAccess=private)
        % ExpectedSet - Set to compare to the actual value
        ExpectedSet
    end
    
    properties(Hidden,Access=protected)
        Expected
    end
    
    properties(Hidden,Constant,Access=protected)
        Catalog = matlab.internal.Catalog('MATLAB:unittest:IsSameSetAs');
        DoSubsetCheck = true;
        DoSupersetCheck = true;
    end
    
    methods
        function expectedSet = get.ExpectedSet(constraint)
            expectedSet = constraint.Expected;
        end
        
        function constraint = IsSameSetAs(expectedSet, varargin)
            % IsSameSetAs - Class constructor
            %
            %   IsSameSetAs(EXPECTEDSET) creates a constraint that determines if a
            %   value is the same set as EXPECTEDSET.
            %
            %   IsSameSetAs(..., RespectingCount=true) creates a constraint that
            %   is also sensitive to the element count. When you use this syntax,
            %   the test fails if an element occurs different numbers of times in
            %   the actual and expected sets. By default, the constraint does not
            %   respect the element count.
            
            constraint.Expected = expectedSet;
            constraint = constraint.parse(varargin{:});
        end
    end

    methods(Hidden,Sealed,Access=protected)
        function args = getInputArguments(constraint)
            args = {constraint.Expected};
            if constraint.RespectCount
                args = [args,{'RespectingCount',true}];
            end
        end

        function bool = doCountCheck(constraint)
            bool = constraint.RespectCount;
        end
    end
end

% LocalWords:  unittest ISSUBSETOF ISSUPERSETOF EXPECTEDSET
