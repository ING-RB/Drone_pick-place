classdef UIControlFrameController < matlab.ui.internal.controller.uicontrol.UIControlController
    % UIControlTextController Web-based controller for uicontrol frame.

    %   Copyright 2023 The MathWorks, Inc.
    methods
        function className = getViewModelType(~, ~)
            className = 'matlab.ui.container.UIControlPanel';
        end
    end
end