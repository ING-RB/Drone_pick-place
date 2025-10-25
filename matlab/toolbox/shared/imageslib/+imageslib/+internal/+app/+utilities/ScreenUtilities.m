classdef ScreenUtilities
    % For internal use only.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    % This file contains utilities for manipulating screen position of
    % AppContainer-based tools and dialogs.
    
    methods (Static)
        
        %------------------------------------------------------------------
        function setInitialToolPosition(app)
            %setInitialToolPosition set the app position to occupy default
            %position on screen. 
                        
            [x, y, width, height] = imageslib.internal.app.utilities.ScreenUtilities.getInitialToolPosition();
            
            app.WindowBounds = [x,y,width,height];
            
        end
        
        %------------------------------------------------------------------
        function [x,y,width,height] = getInitialToolPosition(windowSizeFraction)
            %getInitialToolPosition returns a reasonable estimate of
            % location for an app to occupy 70% screen real estate on the
            % primary monitor.
            %
            %   Use this method if you are an author of an App built on the
            %   AppContainer API
            %   (matlab.ui.container.internal.AppContainer). Use this
            %   method to get default position as x, y, width and height
            %   which can be passed to WindowBounds property on the app.
            %   This can be invoked before constructing the app.
            %
            %   Usage
            %   -----
            %   [x,y,width,height] = imageslib.internal.app.utilities.ScreenUtilities.getInitialToolPosition();
            %
            %   appOptions.WindowBounds = [x,y,width,height];
            %   myApp = matlab.ui.container.internal.AppContainer(appOptions);
            %
            %   app.Visible = 'on';
            
            arguments
                windowSizeFraction (1,1) double {mustBeGreaterThan(windowSizeFraction,0), mustBeLessThanOrEqual(windowSizeFraction,1)} = 0.7;
            end
            
            % set units to pixels
            origUnits = get(0,'Units');
            set(0, 'Units', 'Pixels');
            restoreGrootUnitsOnCleanUp = onCleanup(@()set(0, 'Units', origUnits));
            
            monitorPositions = get(0,'MonitorPositions');
            isDualMonitor = size(monitorPositions,1) > 1;
            
            if isDualMonitor
                % Pick the primary monitor.
                % MATLAB sets origin for the primary monitor at (1,1). use
                % this to find which index corresponds to the primary
                % monitor.
                origins = monitorPositions(:,1:2);
                primaryMonitorIndex = find(origins(:,1)==1 & origins(:,2)==1,1);
                
                if isempty(primaryMonitorIndex)
                    % pick the first monitor if this doesn't work.
                    primaryMonitorIndex = 1;
                else
                    primaryMonitorIndex = max(primaryMonitorIndex,1);
                end
                
                sz = monitorPositions(primaryMonitorIndex, :);
            else
                sz = get(0, 'ScreenSize');
            end
            
            % minimum size that we'll use for the tool
            szMinWidth  = 1200;
            szMinHeight = 700;
            
            % actual monitor size
            szWidth  = sz(3);
            szHeight = sz(4);
            
            % occupy 70% of the screen real estate or whatever is the
            % min size defined above
            width  = max(szMinWidth, round(szWidth * windowSizeFraction));
            height = max(szMinHeight, round(szHeight * windowSizeFraction));
            
            % origin for the app coordinate system are located at top
            % left of the primary monitor
            x = sz(1) + round(szWidth/2) - round(width/2);
            y = sz(2) + round(szHeight/2) - round(height/2);
        end
        
        %------------------------------------------------------------------
        function pos = getToolPosition(app)
            %getToolPosition returns the location of the app in screen pixel
            % coordinate system.
            
            % Tool position in app container coordinate system whose origin
            % is at the top-left of the monitor.
            pos = app.WindowBounds;

            % Get screen size in pixels.
            origUnits = get(0,'Units');
            set(0, 'Units', 'Pixels');
            screenSize = get(0,'ScreenSize');
            set(0, 'Units', origUnits);
            
            % Convert the tool position to uifigure coordinate system whose
            % origin is at the bottom left of the monitor.
            pos(2) = screenSize(4) - (pos(2) + pos(4));
        end
        
        %------------------------------------------------------------------
        function center = getToolCenter(app)
            %getToolPosition returns the location of the center of the app  
            % in screen pixel coordinate system. This is commonly used to
            % place dialogs.
            
            pos = imageslib.internal.app.utilities.ScreenUtilities.getToolPosition(app);
            
            center = [round(pos(1) + (pos(3)/2)), round(pos(2) + pos(4)/2)];
        end
        
        %------------------------------------------------------------------
        function dlgPos = getModalDialogPos(app, dlgSize)
            %getModalDialogPos returns the position of the dialog of size
            % dlgSize that would center the dialog over the app.
            
            toolCenter = imageslib.internal.app.utilities.ScreenUtilities.getToolCenter(app);
            
            dlgLocation = round(toolCenter - (dlgSize/2));
            
            dlgPos = [dlgLocation, dlgSize];
        end

        %------------------------------------------------------------------
        function dlgLocation = getModalDialogLocation(toolLocation, dlgSize)
            %getModalDialogLocation returns the location of the dialog of 
            % size dlgSize that would center the dialog over the app.
            
            dlgLocation = round(toolLocation - (dlgSize/2));
        end
    end
    
end