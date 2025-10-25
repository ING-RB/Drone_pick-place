classdef DefaultProjectFileErrorHandler < matlab.unittest.internal.ProjectFileErrorHandler
    %

    % Copyright 2022 The MathWorks, Inc.

    methods
        function handle(~, exception, filename)
            exc = MException(message("MATLAB:unittest:TestSuite:ProjectFileError", filename));
            exc = exc.addCause(exception);
            throwAsCaller(exc);
        end
    end
end

% LocalWords:  exc
