classdef ProjectHandler < matlab.unittest.internal.services.informalsuite.SingleTestHandler
    % ProjectHandler - Create suite for a project folder.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        Precedence = matlab.unittest.internal.services.informalsuite.HandlerPrecedence.ContainerPre;
    end

    methods (Access=protected)
        function bool = canHandle(~, test)
            import matlab.unittest.internal.services.informalsuite.resolveFolderPossiblyOnPath;

            bool = false;
            if exist(test, "dir")
                folder = resolveFolderPossiblyOnPath(test);
                [underRoot, projectRoot] = slproject.isUnderProjectRoot(fullfile(folder, "resources"));
                bool = underRoot && strcmpi(folder, projectRoot);
            end
        end

        function suite = createSuiteForSingleTest(~, test, rejector, options)
            import matlab.unittest.internal.services.informalsuite.resolveFolderPossiblyOnPath;
            import matlab.unittest.internal.fromProjectCore_;

            suite = fromProjectCore_(resolveFolderPossiblyOnPath(test), ...
                rejector, options.ExternalParameters, options.IncludeReferencedProjects);
        end
    end
end

% LocalWords:  rejector isfile slproject Subfolders
