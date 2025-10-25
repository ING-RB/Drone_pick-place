classdef AppShareWindow < handle
    properties
        window
        appFullFileName
        appType
        windowType
        script
        image
    end
    
    methods
        function obj = AppShareWindow(appFullFileName, appType, windowType, varargin)
            obj.appFullFileName = appFullFileName;
            obj.appType = appType;
            obj.windowType = windowType;
            obj.script = '';
            obj.image = '';
            if (nargin > 3) % only applicable if this is the package step, where we pass in a script/images
                obj.script = varargin{1};
                image = varargin{2};
                if ~isempty(image)
                    obj.image = image{2};
                end
            end
        end
        
        function launch(obj)
            connector.ensureServiceOn();
            connector.newNonce();     
            s = settings;
            theme = s.matlab.appearance.CurrentTheme.ActiveValue;
            [title, minSize, position] = obj.getWindowSettings();       
            url = connector.getUrl('toolbox/deployment/share_window/web/share_window_common/index.html');
            urlParams = [
                '&param1=' urlencode(obj.appFullFileName),...
                '&param2=' obj.appType,...
                '&param3=' lower(theme),...
                '&param4=' obj.windowType,...
                '&param5=' urlencode(obj.script),...
                '&param6=' urlencode(obj.image)
            ];
            fullUrl = [url urlParams];
            obj.window = matlab.internal.webwindow(fullUrl);
            obj.window.Title = title;
            obj.window.Position = position;
            obj.window.setMinSize(minSize);
            obj.window.show();
                
            % on close, configure app designer window to close share window too
            manager = matlab.internal.webwindowmanager;
            appDesWindow = manager.windowList(contains({manager.windowList.Title}, string(message("compiler_ui_common:messages:appDesigner")))); % "App Designer")); 
            if ~isempty(appDesWindow)
                callback = @(src, event) obj.closeWindows(appDesWindow);
                appDesWindow.CustomWindowClosingCallback = callback;
            end
        end

        function closeWindows(obj, appDesWindow)
            appDesWindow.close();
            obj.window.close();
        end
        
        function position = getCenteredPosition(obj, width, height, ratio)
            screen = obj.getScreenSize();
        
            window.Width = min(screen.Width * ratio, width);
            window.Height = min(screen.Height * ratio, height);
        
            topCenterX = screen.Width / 2;
            topCenterY = (screen.Height+window.Height) / 2;
    
            x = topCenterX - window.Width / 2;
            y = topCenterY - window.Height;
        
            position = [x, y, window.Width, window.Height];
        end

        function screen = getScreenSize(obj)
            initUnits = get(groot, "Units");
            cleanup = onCleanup(@()set(groot, Units=initUnits));
            set(groot, Units="pixels");
        
            ss = get(groot, "ScreenSize");
            screen.Width = ss(3);
            screen.Height = ss(4);
        end
    end

    methods (Abstract, Access = protected)
        windowSettings = getWindowSettings(obj)
    end
end