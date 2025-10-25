classdef FigureServices
% FIGURESERVICES A set of static helper functions for working with Figures.

% Copyright 2015-2024 The MathWorks, Inc.

    methods(Static, Access = private)

        function out = setgetURL(figOrUuid, url)
        % Helper function to access the persistent map of Figure to URL.
        % This function allows for setting, getting and removing of an URL.
            persistent urlMap;

            if isempty(urlMap)
                % Create the URL map
                urlMap = containers.Map('KeyType','char','ValueType','char');
            end

            out = [];

            if ischar(figOrUuid)
                key = figOrUuid;
            else
                try
                    key = figOrUuid.Uuid;
                catch
                    % abort if the key is not the expected data type (g2106657)
                    return;
                end
            end

            if (nargin == 2)
                if isKey(urlMap, key) && isempty(url)
                    % Delete Figure URL
                    remove(urlMap, key);
                elseif ~isempty(key) && ~isempty(url)
                    % Insert Figure URL
                    urlMap(key) = url;
                end
            elseif isKey(urlMap, key)
                % Retrieve Figure URL
                out = string(urlMap(key));
            end
        end

    end

    methods(Static, Access = {?matlab.ui.internal.controller.platformhost.DivFigurePlatformHost, ...
                              ?matlab.ui.internal.controller.platformhost.EmbeddedFigurePlatformHost})

        function differentiators = getChannelDifferentiators()
        % Helper function to provide div/embedded Figure ClientToServer and ServerToClient differentiators
        % for use with the MessageService
        % *** This function is designed to provide a single source of truth for these strings ***
        differentiators.ClientToServer = "/embeddedfigure/ClientToServer";
        differentiators.ServerToClient = "/embeddedfigure/ServerToClient";
        end

    end

    methods(Static, Access = {?matlab.ui.internal.controller.FigureController, ...
                              ?gbttest.GBTCommonUnitTestCase})

        function setFigureURL(fig, url)
        %SETFIGUREURL Stores the URL for a given Figure.
        % SETFIGUREURL(FIG,URL) stores URL as the URL for the given Figure handle
        % FIG.
            matlab.ui.internal.FigureServices.setgetURL(fig, url);
        end

        function removeFigureURL(fig)
            %REMOVEFIGUREURL Removes the URL for the given Figure from the
            %repository.
            % REMOVEFIGUREURL(FIG) removes the URL for the given Figure
            % from the URL repository.
            matlab.ui.internal.FigureServices.setgetURL(fig, []);
        end
    end

    methods(Static)
        function url = getFigureURL(figOrUuid)
        %GETFIGUREURL Gets the URL for a given Figure handle.
        % GETFIGUREURL(FIG) returns the URL that represents the given Figure
        % handle FIG or Figure UUID
            url = matlab.ui.internal.FigureServices.setgetURL(figOrUuid);

            % call drawnow to let the Controller and URL be created and
            % re-get the URL, if the URL is not yet present in the urlMap
            if isempty(url)
                matlab.graphics.internal.drawnow.startUpdate
                url = matlab.ui.internal.FigureServices.setgetURL(figOrUuid);
            end
        end

        function channel = getUniqueChannelIdImpl(fig)
            channel = strcat('/uifigure/', fig.Uuid);
            channel = string(channel);
        end

        function channel = getUniqueChannelId(fig)
        %GETUNIQUECHANNELID Gets the unique CHANNEL id for a given Figure handle.
        % GETUNIQUECHANNELID(FIG) returns the unique CHANNEL id for the given Figure
        % handle FIG and ensures that the CHANNEL is cached in a map.

            channel = matlab.ui.internal.FigureServices.getUniqueChannelIdImpl(fig);
            % fix for g2250959: allow Controller to be created so messages don't get lost
            matlab.graphics.internal.drawnow.startUpdate;
        end

        function channel = getUniqueChannelIdForVisibleFigures(fig)

            channel = matlab.ui.internal.FigureServices.getUniqueChannelIdImpl(fig);
            % fix for g2250959: allow Controller to be created so messages don't get lost
            matlab.graphics.internal.updateVisibleFiguresOnly;
        end

        function packet = getDivFigurePacket(fig, dataForClient)
        %GETDIVDFIGUREPACKET Gets the PACKET for a given Div Figure handle.
        % GETDIVFIGUREPACKET(FIG) returns the PACKET to be passed to
        % the JS DivFigureFactory for the given Figure handle FIG.
        % For client-first rendering uifigure in AD's Plain Text app,
        % addiontal data would be appended to DivFigurePacket, which includes:
        % 1) A URL pointing to component view properties cache file
        % 2) Required figure startup ViewModel properties, like ACT channel, etc.

        arguments
            fig
            dataForClient = [];
        end
            if feature('DivFigureEarlyLaunch')
                % fix for g2250959: allow Controller to be created so messages don't get lost
                matlab.graphics.internal.drawnow.startUpdate;
                packet = matlab.ui.internal.getDivFigurePacket(fig);
            else
                % get the MessageService ClientToServer and ServerToClient differentiators to
                % start the packet
                packet = matlab.ui.internal.FigureServices.getChannelDifferentiators();

                % get the unique channel id for the figure
                channel = matlab.ui.internal.FigureServices.getUniqueChannelId(fig);

                packet = matlab.ui.internal.FigureServices.getDivFigurePacketImpl(fig, packet, channel);
            end

            if ~isempty(dataForClient)
                clientFirstDataFieldNames = fieldnames(dataForClient);

                for ix = 1 : numel(clientFirstDataFieldNames)
                    key = clientFirstDataFieldNames{ix};
                    packet.(key) = dataForClient.(key);
                end
            end
        end

        function packet = getDivFigurePacketForVisibleFiguresOnly(fig)
        %Gets the PACKET for a given Div Figure handle.
        % returns the PACKET to be passed to
        % the JS DivFigureFactory for the given Figure handle FIG.

            % get the MessageService ClientToServer and ServerToClient differentiators to
            % start the packet
            packet = matlab.ui.internal.FigureServices.getChannelDifferentiators();

            % get the unique channel id for the figure
            channel = matlab.ui.internal.FigureServices.getUniqueChannelIdForVisibleFigures(fig);

            packet = matlab.ui.internal.FigureServices.getDivFigurePacketImpl(fig, packet, channel);
        end

        function packet = getDivFigurePacketImpl(fig, packet, channel)
            % add the channel id to the packet
            packet.channel = channel;
            packet.Uuid = fig.Uuid;

            % add the required initial property values to the packet
            if matlab.ui.internal.FigureServices.isLastPropOuterPosition(fig)
                packet.OuterPosition = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getPositionInPixelsForView(fig, 'OuterPosition');
            else
                packet.Position = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getPositionInPixelsForView(fig, 'Position');
            end

            packet.Title = matlab.ui.internal.FigureServices.getTitle(fig);
            packet.IconView = matlab.ui.internal.FigureServices.getIconPath(fig.Icon);
            packet.Visible = strcmp(fig.Visible, 'on');
            packet.Resize = strcmp(fig.Resize, 'on');
            packet.WindowState = fig.WindowState;
            packet.WindowStyle = fig.WindowStyle;
            packet.DefaultTools = fig.DefaultTools;

            packet.undockInWindow = matlab.ui.internal.FigureServices.inEnvironmentForInWindowDialogFigures();
        end

        function packet = getEmbeddedFigurePacket(fig)
        %GETEMBEDDEDFIGUREPACKET Gets the PACKET for a given Embedded Figure handle.
        % GETEMBEDDEDFIGUREPACKET(FIG) returns the PACKET to be passed to
        % the JS EmbeddedFigureFactory for the given Figure handle FIG.
           packet = matlab.ui.internal.FigureServices.getDivFigurePacket(fig);
        end

        function packet = getDivFigurePacketForLiveEditor(fig)
        %GETDIVFIGUREPACKET Gets the PACKET for a given div Figure handle.
        % GETDIVFIGUREPACKET(FIG) returns the PACKET to be passed to
        % the JS DivFigureFactory for the given Figure handle FIG.
            packet = matlab.ui.internal.FigureServices.getDivFigurePacketForVisibleFiguresOnly(fig);
        end

        function title = getTitle(fig)
            % Using the Property Management Service ( PMS ), the 'Title' property has
            % defined dependency on the 'NumberTitle', 'IntegerHandle' and 'Name' properties.
            name = fig.Name;
            title = '';
            if (~isempty(name) || ...
                  (strcmp(fig.IntegerHandle,'on') && strcmp(fig.NumberTitle,'on')))
                % Assemble the Figure's title (e.g. "Figure 1: My Figure")
                if (strcmp(fig.IntegerHandle,'on') && strcmp(fig.NumberTitle,'on'))
                    title = ['Figure ' num2str(fig.Number)];
                    if (~isempty(name))
                        title = [title ': '];
                    end
                end
                if (~isempty(name))
                    title = [title name];
                end
            end
        end

        function figureIconPath = getIconPath(value)
            % Return the Default Figure icon path in case of icon is not defined
            % by the user
            % Also convert the icon to .png format as windows for linux/
            % window os support only .png format.
            figureIconPath = '';
            persistent defaultIconPath;

            if isempty(value)
                % Calculate and apply path to the default figure ICON
                if isempty(defaultIconPath)
                    defaultIconPath = fullfile(toolboxdir('matlab'),'uitools','uicomponents','resources','images', 'figure_48.png');
                end
                figureIconPath = defaultIconPath;
            else
                try
                    % Convert to PNG file for formats jpeg, gif and  m-by-n-by-3 truecolor image array
                    % Get path to a PNG file for the Icon
                    figureIconPath = matlab.ui.internal.IconUtils.getPNGFileForView(value);
                catch ex
                    % Create and throw warning
                    w = warning('backtrace', 'off');
                    warning(ex.identifier, '%s', ex.message);
                    warning(w);
                end
            end
        end

        function defaultObjectPropertiesForAppBuilding = getDefaultObjectPropertiesForAppBuilding()
        %GETDEFAULTOBJECTPROPERTIES Returns pair-values for application building
        %containing several default property values for each of several types
        %of object that the figure may contain.

            % Set the units to Pixels as default, as we now support only
            % Pixels as type for units when hosting UIPanel, UITabGroup, UITab, UIButtonGroup, and UIContainer in application figures

            defaultObjectPropertiesForAppBuilding = {'DefaultUipanelUnits', 'pixels', 'DefaultUipanelPosition', [20,20, 260, 221],...
                'DefaultUipanelBordertype', 'line', 'DefaultUipanelFontname', 'Helvetica', 'DefaultUipanelFontunits', 'pixels',...
                'DefaultUipanelFontsize', 12, 'DefaultUipanelAutoresizechildren', 'on', 'DefaultUitabgroupUnits', 'pixels',...
                'DefaultUitabgroupPosition', [20,20, 250, 210], 'DefaultUitabgroupAutoresizechildren', 'on', 'DefaultUitabgroupFontname', 'Helvetica',...
                'DefaultUitabUnits', 'pixels', 'DefaultUitabAutoresizechildren', 'on', 'DefaultUitabFontname', 'Helvetica',...
                'DefaultUibuttongroupUnits', 'pixels', 'DefaultUibuttongroupPosition', [20,20, 260, 210],...
                'DefaultUibuttongroupBordertype', 'line', 'DefaultUibuttongroupFontname', 'Helvetica',...
                'DefaultUibuttongroupFontunits', 'pixels', 'DefaultUibuttongroupFontsize', 12,...
                'DefaultUibuttongroupAutoresizechildren', 'on', 'DefaultUIContainerUnits', 'pixels',...
                'DefaultUIContainerPosition', [20,20, 260, 210], 'DefaultUitableFontname', 'Helvetica', 'DefaultUitableFontunits', 'pixels',...
                'DefaultUitableFontsize', 12,'DefaultUipanelHighlightColor', [125/255,125/255,125/255],...
                'DefaultUibuttongroupHighlightColor', [125/255,125/255,125/255],...
                'DefaultUipanelEnableLegacyPadding',false,'DefaultUibuttongroupEnableLegacyPadding',false};
        end

        function setAppBuildingDefaults(figOrCompcontainer)
        %SETAPPBUILDINGDEFAULTS Configures the given input for application building
        %by setting several default property values for each of several types
        %of object that the input may contain.
        %This method accepts either the figure or component container as the input.
            defaultObjectPropertiesForAppBuilding = matlab.ui.internal.FigureServices.getDefaultObjectPropertiesForAppBuilding();
            set(figOrCompcontainer, defaultObjectPropertiesForAppBuilding{:});

        end

        function vararginWithDefaultObjectProperties = mergeDefaultObjectPropertiesForAppBuildingWithVarargin(varargin)
            %MERGEDEFAULTOBJECTPROPERTIES merges any user name-pair values
            %passed in from the figure constructor with default object
            %properties for app building.

            defaultObjectPropertiesForAppBuilding = matlab.ui.internal.FigureServices.getDefaultObjectPropertiesForAppBuilding();
            vararginWithDefaultObjectProperties = [defaultObjectPropertiesForAppBuilding varargin];
        end

        function useDecaf = useViewModel()
            % USEVIEWMODEL Returns true if DECAF mode is selected.
            localSettings = settings;
            useDecaf = localSettings.matlab.ui.internal.figure.viewmodel.Decaf.ActiveValue;
        end

        function syncManagerString = selectedSyncManager()
            % SELECTEDSYNCMANAGER Returns the string representing the sync manager currently
            % selected.
            if matlab.ui.internal.FigureServices.useViewModel()
                syncManagerString = 'MF0ViewModel';
            else
                syncManagerString = 'PeerModel';
            end
        end

        function forwardToKeyPress(mods, keyChar, keyCode)

            % Forward the Key Press Event to the MATLAB Command Window via
            % processKeyFromC.m
            internal.matlab.desktop.commandwindow.processKeyFromC(mods,keyChar,keyCode);

        end

        function result = isUIFigure(fig)
        % ISUIFIGURE Returns true if the given object is a Figure handle that was created
        % using the uifigure function. Returns false otherwise.
            if (isa(fig,'matlab.ui.Figure') && isprop(fig,'isUIFigure'))
                result = true;
            else
                result = false;
            end
        end

        function createNewFigureInDockedFigureContainer()
            % Callback that is connected to the docked figure container
            % plus affordance

            % TODO: Unify new docked figure command once MO and Desktop
            % WindowStyles align
            if (feature('webui') && desktop('-inuse'))
                figure("WindowStyle", "docked");
            else
                figure;
            end

        end

        function returnVal = inEnvironmentForInWindowDialogFigures()
            % Determine if figure should be
            % undocked in-window inside of a dialog
            import matlab.internal.capability.Capability;
            s = settings;
            returnVal = s.matlab.ui.figure.ShowInDialogWindow.ActiveValue && ~Capability.isSupported(Capability.LocalClient);
        end
    end

    % The below code are for client-first rendering data preparation
    % Once this change has been promoted to Bdesktop, we should work on
    % refactorying platformhost and generarize the way to prepare and send
    % data to client side
    properties (Constant)
        CompViewPropsResourceKey = "viewPropertiesResource";
        FigureAdditionalViewPropsKey = "figureExtraViewModelProps";
        ClientFirstRenderingDataKey = 'ClientFirstRendering';
    end

    methods (Static)
        function data = getClientFirstRenderingDataForServer(fig, figureAdditionalViewProps)
            data = struct.empty();
            import matlab.ui.internal.FigureServices;
            if matlab.ui.internal.FigureServices.isClientFirstRendering(fig)
                data = struct;

                data.(FigureServices.CompViewPropsResourceKey) = matlab.ui.internal.FigureServices.getClientFirstRenderingViewPropertiesFilePath(fig);

                % Add Figure Uuid and ViewModel Uuid
                figUuid = fig.Uuid;
                figureAdditionalViewProps.Uuid = figUuid;
                figureAdditionalViewProps.FigureViewModelUuid = figUuid;

                data.(FigureServices.FigureAdditionalViewPropsKey) = figureAdditionalViewProps;
            end
        end

        function dataForClient = getClientFirstRenderingDataForClient(figureModel, figureAdditionalViewProps)
            dataForClient = struct.empty();

            import matlab.ui.internal.FigureServices;
            data = FigureServices.getClientFirstRenderingDataForServer(figureModel, figureAdditionalViewProps);
            if ~isempty(data)
                % Convert component view properties resource file to a URL for client
                data.(FigureServices.CompViewPropsResourceKey) = matlab.ui.internal.URLUtils.getURLToUserFile(char(data.(FigureServices.CompViewPropsResourceKey)), false);

                dataForClient = struct(FigureServices.ClientFirstRenderingDataKey, data);
            end
        end

        function runningAppInstance = getRunningAppInstance(fig)
            runningAppInstance = [];

            if(isprop(fig, 'RunningAppInstance'))
                runningAppInstance = fig.RunningAppInstance;
            end
        end

        function compViewPropertiesFile = getClientFirstRenderingViewPropertiesFilePath(fig)
            compViewPropertiesFile = '';
            if isprop(fig, 'AppViewCacheFile') && isfile(fig.AppViewCacheFile)
                compViewPropertiesFile = fig.AppViewCacheFile;
            end
        end

        function tf = isClientFirstRendering(fig)
            filePath = matlab.ui.internal.FigureServices.getClientFirstRenderingViewPropertiesFilePath(fig);

            tf = ~isempty(char(filePath));
        end

        function res = isLastPropOuterPosition(fig)
            % Returns whether the last position-related property set is
            % OuterPosition.
            % Position-related properties considered here are those from
            % getOrderedProperties, i.e. Position, OuterPosition, WindowState.
            % For cases where fig is represented with a number, get the
            % figure handle
            if isa(fig, 'double') && ishghandle(fig, 'figure')
                try
                   fig = handle(fig);
                catch ex
                    if (strcmp(ex.identifier, 'MATLAB:class:noConvertToHandle'))
                        error(message('MATLAB:Figure:FigureNonExistentForDouble'));
                    else
                        rethrow(ex);
                    end
                end
            end
            propOrder = fig.getOrderedProperties();
            res = false;
            for i = length(propOrder):-1:1
                currentProperty = propOrder(i);
                if ismember(lower(currentProperty), {'position', 'innerposition'})
                    break;
                end
                if strcmpi(currentProperty, 'outerposition')
                    res = true;
                    break;
                end

            end
        end
    end

end
