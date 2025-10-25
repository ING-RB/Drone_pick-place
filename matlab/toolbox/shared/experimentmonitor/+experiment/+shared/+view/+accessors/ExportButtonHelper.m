classdef (Sealed) ExportButtonHelper < handle
    % ExportButtonHelper  Helper for accessing the underlying export button from experiment.shared.view.ExportButton
    
    %   Copyright 2022 The MathWorks, Inc.

    methods(Static)
        function button = getButton(component)
            button = component.Button;
        end
    end
end