classdef WebColorChooser < matlab.ui.internal.dialog.Dialog
    % This function is undocumented and will change in a future release
    
    % Copyright 2014-2025 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        Title = getString(message('MATLAB:uistring:uisetcolor:TitleColor'));
        InitialColor = [1 1 1];
    end
    
    properties
        SelectedColor;
        
        Browser;
        BrowserPanel;
        
        URL;
        
        RecentColors;
     
        Decaf = false;

        TextScaling = 1;
    end
    
    properties (Dependent)
        InitialHexColor;
    end
    
    properties (Constant,Access = private)
        W = 226;
        H = 321;
        Tag = 'BasicColorDialog';
    end
    
    methods
        function obj = WebColorChooser(title, initialColor)
            arguments
                title {mustBeTextScalar} = '';
                initialColor = [];
            end
            
            obj.Decaf = matlab.ui.internal.dialog.DialogUtils.checkDecaf;
            obj.SelectedColor = 0;
            
            % title            
            if ~isempty(title)
                obj.Title = title;
            end
            
            % intial color
            if ~isempty(initialColor)
                %We are not going to allow values like [true false false]
                %as valid colors
                if ~isnumeric(initialColor)
                    error(message('MATLAB:UiColorChooser:InvalidColorType'));
                end
                %if multidimensional or column wise vector is given, extract color values
                obj.InitialColor = convert(obj,initialColor);
            end 
            
            obj.setupRecentColors();
            obj.setupURL();
            
            % Create modal JDialog peer
            obj.setupPeer();            
        end        
       
        function delete(obj)
            % Dispose Peer and Browser
            if ~isempty(obj.Peer)
                if obj.isWebUI()
                    delete(obj.Peer);
                    obj.Peer = [];
                else
                    if ~isempty(obj.Browser)
                        obj.Browser.dispose();
                        obj.Peer.remove(obj.BrowserPanel);
                    end
                    obj.Peer.dispose();
                end
            end
        end
        
        function show(obj)
            returnSubsciption = message.subscribe('/gbt/dialogs/uisetcolor/return',@(val) obj.onReturn(val));
            c = onCleanup(@() message.unsubscribe(returnSubsciption));

            obj.blockMATLAB();
            drawnow;
        end
        
        function out = get.InitialHexColor(obj)
            v = round(255 * obj.InitialColor);
            out = lower([dec2hex(v(1),2) dec2hex(v(2),2) dec2hex(v(3),2)]);
        end
    end
    
    methods(Access = protected)
        function onReturn (obj, value)
            if strcmpi(value,'cancel')
                obj.SelectedColor = 0;
            else
                if contains(value, obj.InitialHexColor, 'IgnoreCase', true)
                    % If initial value is the same as value returned then
                    % do nothing and take initial value to avoid rounding.
                    obj.SelectedColor = obj.InitialColor;
                else
                    % Convert incoming hex value to a MATLAB based 0-1 3 element color array
                    c = [hex2dec(value(2:3)) hex2dec(value(4:5)) hex2dec(value(6:7))];
                    obj.SelectedColor = c/255;
                end
                obj.updateRecentColors(value(2:end));
            end
            obj.unblockMATLAB()
        end
        
        function setupURL(obj)
            try
                s = settings;
                currentTheme = s.matlab.appearance.CurrentTheme.ActiveValue;
            catch
                currentTheme = 'Light';
            end
            baseURL = sprintf('/toolbox/matlab/uitools/uidialogs/uisetcolorappjs/index.html?init=%s&recent=%s&theme=%s', obj.InitialHexColor, obj.RecentColors, currentTheme);
            % create web URL
            connector.ensureServiceOn();
            obj.URL = connector.getUrl(baseURL);
        end
        
        function blockMATLAB(obj)
            if obj.isWebUI()
                % workaround for g3508100: must set window as modal before
                % it is shown in MO+MPA
                obj.Peer.setWindowAsModal(true);
                obj.Peer.show();
                blockMATLAB@matlab.ui.internal.dialog.Dialog(obj);                
            else 
                % On Showing the JWebDialog it is modal and blocks the MATLAB thread.
                obj.Peer.setVisible(true);
            end
        end
        
        function unblockMATLAB(obj)
            if obj.isWebUI()
                unblockMATLAB@matlab.ui.internal.dialog.Dialog(obj);
            else 
                % To Unblock we will simply dispose the JavaWebDialog
                obj.Peer.setVisible(false);
            end
            drawnow;
        end
    end
    
    methods (Access = private)
        function isWebUI = isWebUI(obj)
            % In web figures and in MATLAB Online we need to show the
            % mw-colorpicker embedded in a web window. obj.Decaf is used to
            % check if web figures are enabled and the Capability API is
            % used to verify if we are accessing from remote client.
            % Otherwise, we show mw-colorpicker embedded in a
            % LightWeightBrowser window which is JAVA based.
            import matlab.internal.capability.Capability;
            isWebUI = obj.Decaf || ~Capability.isSupported(Capability.LocalClient);
        end

        function setupRecentColors(obj)
            s = settings;
            obj.RecentColors = s.matlab.ui.dialog.uisetcolor.RecentlyUsedColors.ActiveValue;
            % Always take 7 RecentColors only
            obj.RecentColors =  obj.RecentColors(1:48);
        end
        
        function updateRecentColors(obj, newColor)
            idx = strfind(obj.RecentColors, newColor);
            if (~isempty(idx))
                if(idx == 1)
                    return;
                end
                % move the color in the RecentColors list to the start
                obj.RecentColors = [newColor '-' obj.RecentColors(1:idx-1) obj.RecentColors(idx+7:end)];
            else
                % Append newColor to the start and remove last color from end
                obj.RecentColors = [newColor '-' obj.RecentColors(1:end-7)];
            end            
            s = settings;
            s.matlab.ui.dialog.uisetcolor.RecentlyUsedColors.PersonalValue = obj.RecentColors;
        end
        
        function bool = isvalidmultidimensional(~, v)
            sizeofv = size(v);
            occurrencesofthree = find(sizeofv==3);
            if (length(occurrencesofthree)~=1  && prod(sizeofv)~=3)
                bool =false;
            else
                bool = true;
            end
        end
        
        function color = convert(obj, v)
            if isvalidmultidimensional(obj, v)
                color = [v(1) v(2) v(3)];
            else
                error(message('MATLAB:UiColorChooser:InvalidColorDimension'));
            end
            %Checking range of rgb values
            if ismember(0,((color(:)<=1) & (color(:)>=0)))
                error(message('MATLAB:UiColorChooser:InvalidRGBRange'));
            end
        end

        function [scaledW, scaledH] = getScaledDims(obj)
            import matlab.internal.capability.Capability;
            isLocalClient = Capability.isSupported(Capability.LocalClient);

            % set scaling using getTextScaleFactor only if in desktop context impl 
            % and feature flag is on
            if isLocalClient && feature('ScaleFiguresByWindowsAccessibleTextSetting')
                obj.TextScaling = matlab.ui.internal.getTextScaleFactor; 
            end

            scaledW = obj.W * obj.TextScaling;
            scaledH = obj.H * obj.TextScaling;
        end
        
        function setupPeer(obj)
            % g3304798 - scale dialog based on text scaling level
            [scaledW, scaledH] = obj.getScaledDims();

            if obj.isWebUI()
                % Setting the Position on web window construction to avoid window flashing
                obj.Peer = matlab.internal.webwindow(obj.URL, matlab.internal.getDebugPort(), 'Position', matlab.ui.internal.dialog.DialogUtils.centerWindowToFigure([0 0 scaledW scaledH]));
                obj.Peer.setResizable(false);
                obj.Peer.Title = obj.Title;
                obj.Peer.Tag = obj.Tag;               
                obj.Peer.setAlwaysOnTop(true);
                obj.Peer.setMinSize([obj.W obj.H]);
                obj.Peer.CustomWindowClosingCallback = @(o,e) obj.unblockMATLAB();
                % MATLABWindowExitedCallback can be removed once g2669657
                % is addressed.
                obj.Peer.MATLABWindowExitedCallback = @(o,e) obj.unblockMATLAB();
            else
                obj.Peer = handle(javaObjectEDT(com.mathworks.mwswing.WindowUtils.createDialogToParent(obj.getParentFrame(), obj.Title, true)),'callbackproperties');
                obj.Peer.setName(obj.Tag);
                obj.Peer.setResizable(false);
                obj.Peer.setCloseOnEscapeEnabled(true);
                % Set dialog always on top
                obj.Peer.setAlwaysOnTop(true);
                obj.Peer.setTitle(obj.Title);
                
                % Create Browser in JDialog
                browserBuilder = com.mathworks.mlwidgets.html.LightweightBrowserBuilder;
                browserBuilder.setZoomEnabled(false).setContextName('WebColorChooser');
                obj.Browser = javaObjectEDT(browserBuilder.buildBrowser);
                obj.BrowserPanel = obj.Browser.getComponent();
                
                obj.Browser.load(obj.URL);
                obj.Peer.add(obj.BrowserPanel);
                
                % Size the browser;
                width = com.mathworks.util.ResolutionUtils.scaleSize(scaledW);
                height = com.mathworks.util.ResolutionUtils.scaleSize(scaledH);
                obj.BrowserPanel.setPreferredSize(java.awt.Dimension(width, height));
                obj.Peer.pack();
                
                % Position centered and 1/3 of the way down on parent.
                bounds = obj.getParentFrame().getBounds();
                dialogSize = obj.Peer.getSize();
                bounds.x = bounds.x + ((bounds.width - dialogSize.width) / 2);
                bounds.y = bounds.y + ((bounds.height - dialogSize.height) / 3);
                obj.Peer.setLocation(bounds.x, bounds.y);
            end
        end
    end
end
