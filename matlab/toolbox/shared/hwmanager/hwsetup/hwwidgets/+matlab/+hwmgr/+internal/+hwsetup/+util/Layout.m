classdef Layout < handle
    % matlab.hwmgr.internal.hwsetup.util.Layout is a class that
    % defines the layout details of the HW Setup templates
    
    %   Copyright 2016 The MathWorks, Inc.
    
    properties(Constant)
        Units = 'pixels';
        HWSetupWindowHeight = 480;
        HWSetupWindowWidth = 680;
    end
    
    methods(Static)
         function out = getWindowDistFromLeftEdge()
            %GETWINDOWDISTFROMLEFTEDGE gets the distance from the left 
            %    edge of the screen to the inner left edge of the figure window
            
            [screenWidth, ~] = matlab.hwmgr.internal.hwsetup.util.Layout.getScreenDimensions();
            offset = screenWidth - matlab.hwmgr.internal.hwsetup.util.Layout.HWSetupWindowWidth;
            out = offset*0.5;
         end
         
         function out = getWindowDistFromBottomEdge()
            %GETWINDOWDISTFROMBOTTOMEDGE gets the distance from the
            %    bottom edge of the screen to the bottom edge of the 
            %   figure window 
            
            [~, screenHeight] = matlab.hwmgr.internal.hwsetup.util.Layout.getScreenDimensions();
            offset = screenHeight - matlab.hwmgr.internal.hwsetup.util.Layout.HWSetupWindowHeight;
            out = offset*0.5;
         end
        
        function [w, h] = getScreenDimensions()
            %[W, H] = GETSCREENDIMENSIONS returns the screen width and
            %      screen height
            dim = get(0,'screensize');
            w = dim(3);
            h = dim(4);
        end
        
        function isWindowVisible(wPosition)
            validateattributes(wPosition, {'numeric'},...
                {'size',[1,4],'>=',1}, mfilename, 'wPosition');
            [sW, sH] = matlab.hwmgr.internal.hwsetup.util.Layout.getScreenDimensions();
            if wPosition(1)+wPosition(3) > sW ||...
                    wPosition(2)+wPosition(4) > sH
                warning(message('hwsetup:widget:WindowOutOfRange'));
            end
        end
    end
end