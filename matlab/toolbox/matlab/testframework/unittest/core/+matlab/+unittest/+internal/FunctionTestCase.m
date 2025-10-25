classdef (Hidden) FunctionTestCase < matlab.unittest.TestCase &  matlab.unittest.internal.Measurable
    
    %
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties
        % TestData - Property used to pass data between test functions.
        %
        %   The TestData property can be utilized by tests to pass data
        %   between fixture setup, test, and fixture teardown functions for
        %   tests created using functiontests. The default value of this
        %   property is a scalar structure with no fields. This allows a
        %   test writer to easily add test data as additional fields on
        %   this structure. However, the test author can reassign this
        %   value to any valid MATLAB value.
        TestData = struct;
    end
    
    properties(Hidden, SetAccess=protected)
        TestFcn
        SetupFcn
        TeardownFcn
        SetupOnceFcn
        TeardownOnceFcn
    end
    
    methods(Hidden, Static)
        function testCase = fromFunction(TestFcn, options)
            arguments
                TestFcn (1,1) {validateFcn}
                options.FunctionTestCaseType (1, 1) string = "matlab.unittest.FunctionTestCase";
                options.SetupFcn (1, 1) {validateFcn} = @matlab.unittest.internal.defaultFixtureFcn;
                options.TeardownFcn (1, 1) {validateFcn} = @matlab.unittest.internal.defaultFixtureFcn;
                options.SetupOnceFcn (1, 1) {validateFcn} = @matlab.unittest.internal.defaultFixtureFcn;
                options.TeardownOnceFcn (1, 1) {validateFcn} = @matlab.unittest.internal.defaultFixtureFcn;
            end
            testCase = feval(str2func(options.FunctionTestCaseType));
            testCase.TestFcn = TestFcn;
            testCase.SetupFcn = options.SetupFcn;
            testCase.TeardownFcn = options.TeardownFcn;
            testCase.SetupOnceFcn = options.SetupOnceFcn;
            testCase.TeardownOnceFcn = options.TeardownOnceFcn;
        end
    end    
    
    methods(Sealed, Hidden, TestClassSetup)
        function setupOnce(testCase)
            testCase.SetupOnceFcn(testCase);
        end
    end
    
    methods(Sealed, Hidden, TestClassTeardown)
        function teardownOnce(testCase)
            testCase.TeardownOnceFcn(testCase);
        end
    end
    
    methods(Sealed, Hidden, TestMethodSetup)
        function setup(testCase)
            testCase.SetupFcn(testCase);
        end
    end
    
    methods(Sealed, Hidden, TestMethodTeardown)
        function teardown(testCase)
            testCase.TeardownFcn(testCase);
        end
    end
    
    methods(Sealed, Hidden, Test)
        function test(testCase)
            testCase.TestFcn(testCase);
        end
    end
    
    
    methods(Access=protected)
        function testCase = FunctionTestCase
        end
    end
    
    methods (Sealed, Hidden)
        function testCase = copyFor(prototype,testFcn)
            testCase = copy(prototype);
            testCase.TestFcn = testFcn;
        end
    end    
end

function validateFcn(fcn)
    validateattributes(fcn, {'function_handle'}, {}, '', 'fcn');
    
    % Test/Fixture functions must accept exactly one input argument
    if nargin(fcn) ~= 1
        throw(MException(message('MATLAB:unittest:functiontests:MustAcceptExactlyOneInputArgument', func2str(fcn))));
    end
    
end

% LocalWords:  func
