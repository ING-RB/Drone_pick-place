classdef SingleTestHandler < matlab.unittest.internal.services.informalsuite.Handler
    % SingleTestHandler - Handler that creates a suite for a single test.

    % Copyright 2022 The MathWorks, Inc.

    methods (Abstract, Access=protected)
        suite = createSuiteForSingleTest(handler, rejector, options);
    end

    methods (Sealed)
        function suite = createSuite(handler, tests, options)
            import matlab.unittest.Test;

            modifier = options.Modifier;
            rejector = modifier.getRejector;

            suites = cell(size(tests));
            for idx = 1:numel(tests)
                suites{idx} = handler.createSuiteForSingleTest(tests(idx), rejector, options);
            end

            suite = [Test.empty, suites{:}];
            suite = modifier.apply(suite);
        end
    end
end

% LocalWords:  rejector
