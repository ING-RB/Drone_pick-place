classdef ParentNameHandler < matlab.unittest.internal.services.informalsuite.SingleTestHandler
    % ParentNameHandler - Create suite for identifier name.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (Constant)
        Precedence = matlab.unittest.internal.services.informalsuite.HandlerPrecedence.EntityCore;
    end

    properties (Access=private)
        % Cache factory for performance
        FactoryCache = dictionary(string.empty, {});
    end

    methods (Access=protected)
        function bool = canHandle(handler, test)
            factory = handler.getFactoryFor(test);
            bool = factory.CreatesSuiteForValidTestContent || ...
                isa(factory, "matlab.unittest.internal.InvalidTestFactory");
        end

        function suite = createSuiteForSingleTest(handler, test, rejector, options)
            import matlab.unittest.internal.addPathAndCurrentFolderFixturesIfNeeded;

            factory = handler.getFactoryFor(test);
            suite = factory.createSuiteFromParentName(rejector, options.ExternalParameters);
            suite = addPathAndCurrentFolderFixturesIfNeeded(suite);
        end
    end

    methods (Access=private)
        function factory = getFactoryFor(handler, test)
            if ~handler.FactoryCache.isKey(test)
                handler.updateCacheFor(test);
            end
            factoryCell = handler.FactoryCache(test);
            factory = factoryCell{1};
        end

        function updateCacheFor(handler, test)
            import matlab.unittest.internal.TestSuiteFactory;
            import matlab.unittest.internal.services.namingconvention.AllowsAnythingNamingConventionService;

            factory = TestSuiteFactory.fromParentName(test, AllowsAnythingNamingConventionService);
            handler.FactoryCache(test) = {factory};
        end
    end
end

% LocalWords:  namingconvention rejector
