classdef MATLABCodeFileHandler < matlab.unittest.internal.services.informalsuite.SingleTestHandler
    % MATLABCodeFileHandler - Informal suite creation from MATLAB files.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        Precedence = matlab.unittest.internal.services.informalsuite.HandlerPrecedence.EntityCore;
    end

    methods (Access=protected)
        function bool = canHandle(~, test)
            bool = any(exist(test, "file") == [2,6]);
        end

        function suite = createSuiteForSingleTest(~, test, rejector, options)
            import matlab.unittest.TestSuite;
            import matlab.unittest.internal.whichFile;

            file = whichFile(test);
            if isempty(file)
                file = test;
            end

            suite = TestSuite.fromFileCore_(file, rejector, options.ExternalParameters);
        end
    end
end

% LocalWords:  rejector
