classdef InvalidTestFactory < matlab.unittest.internal.TestSuiteFactory
    % This class is undocumented.

    % InvalidTestFactory - Factory for creating suites for invalid test entities.

    % Copyright 2014-2022 The MathWorks, Inc.

    properties(Constant)
        CreatesSuiteForValidTestContent = false;
        SupportsParameterizedTests = true;
    end

    properties (Access=private)
        ParentName
        Exception
    end

    methods
        function factory = InvalidTestFactory(parentName, exception)
            factory.ParentName = parentName;
            factory.Exception = exception;
        end

        function suite = createSuiteExplicitly(factory, varargin) %#ok<STOUT>
            throwAsCaller(factory.Exception);
        end

        function suite = createSuiteImplicitly(factory, ~, ~, nvpairs)
            arguments
                factory
                ~
                ~
                nvpairs.InvalidFileFoundAction {mustBeMember(nvpairs.InvalidFileFoundAction,["error","warn"])} = "warn"
            end

            import matlab.unittest.internal.diagnostics.indent;
            import matlab.unittest.internal.whichFile;

            if strcmp(nvpairs.InvalidFileFoundAction,"error")
                throwAsCaller(factory.Exception);
            end

            try
                file = whichFile(factory.ParentName);
            catch
                file = factory.ParentName;
            end

            warning(message('MATLAB:unittest:TestSuite:FileExcluded', ...
                file, indent(factory.Exception.message)));
            suite = matlab.unittest.Test.empty;
        end
    end
end