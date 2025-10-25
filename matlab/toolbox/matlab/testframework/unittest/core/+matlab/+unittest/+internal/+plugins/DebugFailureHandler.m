classdef DebugFailureHandler < matlab.unittest.internal.plugins.FailureHandler
    %

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Constant, Access=private)
        LinePrinter = matlab.unittest.internal.plugins.LinePrinter(...
            matlab.unittest.plugins.ToStandardOutput);
    end

    methods
        function handleQualificationFailure(handler)
            handler.LinePrinter.printLine(getString(message("MATLAB:unittest:StopOnFailuresPlugin:PausedAtFailure")));
            matlab.unittest.internal.plugins.masked.pauseAtFailure;
        end
    end
end
