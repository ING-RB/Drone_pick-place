classdef TestRunCustomizationLiaison < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        RunnerOption (1,1) string
        RunnerOptionValue
    end

    methods
        function liaison = TestRunCustomizationLiaison(option, value)
            arguments
                option (1,1) string
                value (1,1)
            end
            liaison.RunnerOption = option;
            liaison.RunnerOptionValue = value;
        end
    end

end
