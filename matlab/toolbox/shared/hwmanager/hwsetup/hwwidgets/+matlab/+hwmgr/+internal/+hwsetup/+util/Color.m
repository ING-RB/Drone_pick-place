classdef Color
    % matlab.hwmgr.internal.hwsetup.util.Color is a class that
    % defines a mapping between color and its RGB triplet/semantic for easy lookup

    % Recommendation is to use semantic variables which will change colors
    % as per the current MATLAB Theme.
    
    % Copyright 2023 The MathWorks, Inc.

    properties(Constant)
        % [1 1 1] Temporarily kept as a semantic because downstream teams are setting it as Label Color frequently.
        WHITE = '--mw-backgroundColor-input'; 
        MWBLUE = [0, 0.33, 0.58];
        GREY = [0.94, 0.94, 0.94];
        HELPBLUE = [0.91, 0.93, 0.96];

        % Semantic variables 
        % Reference: https://confluence.mathworks.com/display/UITP/Semantic+Variables+-+Color
        BackgroundColorInput = '--mw-backgroundColor-input';
        BackgroundColorPrimary = '--mw-backgroundColor-primary';
        BackgroundColorTertiary = '--mw-backgroundColor-tertiary';
        BackgroundColorHighlightFocus = '--mw-backgroundColor-highlight-focus';
        BackgroundColorSecondary = '--mw-backgroundColor-secondary';
        BackgroundColorAnnouncementBanner = '--mw-backgroundColor-announcementBanner';
        BorderColorPrimary = '--mw-borderColor-primary';
        ColorTertiary = '--mw-color-tertiary';
        ColorPrimary = '--mw-color-primary';
        ColorListPrimary = '--mw-color-list-primary';
        ColorError = '--mw-color-error';
        ColorMatlabWarning = '--mw-color-matlabWarning';       
    end
    
    methods(Static)
        function applyThemeColor(component, property, colorName)
            matlab.graphics.internal.themes.specifyThemePropertyMappings(component, property, colorName);
        end
    end
end