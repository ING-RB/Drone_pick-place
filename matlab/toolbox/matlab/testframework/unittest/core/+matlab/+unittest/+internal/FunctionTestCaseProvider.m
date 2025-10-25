classdef(Hidden) FunctionTestCaseProvider < matlab.unittest.internal.TestCaseProvider
    % FunctionTestCaseProvider is a TestCaseProvider that holds onto a
    % TestCase instance.
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(SetAccess=immutable, GetAccess=private)
        TestCase
    end
    
    properties(Dependent, SetAccess=immutable)
        TestClass
        TestParentName
        TestName
    end
    
    properties (SetAccess=private)
        Parameterization = matlab.unittest.parameters.EmptyParameter.empty;
        SharedTestFixtures = matlab.unittest.fixtures.EmptyFixture.empty;
        Tags = cell(1,0);
    end
    
    properties(Transient, SetAccess=immutable)
        TestMethodName = 'test';
    end
    
    methods
        function provider = FunctionTestCaseProvider(testFcns, testType, varargin)
            import matlab.unittest.internal.FunctionTestCaseProvider;
            import matlab.unittest.internal.determineSharedTestFixturesFor;
            import matlab.unittest.internal.FunctionTestCase;
            
            if nargin == 0
                % Allow pre-allocation
                return
            end
            
            numElements = numel(testFcns);
            if numElements > 0
                functionTestCase = getFunctionTestCase(testType);
                
                provider(numElements) = FunctionTestCaseProvider;
                testCaseCell = cellfun(@(fcn) FunctionTestCase.fromFunction(fcn, varargin{:}, FunctionTestCaseType=functionTestCase), testFcns, ...
                                       'UniformOutput', false);                
                [provider.TestCase] = testCaseCell{:};

                % functiontests validates that at least one test function
                % exists in the test file. fromFunction must return
                % TestCases that all belong to the same class. Thus, we can
                % get the metaclass by looking at the first element.
                mcls = metaclass(testCaseCell{1});
                [provider.SharedTestFixtures] = deal(determineSharedTestFixturesFor(mcls));

                provider = provider.setFullFilename(string(functions(testFcns{1}).file));
            end
            provider = reshape(provider, size(testFcns));
        end
        
        function testCase = provideClassTestCase(provider)
            % Create a copy to keep each run independent
            testCase = copy(provider.TestCase);
        end
        
        function testCase = createTestCaseFromClassPrototype(provider, prototype) 
              testCase = prototype.copyFor(provider.TestCase.TestFcn);
        end
        
        function bool = supportsThreadBasedPools(~)
            bool = true;
        end

        function testClass = get.TestClass(provider)
            testClass = provider.getDefaultTestClass;
        end
        
        function testParentName = get.TestParentName(provider)
            import matlab.unittest.internal.getParentNameFromFilename;
            fcnInfo = functions(provider.TestCase.TestFcn);
            testParentName = getParentNameFromFilename(fcnInfo.file);
        end
        
        function testName = get.TestName(provider)
            testName = func2str(provider.TestCase.TestFcn);
        end
    end
    
end

function functionTestCase = getFunctionTestCase(testType)
import matlab.automation.internal.services.ServiceLocator
import matlab.unittest.internal.services.ServiceFactory
import matlab.unittest.internal.services.functiontestcase.FunctionTestCaseLiaison

namespace = 'matlab.unittest.internal.services.functiontestcase';
locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
serviceClass = ?matlab.unittest.internal.services.functiontestcase.FunctionTestCaseService;

locatedServiceClasses = locator.locate(serviceClass);
locatedServices = ServiceFactory.create(locatedServiceClasses);

liaison = FunctionTestCaseLiaison(testType);
fulfill(locatedServices,liaison);

functionTestCase = liaison.FunctionTestCase;

end

% LocalWords:  func functiontestcase Casefrom mcls
