classdef Font
    %FONT class provides common definitions required for specifying fonts.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(Constant)
        Units = 'pixels';
    end
    
    properties
        % The default Font will be used for the UI objects
        % Legacy: MS Sans Serif
        % Current: Helvetica
    end
    
    methods(Static)
        function size = getPlatformSpecificFontSize()
            %GETPLATFORMSPECIFICFONTSIZE specifies platform specific font
            %sizes. Older implementations had varying font sizes. This is
            %no longer the case after switch to web-based backend.
            size = 13;
        end
    end
end