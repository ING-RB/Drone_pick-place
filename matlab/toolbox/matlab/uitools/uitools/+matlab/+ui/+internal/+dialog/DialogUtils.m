classdef ( Sealed ) DialogUtils < handle
    % This class is undocumented and will change in a future release
    
    % Copyright 2014-2024 The MathWorks, Inc.
    
    % This dialog utility is used as a switch to determine which dialogs to
    % show. Also it creates the appropriate dialog.
    
    methods (Static)     
        function retObj = createColorChooser(title, initialColor)
            s = settings; 
            colorChooser = str2func(s.matlab.ui.dialog.uisetcolor.ControllerName.ActiveValue);
            retObj = colorChooser(title, initialColor);
        end
        
        function retObj = createFontChooser(title, initialFont)
            if matlab.ui.internal.dialog.DialogUtils.checkDecaf
                retObj = matlab.ui.internal.dialog.FontChooser(title, initialFont);
            else
                retObj = matlab.ui.internal.dialog.JavaFontChooser(title, initialFont);
            end
        end
        
        function c = disableAllWindowsSafely(checkDecaf)
            % This will disable all CEF windows (if any) from visual
            % interaction and activation.
            % This returns an onCleanup object that will re-enable the CEF
            % windows when it goes out of scope or is deleted.
            
            c = [];
            isDecaf = false;
            
            % get decaf settings value
            if checkDecaf
                isDecaf = matlab.ui.internal.dialog.DialogUtils.checkDecaf;
            end
                   
            % check if connector is running and not decaf before getting webwindows
            if connector.isRunning && ~isDecaf
                webWindows = matlab.ui.internal.dialog.DialogUtils.setAllWindowsActiveValue(false);
                if ~isempty(webWindows)
                    c = onCleanup(@() matlab.ui.internal.dialog.DialogUtils.setAllWindowsActiveValue(true));
                end
            end
        end

        function webWindows = setAllWindowsActiveValue(newValue)
            webWindows = matlab.internal.webwindowmanager.instance.findAllWebwindows();
            if ~isempty(webWindows)
                w = webWindows(1);
                w.setActivateAllWindows(newValue);
            end
        end
        
        function isDecaf = checkDecaf
            % Function to return decaf active value for uitools functions
            % g2447933 - To clean up when we move away from decaf
            isDecaf = logical(feature('webui'));
        end

        % Helper function to check if the current environment is a deployed web app
        function isDeployedEnv = isDeployedWebAppEnv(newSetting)
            persistent deployed
            if isempty(deployed)
                deployed = isdeployed && matlab.internal.environment.context.isWebAppServer;
            end
            if nargin == 1
                % Added for testing purposes
                assert(isa(newSetting, 'logical'))
                deployed = newSetting;
            end
            isDeployedEnv = deployed;
        end
        
        function [iconData, alphaData] = imreadDefaultIcon(iconName)
            % This is a helper to read in the icons in uitools/uitools/private
            % directory. These are the standard icons used by error, warn,
            % help and quest dlg functions.
            iconFileName = fullfile(toolboxdir('matlab'), 'uitools', 'uitools' , 'private', ['icon_' iconName '_32.png']);
            [iconData, ~, alphaData] = imread(iconFileName, 'BackgroundColor', 'none');
        end

        function size = getContainerSize(isLocalClient)
            % Workaround for g1374535: If in MO, check for
            % screen size using defaultPosition
            if isLocalClient
                % Use "get" for desktop MATLAB
                size = get(0, 'ScreenSize');
            else
                % Use defaultPosition for MO
                % Does not work in -externalUI
                size = connector.internal.webwindowmanager.instance().defaultPosition;
            end
        end
        
        function figure_size = centerWindowToFigure(figure_size, figure_units)
            % adjust the specified figure position to fig nicely over GCBF
            % or into the upper 3rd of the screen            
            arguments 
                figure_size
                figure_units = 'pixels'
            end

            import matlab.internal.capability.Capability;
            import matlab.ui.internal.FigureCapability;

            isLocalClient = Capability.isSupported(Capability.LocalClient);
            
            parentHandle = gcbf;
            convertData.destinationUnits = figure_units;
            if ~isempty(parentHandle)
                % If there is a parent figure
                convertData.hFig = parentHandle;

                % workaround for g3426359: dialogs launched from docked
                % figures should be positioned in center of screen
                isEmbedded = FigureCapability.hasCapability(parentHandle, FigureCapability.Embedded);
                isDocked = strcmp(parentHandle.WindowStyle, 'docked');
                if isEmbedded || isDocked
                    convertData.size = matlab.ui.internal.dialog.DialogUtils.getContainerSize(isLocalClient);
                else
                    convertData.size = get(parentHandle,'Position');
                end
                
                convertData.sourceUnits = get(parentHandle,'Units');
                c = [];
            else
                % If there is no parent figure, use the root's data
                % and create a invisible figure as parent
                convertData.hFig = figure('visible','off');

                convertData.size = matlab.ui.internal.dialog.DialogUtils.getContainerSize(isLocalClient);

                convertData.sourceUnits = get(0,'Units');
                c = onCleanup(@() close(convertData.hFig));
            end
            
            % Get the size of the dialog parent in the dialog units
            container_size = hgconvertunits(convertData.hFig, convertData.size ,...
                convertData.sourceUnits, convertData.destinationUnits, get(convertData.hFig,'Parent'));
            
            delete(c);
            
            figure_size(1) = container_size(1)  + 1/2*(container_size(3) - figure_size(3));
            figure_size(2) = container_size(2)  + 2/3*(container_size(4) - figure_size(4));
        end
    end
    
    methods (Hidden, Access = private)
        function obj = DialogUtils()
        end
    end
end
