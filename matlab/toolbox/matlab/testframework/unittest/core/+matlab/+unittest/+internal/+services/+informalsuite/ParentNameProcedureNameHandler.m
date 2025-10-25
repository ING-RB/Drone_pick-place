classdef ParentNameProcedureNameHandler < matlab.unittest.internal.services.informalsuite.SingleTestHandler
    % ParentNameProcedureNameHandler - Create suite for a ParentName/ProcedureName combination.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        Precedence = matlab.unittest.internal.services.informalsuite.HandlerPrecedence.PortionCore;
    end

    properties (Access=private)
        % Cache factory for performance
        FactoryCache = dictionary(string.empty, struct("CanHandle",{}, "Factory",{}, "Name",{}));
    end

    methods (Access=protected)
        function bool = canHandle(handler, test)
            info = handler.getInfoFor(test);
            bool = info.CanHandle;
        end

        function suite = createSuiteForSingleTest(handler, test, rejector, options)
            import matlab.unittest.internal.addPathAndCurrentFolderFixturesIfNeeded;

            info = handler.getInfoFor(test);
            factory = info.Factory;
            suite = factory.createSuiteFromProcedureName(info.Name, rejector, options.ExternalParameters);
            suite = addPathAndCurrentFolderFixturesIfNeeded(suite);
        end
    end

    methods (Access=private)
        function info = getInfoFor(handler, test)
            if ~handler.FactoryCache.isKey(test)
                handler.updateCacheFor(test);
            end
            info = handler.FactoryCache(test);
        end

        function updateCacheFor(handler, test)
            import matlab.unittest.internal.NameParser;
            import matlab.unittest.internal.TestSuiteFactory;
            import matlab.unittest.internal.services.namingconvention.AllowsAnythingNamingConventionService;

            info.CanHandle = false;
            parser = NameParser(test);
            parser.parse;
            if parser.Valid && isempty(parser.TestMethodParameters) && isempty(parser.MethodSetupParameters) && isempty(parser.ClassSetupParameters)
                info.Factory = TestSuiteFactory.fromParentName(parser.ParentName, AllowsAnythingNamingConventionService);
                info.Name = parser.TestName;
                info.CanHandle = info.Factory.CreatesSuiteForValidTestContent && info.Factory.isValidProcedureName(parser.TestName);
            end
            handler.FactoryCache(test) = info;
        end
    end
end

% LocalWords:  namingconvention rejector
