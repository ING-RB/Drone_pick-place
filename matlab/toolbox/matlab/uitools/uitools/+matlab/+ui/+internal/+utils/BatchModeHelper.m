classdef(Hidden, Sealed) BatchModeHelper < handle
    % This class is undocumented and will change in a future release

    % This helper serves as a temporary solution for the dialog in Batch Mode
    % to ascertain whether the test author is utilizing a testing tool to
    % handle the upcoming dialog prompts
    %
    % Query whether dialog test tool is used
    % >> currentState = matlab.ui.internal.utils.BatchModeHelper.isTestToolUsed()
    %
    % Set isTestToolUsed to a value(true/false) and get its previous state
    % >> prevState = matlab.ui.internal.utils.BatchModeHelper.isTestToolUsed(value)

    % Copyright 2024 The MathWorks, Inc.

    methods (Static)

        function priorState = isTestToolUsed(flag)
            arguments
                flag (1,1) logical = false
            end

            persistent value;
            if isempty(value)
                value = false;
            end
            
            priorState = value;

            if nargin == 1
                value = flag;
            end

        end

    end

end