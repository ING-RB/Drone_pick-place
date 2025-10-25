classdef NameHandler < matlab.unittest.internal.services.informalsuite.SingleTestHandler
    % NameHandler - Create suite for test suite element name.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        Precedence = matlab.unittest.internal.services.informalsuite.HandlerPrecedence.PortionCore;
    end

    properties (Access=private)
        % For performance and to avoid redundant suite creation, cache
        % suite creation information across calls to various methods.
        SuiteCache = dictionary(string.empty, struct("CanHandle",{}, "Suite",{}, "Exception",{}));
    end

    methods (Access=protected)
        function bool = canHandle(handler, test)
            info = handler.getInfoFor(test);
            bool = info.CanHandle;
        end

        function exception = unhandledTestException(handler, test)
            info = handler.getInfoFor(test);
            exception = info.Exception;
        end

        function suite = createSuiteForSingleTest(handler, test, rejector, options)
            import matlab.unittest.internal.addPathAndCurrentFolderFixturesIfNeeded;

            % Raw suite is created no ExternalParameters. None can be used now, either.
            assert(isempty(options.ExternalParameters));

            info = handler.getInfoFor(test);
            rawSuite = info.Suite;
            suite = rejector.apply(rawSuite);
            suite = addPathAndCurrentFolderFixturesIfNeeded(suite);
        end
    end

    methods (Access=private)
        function info = getInfoFor(handler, test)
            if ~handler.SuiteCache.isKey(test)
                handler.updateCacheFor(test);
            end
            info = handler.SuiteCache(test);
        end

        function updateCacheFor(handler, test)
            import matlab.unittest.internal.NameParser;
            import matlab.unittest.Test;
            import matlab.unittest.internal.selectors.NeverFilterSelector;
            import matlab.unittest.parameters.Parameter;
            import matlab.unittest.internal.getFilenameFromParentName;

            canHandle = false;
            suite = Test.empty;
            exception = MException.empty;

            parser = NameParser(test);
            parser.parse;
            if parser.Valid
                try
                    suite = Test.fromName(test, NeverFilterSelector, Parameter.empty(1,0));
                    canHandle = true;
                catch exception
                    if ~any(exist(getFilenameFromParentName(parser.ParentName), "file") == [2,6])
                        % Only retain exception when the test file exists
                        exception = MException.empty;
                    end
                end
            end

            handler.SuiteCache(test) = struct("CanHandle",canHandle, "Suite",suite, "Exception",exception);
        end
    end
end

% LocalWords:  rejector
