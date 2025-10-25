classdef(Hidden) TestCaseAttributeProvider < matlab.unittest.internal.TestCaseProvider
    % TestCaseAttributeProvider is a TestCaseProvider that initializes test
    % attributes from values contained in a struct array. This class only
    % sets properties necessary to create TestSuites for the
    % purposes of report generation. TestSuites created from this
    % TestCaseProvider are not expected to be runnable.

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess=private)
        SharedTestFixtures = matlab.unittest.fixtures.EmptyFixture.empty; % not needed for reporting
        Parameterization = matlab.unittest.parameters.EmptyParameter.empty;
        Tags = cell(1,0);
    end

    properties (SetAccess=immutable)
        Superclasses = string.empty % not needed for reporting
    end

    properties (SetAccess=immutable)
        TestParentName
        TestName
        FullFilename % Used to compute BaseFolder and RelativeFilename
        TestClass
        TestMethodName
    end

    methods
        function provider = TestCaseAttributeProvider(attributeStructArray)
            import matlab.unittest.internal.TestCaseAttributeProvider;
            import matlab.unittest.parameters.Parameter;

            if nargin == 0
                % Allow pre-allocation
                return
            end

            numElements = numel(attributeStructArray);
            if numElements > 0
                provider(numElements) = TestCaseAttributeProvider;
                [provider.TestParentName] = attributeStructArray.TestParentName;
                [provider.TestName] = attributeStructArray.TestName;
                [provider.Tags] = attributeStructArray.Tags;
                [provider.Parameterization] = attributeStructArray.Parameterization;
                [provider.FullFilename] = attributeStructArray.FullFilename;
                [provider.TestClass] = attributeStructArray.TestParentName;
                [provider.TestMethodName] = attributeStructArray.TestName;
                provider = arrayfun(@(p) p.setFullFilename(string(p.FullFilename)), provider);
            end
        end

        % Intentionally not implemented. This test suite is not runnable.
        testCase = provideClassTestCase(~)
        testCase = createTestCaseFromClassPrototype(~,~)

        % Override base folder getter since default implementation uses
        % 'which' to find the folder on the path
        function baseFolder = getBaseFolder(provider)
            baseFolder = matlab.automation.internal.getBaseFolderFromFilename(provider.FullFilename);
        end
    end
end

