classdef (Sealed) StopButtonHelper < handle
    % StopButtonHelper  Helper for accessing the underlying stop button from experiment.shared.view.StopButton
    
    %   Copyright 2022 The MathWorks, Inc.

    methods(Static)
        function button = getButton(component)
            button = component.UIHTML;
        end
    end
end