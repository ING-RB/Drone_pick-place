classdef (Sealed = true) WindowStateUtil < handle
    % Manage the position of Add-On Windows

    %   Copyright 2016-2021 The MathWorks, Inc.
    
    
    methods (Access = {?matlab.internal.addons.Explorer, ?matlab.internal.addons.Manager})
    
        function position = getPositionForExplorer(obj)
            s = settings;
            if (s.matlab.addons.explorer.Position.hasPersonalValue)
                position = obj.getValidPosition(s.matlab.addons.explorer.Position.PersonalValue);
            else
                position = obj.getDefaultPosition;
            end
        end
        
        function position = getPositionForManager(obj)
            s = settings;
            if (s.matlab.addons.manager.Position.hasPersonalValue)
                position = obj.getValidPosition(s.matlab.addons.manager.Position.PersonalValue);
            else
                position = obj.getDefaultPosition;
            end
        end
        
        function setExplorerPositionSetting(obj, position)
            s = settings;
            s.matlab.addons.explorer.Position.PersonalValue = position;
        end
        
        function setManagerPositionSetting(obj, position)
            s = settings;
            s.matlab.addons.manager.Position.PersonalValue = position;
        end
        
        function setExplorerWindowMaximizedSetting(~, maximized)
            s = settings;
            s.matlab.addons.explorer.Maximized.PersonalValue = maximized;
        end
        
        function setManagerWindowMaximizedSetting(~, maximized)
            s = settings;
            s.matlab.addons.manager.Maximized.PersonalValue = maximized;
        end
        
        function windowState = getExplorerWindowMaximizedSetting(~)
            s = settings;
            if(~s.matlab.addons.explorer.Maximized.hasPersonalValue)
                s.matlab.addons.explorer.Maximized.PersonalValue = false;
            end
            windowState = s.matlab.addons.explorer.Maximized.PersonalValue;
        end
        
        function windowState = getManagerWindowMaximizedSetting(~)
            s = settings;
            if(~s.matlab.addons.manager.Maximized.hasPersonalValue)
                s.matlab.addons.manager.Maximized.PersonalValue = false;
            end
            windowState = s.matlab.addons.manager.Maximized.PersonalValue;
        end
        
    end
    
    methods (Access = private)
        
        %%%%%%%
        %   Adjusts the Position as required to keep the window on the
        %   screen or screens in case of multiple desktop environment
        %%%%%%%
        function position = getValidPosition(obj, position)
            if feature('webui')
                return;
            end
            point = java.awt.Point(position(1), position(2));
            dimension = java.awt.Dimension(position(3), position(4));
            pointToBeUsed = com.mathworks.mwswing.WindowUtils.ensureOnScreen(point, dimension, 0);
            position = [pointToBeUsed.x pointToBeUsed.y position(3) position(4)];
        end
        
        function defaultPosition = getDefaultPosition(obj)
            screenSize = get(groot,'screensize');
            height = screenSize(4) * 0.75;
            width = screenSize(3) * 0.75;
            yPosition = (screenSize(4) - height)/2;
            xPosition = (screenSize(3) - width)/2;
            defaultPosition = [xPosition, yPosition, width, height];
        end
    end
end
