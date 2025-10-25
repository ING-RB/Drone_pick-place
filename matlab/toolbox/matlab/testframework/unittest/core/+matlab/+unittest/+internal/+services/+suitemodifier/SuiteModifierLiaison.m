classdef SuiteModifierLiaison < handle
    %

    % Copyright 2021 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Options (1,1) struct;
        OnlySelectors (1,1) logical;
    end

    properties
        Modifier = matlab.unittest.internal.selectors.NeverFilterSelector;
    end

    methods
        function liaison = SuiteModifierLiaison(options, namedargs)
            arguments
                options;
                namedargs.OnlySelectors = false;
            end

            liaison.Options = options;
            liaison.OnlySelectors = namedargs.OnlySelectors;
        end
    end
end

