function suite = testSuiteFromAttributes(attributes)
% testSuiteFromAttributes Create a test suite from a struct array
% of test attributes
%   This method allows creating test suites directly by specifying the
%   following properties of TestCaseProvider as a struct.
%       * FullFilename           - Full path of parent test file
%       * TestParentName         - Name of test class
%       * TestName               - Name of test procedure
%       * Parameterization       - Array of matlab.unittest.parameter.Parameter objects
%       * Tags                   - Cell array of tags
%
%   The main purpose for this capability is to create test suites to
%   generate test reports for test elements that may no longer exist.

% Copyright 2024 The MathWorks, Inc.

    import matlab.unittest.Test;
    import matlab.unittest.internal.TestCaseAttributeProvider;

    narginchk(1,Inf);

    provider = TestCaseAttributeProvider(attributes);
    suite = Test.fromProvider(provider);
end