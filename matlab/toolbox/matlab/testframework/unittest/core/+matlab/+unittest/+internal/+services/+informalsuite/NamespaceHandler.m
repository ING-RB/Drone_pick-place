classdef NamespaceHandler < matlab.unittest.internal.services.informalsuite.SingleTestHandler
    % NamespaceHandler - Create suite for namespace.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Constant)
        Precedence = matlab.unittest.internal.services.informalsuite.HandlerPrecedence.ContainerCore;
    end

    methods (Access=protected)
        function bool = canHandle(~, test)
            namespace = meta.package.fromName(test);
            bool = ~isempty(namespace);
        end

        function suite = createSuiteForSingleTest(~, test, rejector, options)
            import matlab.unittest.TestSuite;
            import matlab.unittest.internal.addPathAndCurrentFolderFixturesIfNeeded;

            namespace = meta.package.fromName(test);
            suite = TestSuite.fromNamespaceCore_(namespace, rejector, options.ExternalParameters, ...
                options.IncludeInnerNamespaces, InvalidFileFoundAction=options.InvalidFileFoundAction);
            suite = addPathAndCurrentFolderFixturesIfNeeded(suite);
        end
    end
end

% LocalWords:  rejector
