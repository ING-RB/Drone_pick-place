% This file contains utilities for manipulating screen position of
% toolstrip based tools and dialogs
    
% Copyright 2015-2020 The MathWorks, Inc.

classdef ScreenUtilities
    
    methods (Static)
        
        %------------------------------------------------------------------
        function setInitialToolPosition(groupName)
            %setInitialToolPosition set the app position to occupy default
            %position on screen. 
            %
            %   NOTE: This must be called after ToolGroup.open().
            %
            %   Usage
            %   -----
            %   imageslib.internal.apputil.ScreenUtilities.setInitialToolPosition(toolGroup.Name);
            %   open(toolGroup);
            
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            
            [x, y, width, height] = imageslib.internal.apputil.ScreenUtilities.getInitialToolPosition();
            
            loc = com.mathworks.widgets.desk.DTLocation.createExternal(...
                int16(x),int16(y),int16(width),int16(height));
            
            md.setGroupLocation(groupName, loc);
            
        end
        
        %------------------------------------------------------------------
        function [x,y,width,height] = getInitialToolPosition()
            %getInitialToolPosition return reasonable estimate of location
            %for an app ToolGroup to occupy 70% screen real estate on the
            %primary monitor.
            %
            %   Use this method if you are an author of an App built on the
            %   new Toolstrip API (matlab.ui.internal.desktop.ToolGroup).
            %   Use this method to get default position as x, y, width and
            %   height which can be passed to setPosition method on the
            %   toolGroup. This can be invoked before open().
            %
            %   Usage
            %   -----
            %   [x,y,width,height] = imageslib.internal.apputil.ScreenUtilities.getInitialToolPosition();
            %
            %   setPosition(toolGroup, x, y, width, height);
            %
            %   open(toolGroup);
            
            % set units to pixels
            origUnits = get(0,'Units');
            set(0, 'Units', 'Pixels');
            restoreGrootUnitsOnCleanUp = onCleanup(@()set(0, 'Units', origUnits));
            
            monitorPositions = get(0,'MonitorPositions');
            isDualMonitor = size(monitorPositions,1) > 1;
            
            if isDualMonitor
                % pick the primary monitor.
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
            szMinWidth  = 1280;
            szMinHeight = 768;
            
            % actual monitor size
            szWidth  = sz(3);
            szHeight = sz(4);
            
            % occupy 70% of the screen real estate or whatever is the
            % min size defined above
            width  = max(szMinWidth, round(szWidth*0.7));
            height = max(szMinHeight, round(szHeight*0.7));
            
            % origin for the JAVA co-ordinate system are located at top
            % left of the primary monitor
            x = sz(1) + round(szWidth/2) - round(width/2);
            y = sz(2) + round(szHeight/2) - round(height/2);
        end
        
        %------------------------------------------------------------------
        function pos = getToolPosition(groupName)
            
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            loc = md.getGroupLocation(groupName);
            
            xy = loc.getFrameLocation;
            wh = loc.getFrameSize;
            
            scrSize = get(0, 'ScreenSize');
            matlabY = scrSize(4)-xy.y; % convert from Java
            
            % correct the x-coordinate in case the primary monitor is on
            % the right.
            monitorPositions = get(0, 'MonitorPositions');
            origin = min(monitorPositions(:, 1:2));
            
            pos = [xy.x+origin(1) matlabY wh.width wh.height];
        end
        
        %------------------------------------------------------------------
        function center = getToolCenter(groupName)
            
            toolPos = imageslib.internal.apputil.ScreenUtilities.getToolPosition(groupName);
            center = toolPos(1:2)+[toolPos(3), -toolPos(4)]/2;
        end
        
        %------------------------------------------------------------------
        % Returns ideal positioning for any modal dialog given its size.
        % The dialog is positioned smack in the middle of the ToolGroup
        %------------------------------------------------------------------
        function pos = getModalDialogPos(groupName, dlgSize)
            
            pos = round([imageslib.internal.apputil.ScreenUtilities.getToolCenter(groupName)-dlgSize/2 dlgSize]);
        end
        
        
    end
    
end
