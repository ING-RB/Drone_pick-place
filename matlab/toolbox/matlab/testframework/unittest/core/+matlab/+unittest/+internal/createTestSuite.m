function suite = createTestSuite(tests, options)
%createTestSuite is undocumented function
%   Creates a testsuite for a given input

% Copyright 2023 The MathWorks, Inc.

arguments
    tests {matlab.unittest.internal.mustBeTextScalarOrTextArray, matlab.unittest.internal.mustContainCharacters}
    options (1,1) = matlab.unittest.internal.services.informalsuite.InformalSuiteCreationOptions
end

tests = string(tests);

availableHandlers = matlab.unittest.internal.services.informalsuite.getInformalSuiteHandlers;
handlersToUse = repmat(matlab.unittest.internal.services.informalsuite.HandlerPlaceholder, size(tests));
for k = 1:numel(tests)
    thisTest = tests(k);
    if strlength(deblank(thisTest)) == 0
        error(message("MATLAB:unittest:TestSuite:UnrecognizedSuite", thisTest));
    end
    handlersToUse(k) = availableHandlers.findFirstSupportedHandler(thisTest);
end

[uniqueHandlersToUse, ~, handlerIdx] = unique(handlersToUse);
suites = cell(1, numel(uniqueHandlersToUse));
for k = 1:numel(uniqueHandlersToUse)
    testsForHandler = tests(k == handlerIdx);
    suites{k} = uniqueHandlersToUse(k).createSuite(testsForHandler, options);
end
suite = [matlab.unittest.Test.empty, suites{:}];

suite = sortByFixtures(suite);
end