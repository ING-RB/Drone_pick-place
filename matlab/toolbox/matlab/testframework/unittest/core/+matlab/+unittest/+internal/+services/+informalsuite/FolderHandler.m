classdef FolderHandler < matlab.unittest.internal.services.informalsuite.SingleTestHandler
    % FolderHandler - Create suite for a folder.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        Precedence = matlab.unittest.internal.services.informalsuite.HandlerPrecedence.ContainerCore;
    end

    methods (Access=protected)
        function bool = canHandle(~, test)
            bool = exist(test, "dir");
        end

        function suite = createSuiteForSingleTest(~, test, rejector, options)
            import matlab.unittest.internal.services.informalsuite.resolveFolderPossiblyOnPath;
            import matlab.unittest.TestSuite;

            suite = TestSuite.fromFolderCore_(resolveFolderPossiblyOnPath(test), rejector, ...
                options.ExternalParameters, options.IncludeSubfolders, InvalidFileFoundAction=options.InvalidFileFoundAction);
        end
    end
end

% LocalWords:  rejector Subfolders
