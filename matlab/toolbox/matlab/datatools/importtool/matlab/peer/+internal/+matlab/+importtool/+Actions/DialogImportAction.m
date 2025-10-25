classdef DialogImportAction < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2020-2022 The MathWorks, Inc.

    methods(Static)
        function [offsetX, offsetY] = getDialogPosition(eventData)
            % in most cases we can just set the dialog's x and y coordinates to
            % what we receive from the JS code...
            offsetX = eventData.offsetX;
            offsetY = eventData.offsetY;
            if isfield(eventData, "windowX")
                % If passed in, the window's x,y position are in varargin
                windowX = eventData.windowX;
                windowY = eventData.windowY;
            else
                windowX = 0;
                windowY = 0;
            end

            % ...but in the case of an import tool in a CEF window, we need to
            % draw from the corner of the _screen_ instead of the corner of the
            % window as is done with the above general case. if we are not on
            % MATLAB online and we have a handle to a Browser, we can assume
            % that we are on the desktop and need to adjust for the browser's
            % position
            if eventData.isWindowPopup
                if windowX > 0 && windowY > 0
                    % Use the window's dimensions if provided
                    set(0, "units", "pixels");
                    ss = get(0, "screensize");

                    offsetX = windowX + eventData.offsetX;
                    offsetY = ss(4) - windowY - 50;
                end
            end

            % note that these cases don't place the dialog properly in the
            % connector workflow. this will be left as-is, because it is not
            % customer-facing, does not prevent functional testing of the add
            % rule feature, and would introduce an unnecessary point of failure
            % in released product to do a second check for whether we're on
            % MATLAB online and adjust in a second way in a second place
        end
    end
end
