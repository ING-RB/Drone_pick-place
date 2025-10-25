classdef TestFooterLiaison < handle
    %

    % Copyright 2022 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Suite matlab.unittest.Test;
        VariableName (1,1) string;
    end

    properties
        Footers (1,:) matlab.unittest.internal.diagnostics.FormattableString;
    end

    methods
        function liaison = TestFooterLiaison(suite, variableName)
            liaison.Suite = suite;
            liaison.VariableName = variableName;
        end
    end
end
