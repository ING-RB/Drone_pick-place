classdef (Abstract) PrintExportDialog < matlab.ui.internal.dialog.MATLABBlocker
    % This function is undocumented and will change in a future release.

    % Copyright 2021-2025 The MathWorks, Inc.
    properties
        FormatType = 'png';
        Fig;
        TempPreviewFilePath;
        TempPreviewURL;
        InitialConfig = struct();

        StartSubscription;
        CancelSubscription;
        ResolutionSubscription;
        IncludeUIComponentsSubscription;
        FigureBackgroundColorSubscription;
        ColorSpaceSubscription;

        BackgroundColor = 'auto';
        ColorSpace = 'rgb';
        InitialFigColor;
        InitialFigColorMode;
        Resolution = '-r150';
        ResolutionInt = 150;
        IncludeUIComponents = false;

        Window;
        CloseListener;
        Channel = '/gbt/dialogs/printexport/';
        PrintOrExport;
        Theme;
        Environment;
        IsStarting = true; % used to prevent multiple calls to refreshPreview() during startup
        Decaf = false;

        MessageService;
    end

    methods
        function obj = PrintExportDialog(varargin)
            import matlab.internal.capability.Capability;
            useLocal = Capability.isSupported(Capability.LocalClient);

            % Disable set minimum size warning for initialized web window
            initialWindowWarningState = warning('off','cefclient:webwindow:updatePositionMinSize');
            warnWindowCleanup = onCleanup(@()warning(initialWindowWarningState));

            % Check whether in desktop or MO
            if useLocal
                obj.Environment = 'desktop';
            else
                obj.Environment = 'MO';
            end

            if isa(obj, 'matlab.ui.internal.dialog.PrintDialog')
                obj.PrintOrExport = 'print';
            else
                obj.PrintOrExport = 'export';
            end

            % Get the current theme. If the theme setting is unavailable,
            % fall back to Light theme.
            if settings().matlab.appearance.CurrentTheme.hasActiveValue
                obj.Theme = settings().matlab.appearance.CurrentTheme.ActiveValue;
            else
                obj.Theme = 'Light';
            end
            obj.Decaf = matlab.ui.internal.dialog.DialogUtils.checkDecaf;

            if length(varargin{1}) > 0 && isa(varargin{1}{1}, 'matlab.ui.Figure')
                obj.Fig = varargin{1}{1};
            else
                obj.Fig = gcf; % do this temporarily for development
                % error('No uifigure or figure argument was specified');
            end

            obj.InitialFigColor = obj.Fig.Color_I;
            obj.InitialFigColorMode = obj.Fig.ColorMode;

            previewFolder = fullfile(tempdir, 'PrintExport');
            [~,~,~] = mkdir(previewFolder);
            obj.TempPreviewFilePath = fullfile(previewFolder, 'preview');
            obj.TempPreviewURL = matlab.ui.internal.URLUtils.getURLToUserFile(obj.TempPreviewFilePath, false);

            obj.MessageService = message.internal.MessageService('PrintExportDialog');

            obj.StartSubscription = obj.MessageService.subscribe([obj.Channel 'ready'],@(msg) obj.start(msg));
            obj.CancelSubscription = obj.MessageService.subscribe([obj.Channel 'cancel'],@(msg) obj.closeWindow);
            obj.ResolutionSubscription = obj.MessageService.subscribe([obj.Channel 'resolution'],@(msg) obj.updateResolution(msg));
            obj.IncludeUIComponentsSubscription = obj.MessageService.subscribe([obj.Channel 'includeUIComponents'],@(msg) obj.updateIncludeUIComponents(msg));
            obj.FigureBackgroundColorSubscription = obj.MessageService.subscribe([obj.Channel 'backgroundColor'],@(msg) obj.updateFigureBackgroundColor(msg));
            obj.ColorSpaceSubscription = obj.MessageService.subscribe([obj.Channel 'colorSpace'],@(msg) obj.updateColorSpace(msg));
        end

        function openDialog(obj)
            if (1) % TEMPORARY FOR DEBUG: use if(0) to open in a browser and use DevTools (but call .closeWindow() afterwards to do unsubscribes)
                connector.ensureServiceOn();
                url = connector.getUrl('toolbox/matlab/uitools/uidialogs/printexportappjs/index.html');
                url = strcat(url,'&printOrExport=',obj.PrintOrExport);
                url = strcat(url,'&theme=',obj.Theme);
                url = strcat(url,'&environment=',obj.Environment);
                obj.Window = matlab.internal.webwindow(convertStringsToChars(url));
                obj.Window.CustomWindowClosingCallback = @(evt,src)closeWindow(obj);
                if strcmp(obj.Environment, 'MO')
                    % smaller default size and min size in MO+MPA
                    obj.Window.Position = matlab.ui.internal.dialog.DialogUtils.centerWindowToFigure([0 0 850 650]);
                    obj.Window.setMinSize([600 500]);
                else
                    obj.Window.Position = matlab.ui.internal.dialog.DialogUtils.centerWindowToFigure([0 0 1000 750]);
                    obj.Window.setMinSize([700 700]);
                end
                % Add web window tag for tester usage;
                obj.Window.Tag = obj.PrintOrExport;
                % g2286380 The modality works only when the figure is
                % visible, and switches on and off based on toggling the visibility.
                % g3668376 The "waitfor" code needs to adapt to Live Editor
                % since 'FigureViewReady' can be 'off' in Live Editor
                matlab.graphics.internal.waitForFigureReady(obj.Fig);
                obj.Window.setWindowAsModal(true); % Does not work against java windows
                obj.Window.show();
                % After calling "show", which makes the dialog appear on
                % the screen, call "bringToFront" to confirm the dialog is
                % in front. "bringToFront" may not work if dialog isn't
                % visible yet.
                obj.Window.bringToFront();
            else
                connector.ensureServiceOn();
                url = connector.getUrl('toolbox/matlab/uitools/uidialogs/printexportappjs/index-debug.html');
                modUrl = strcat(url,'&printOrExport=',obj.PrintOrExport);
                modUrl = strcat(modUrl, '&theme=',obj.Theme);
                modUrl = strcat(modUrl,'&environment=',obj.Environment);
                web(modUrl, '-browser');
            end
            % wait until client has started and sends "ready" message
        end

        function start(obj, msg)
            % Client is ready. Generate initial preview.

            % Initialize client values
            obj.InitialConfig.fileSeparator = filesep;

            obj.InitialConfig.environment = obj.Environment;

            % Disable the "Graphics and UI Components" option if only axes
            % exist in the figure. If no axes exist, disable the "Graphics
            % Only" option. Checking figure's "NodeChildren" property since
            % it includes objects with "HandleVisibility" set to "off"

            % uicontextmenu objects are ignored in "exportgraphics" and
            % "exportapp", so we should ignore them when evaluating the
            % "NodeChildren"
            nodeChildren = findobj(obj.Fig.NodeChildren, '-not', '-isa', 'matlab.ui.container.ContextMenu', '-depth', 0);

            if isempty(nodeChildren)
                obj.InitialConfig.includeUIComponentsDisabled = true;
                obj.InitialConfig.graphicsOnlyDisabled = false;
            else
                % "Include UI Components" option will be disabled if the
                % direct children (NodeChildren) of the figure doesn't
                % include a non-canvas (UI components can't be contained
                % within a canvas)
                obj.InitialConfig.includeUIComponentsDisabled = isempty(findobj(nodeChildren,'-depth',0,'-not','-class','matlab.graphics.primitive.canvas.HTMLCanvas'));
                % "Graphics Only" option will be disabled if the direct
                % children (NodeChildren) of the figure doesn't include a
                % canvas (No canvas means no direct graphics to export)
                obj.InitialConfig.graphicsOnlyDisabled = isempty(findobj(nodeChildren,'-depth',0,'-class','matlab.graphics.primitive.canvas.HTMLCanvas'));
            end

            % If "Include UI Components" radiobutton is not disabled, see
            % if it should be selected based off of the previous selection
            % or if the "Graphics Only" radiobutton is disabled
            if ~obj.InitialConfig.includeUIComponentsDisabled
                includeUIComponents = getappdata(groot, 'includeUIComponents');
                if obj.InitialConfig.graphicsOnlyDisabled
                    obj.IncludeUIComponents = true;
                elseif ~isempty(includeUIComponents)
                    obj.IncludeUIComponents = includeUIComponents;
                end
            end
            obj.InitialConfig.includeUIComponents = obj.IncludeUIComponents;
            obj.MessageService.publish([obj.Channel 'initialize'], obj.InitialConfig);

            % Focus the Export/Print button
            obj.MessageService.publish([obj.Channel 'focus'], 'focus');

            % client is ready. Generate initial preview.
            obj.IsStarting = false;
            obj.refreshPreview();
        end

        function updateResolution(obj, msg)
            obj.Resolution = ['-r' num2str(msg)];
            obj.ResolutionInt = msg;
            obj.refreshPreview();
        end

        function updateFigureBackgroundColor(obj, msg)
            if ischar(msg)
                if strcmpi(msg, 'auto') && strcmpi(obj.Fig.ColorMode, 'manual')
                    % if there is a user-set color, use it for 'auto'
                    matlabRGBColor = obj.Fig.Color_I;
                else
                    matlabRGBColor = msg;
                end
            else
                matlabRGBColor = [msg(1) / 255, msg(2) / 255, msg(3) / 255];
            end

            obj.BackgroundColor = matlabRGBColor;

            obj.refreshPreview();
        end

        function updateColorSpace(obj, msg)
            obj.ColorSpace = msg;
            obj.refreshPreview();
        end

        function updateIncludeUIComponents(obj, msg)
            obj.IncludeUIComponents = msg;
            obj.refreshPreview();
        end

        function initializeSharedSettings(obj)
            % Populate settings from previous session (if any)
            resolution = getappdata(groot, 'resolution');
            backgroundColor = getappdata(groot, 'backgroundColor');
            if ~isempty(resolution)
                obj.ResolutionInt = resolution;
                obj.Resolution = ['-r' num2str(resolution)];
                obj.InitialConfig.resolution = resolution;
            end

            % Background color for both dialogs
            if ~isempty(backgroundColor)
                % Use the saved background color setting if available
                obj.BackgroundColor = backgroundColor;
            else
                % Else, set background color to 'auto'
                obj.BackgroundColor = 'auto';
            end

            obj.InitialConfig.backgroundColor = obj.BackgroundColor;

            colorSpace = getappdata(groot, 'colorSpace');
            if ~isempty(colorSpace)
                obj.ColorSpace = colorSpace;
                obj.InitialConfig.colorSpace = colorSpace;
            end
        end

        function resetColor(obj)
            % Reset
            obj.Fig.Color_I = obj.InitialFigColor;
            obj.Fig.ColorMode = obj.InitialFigColorMode;
        end

        function closeWindow(obj)
            if ~isempty(obj.Window)
                obj.Window.close();
                delete(obj.Window);
            end
            obj.unblockMATLAB();
        end
    end

    methods (Abstract)
        refreshPreview(obj)
    end
end

