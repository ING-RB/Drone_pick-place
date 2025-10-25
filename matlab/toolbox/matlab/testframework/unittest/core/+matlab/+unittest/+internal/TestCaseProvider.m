classdef(Hidden) TestCaseProvider
    % Class to help abstract different ways to provide testCases. This is
    % used when constructing TestSuite, some of which have a TestCase
    % prototype and some of which only have the TestCase meta classes.
    
    % Copyright 2012-2022 The MathWorks, Inc.
    
    properties(Abstract, SetAccess=immutable)
        TestClass
        TestParentName
        TestMethodName
        TestName
    end
    
    properties(Abstract, SetAccess=private)
        SharedTestFixtures
        Parameterization
        Tags
    end

    properties (SetAccess=protected)
        InternalSharedTestFixtures = matlab.unittest.fixtures.EmptyFixture.empty;
        NumInputParameters = 0;
    end

    properties (SetAccess=private)
        % RelativeFilename - Filename relative to the BaseFolder.
        RelativeFilename (1,1) string = missing;
    end
    
    methods(Abstract)
        testCase = provideClassTestCase(provider);
        testCase = createTestCaseFromClassPrototype(provider, classTestCase);
    end
        
    methods
        function baseFolder = getBaseFolder(provider)
            import matlab.unittest.internal.getBaseFolderFromParentName;
            baseFolder = getBaseFolderFromParentName(provider.TestParentName);
        end

        function superClasses = getSuperclasses(~)
            superClasses = string.empty;
        end
        
        function bool = supportsThreadBasedPools(~)
            bool = false;
        end
    end
    
    methods (Access = protected)
        function testClass = getDefaultTestClass(~)
            testClass = string.empty;
        end

        function providers = setFullFilename(providers, filename)
            import matlab.unittest.internal.getBaseFolderFromFilename;

            % Store only the relative filename to accommodate scenarios where the base
            % folder changes after suite creation (e.g., parallel test running).
            [providers.RelativeFilename] = deal(filename.extractAfter(getBaseFolderFromFilename(filename)));
        end
    end
end
