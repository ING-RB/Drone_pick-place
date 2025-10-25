classdef FigureController < matlab.ui.internal.controller.WebCanvasContainerController & ...
        matlab.ui.internal.controller.FigureUpdatesFromClient & ...
        matlab.ui.internal.componentframework.services.optional.EventDispatcherAddOn & ...
        matlab.ui.internal.componentframework.services.optional.ViewReadyInterface ...
        % FIGURECONTROLLER Controller object for matlab.ui.Figure
    % This is the controller object that connects matlab.ui.Figure objects
    % to an HTML-based view.

    % Copyright 2013-2024 The MathWorks, Inc.


    properties (Access = private)
        PositionListener
        % This variable is used for the setPosition for the figure as Set is happening in the Matlab
        % and get is happening on the client side. This will be cleaned off
        % once set is wired up on the client side with same channel
        FigureToolsHeight = 0;
        FigureToolsHeightChanged = false;
        MapKey
        PeerModelInfo
        ViewModelManager
        ViewModelTransactionBegunListener;
        scrollableBehavior
        hasContextMenuBehavior
        SynchronizationMetadata
        PubsubChannels = [];

        % Bool to track if we have committed the very first ViewModel
        % transaction
        %
        % Used for DDUX
        HasCommittedFirstViewModelTransaction = false;

        Uuid;
    end

    properties (Access = public)
        ExportDone = false; % Required to block MATLAB until client returns with export data
        ExportEventListener =[];
        webExportWindow = [];
    end

    properties (Dependent)
        IsFigureViewReady
    end

    properties (Access = {?matlab.ui.control.internal.HTMLComponentDebugUtils, ...
            ?matlab.ui.internal.FigureImageCaptureService, ...
            ?tFigureController})
        PlatformHost    % host that performs platform-specific operations for the current platform
    end

    properties (Access = {?matlab.ui.control.internal.model.mixin.FocusableComponent, ...
    ?matlab.ui.internal.controller.uicontrol.UIControlController, ...
    ?tFigureController})
        IsActive = false;
    end

    properties (Constant)
        COLOR_NONE = [0 0 0];  % constant for the color used on-screen to represent Color='none'
    end

    methods

        function this = FigureController(model, varargin)
            import matlab.ui.internal.FigureCapability;

            % instantiate base class
            this = this@matlab.ui.internal.controller.WebCanvasContainerController(model, varargin{:});

            % get the PlatformHost for the environment in which we are being created,
            %  passing in the model's controllerInfo structure and our
            % instance of the FigureUpdatesFromClient interface, which happens to be us.
            this.Uuid = model.Uuid;

            factory = matlab.ui.internal.controller.platformhost.FigurePlatformHostFactory;

            % Account for a request to make this Figure embedded or isolated by adding on to the existing ControllerInfo
            controllerInfo = this.Model.getControllerInfo();
            if FigureCapability.hasCapability(this.Model, FigureCapability.IsolatedRequested)
                controllerInfo.IsIsolatedRequested = true;
            end
            if FigureCapability.hasCapability(this.Model, FigureCapability.Embedded)
                controllerInfo.IsEmbedded = true;
            end

            this.PlatformHost = factory.createHost(controllerInfo, this);
            this.scrollableBehavior = matlab.ui.internal.componentframework.services.optional.ScrollableBehaviorAddOn(this.PropertyManagementService, this.EventHandlingService);
            this.hasContextMenuBehavior = matlab.ui.internal.componentframework.services.optional.HasContextMenuBehaviorAddOn(this.PropertyManagementService);
            this.ensureConnectorIsRunning;

            if feature('webui')
                this.handleFigureContainerSettings();
            end

            % If in a MO-like environment, make a decision about whether a
            % figure should be opened as undocked according to heuristics
            if matlab.ui.internal.FigureServices.inEnvironmentForInWindowDialogFigures()
                this.checkMOFigureBasedAppHeuristics();
            end

            this.warnIfTextScalingOn();
        end

        function delete(this)
            % delete the PeerModelInfo AFTER the PlatformHost, which may use it
            delete(this.PlatformHost);
            delete(this.ViewModelManager);
            delete(this.PeerModelInfo);
            delete(this.ViewModelTransactionBegunListener);
            matlab.ui.internal.FigureServices.removeFigureURL(this.MapKey);
            delete(this.ExportEventListener);
            delete(this.webExportWindow);
        end

        function markModelDirty(this)
            % avoid errors when this method gets called after figure is
            % deleted
            if isvalid(this)
                this.Model.markDirty(true);
            end
        end

        % This is the entry point for the Position set through PMS
        function newPos = updatePosition(this)
            newPos = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getPositionInPixelsForView(this.Model, 'Position');
        end

        % This is the entry point for the Position set through PMS
        function newOuterPos = updateOuterPosition(this)
            newOuterPos = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getPositionInPixelsForView(this.Model, 'OuterPosition');
        end

        function postUpdatePosition(this, ~)
            % Ideally this should be done in a custom "post/side-effect" function
            % which accepts the output from this function (newPos)
            positionChanged(this);
        end

        function id = getWindowUUID(this)
            id = this.PlatformHost.getWindowUUID();
        end

        function id = getUuid(this)
            id = this.Uuid;
        end

        % This is the entry point for the Position set through FigureWindowMethods
        % during initialization. Ideally, this will be removed once PMS handles
        % initialization
        function positionChanged(this)
            newPos = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getPositionInPixelsForView(this.Model, 'Position');
            this.PlatformHost.updatePosition(newPos);
        end

        function newTitle = updateTitle(this)
            newTitle = string(this.getTitle());
        end

        function postUpdateTitle(this, newTitle)
            this.PlatformHost.updateTitle(newTitle);    % delegate update to PlatformHost
        end

        function newBgColor = updateBackgroundColor(this)
            newBgColor = this.getBackgroundColor();
        end

        function newVisible = updateVisible(this)
            newVisible = this.getVisible();
        end

        function postUpdateVisible(this, newVisible)
            this.PlatformHost.updateVisible(newVisible);    % delegate update to PlatformHost
            this.updateDrawnowSyncReady(this.PlatformHost.isDrawnowSyncSupported());
        end

        function ensureConnectorIsRunning(this)
            connector.ensureServiceOn;
        end

        function newResizable = updateResize(this)
            newResizable = this.getResizable();
        end

        function postUpdateResize(this, newResizable)
            this.PlatformHost.updateResize(newResizable);   % delegate update to PlatformHost
        end

        function newWindowState = updateWindowState(this)
            newWindowState = this.getWindowState();
        end

        function postUpdateWindowState(this, newWindowState)
            this.PlatformHost.updateWindowState(newWindowState);   % update current WindowState for the PlatformHost
        end

        function newWindowStyle = updateWindowStyle(this)
            newWindowStyle = this.getWindowStyle();
        end

        function postUpdateWindowStyle(this, newWindowStyle)
            this.PlatformHost.updateWindowStyle(newWindowStyle);   % update current WindowState for the PlatformHost
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  Method:      updateIconView
        %  Description: Custom method to set new Icon.
        %  Outputs:     url to the newIcon -> on the Tool peernode
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newIconPath = updateIconView( this )
            newIconPath = matlab.ui.internal.FigureServices.getIconPath(this.Model.Icon);
        end

        function postUpdateIconView(obj, figIconPath)
            obj.PlatformHost.updateWindowIconPNG(figIconPath);
        end

        function result = updateScrollTarget( obj )
            result = obj.scrollableBehavior.updateScrollTarget( obj.Model );
        end

        %  updateContextMenuID invoked when uifigure UIContextMenu property changes.
        function newContextMenuID = updateContextMenuID( this )
            newContextMenuID = this.hasContextMenuBehavior.updateContextMenuID(this.Model.UIContextMenu);
        end

        function interactionObject = constructInteractionObject(this, interactionInformation)
            % CONSTRUCTINTERACTIONOBJECT - Add any InteractionInformation
            % InteractionInformation that is specific to this component.
            interactionObject = matlab.ui.eventdata.FigureInteraction(interactionInformation);
        end

        function newInteractionInformation = addComponentSpecificInteractionInformation(obj, interactionInformation, eventdata)
            % ADDCOMPONENTSPECIFICINTERACTIONINFORMATION - Construct the object to be used
            % with InteractionInformation.
            newInteractionInformation = addComponentSpecificInteractionInformation@matlab.ui.internal.componentframework.WebComponentController(obj, interactionInformation, eventdata);
        end

        function newPointer = updatePointer(this)
            if strcmp(this.Model.Pointer, 'custom') && all(isnan(this.Model.PointerShapeCData(:)))
                % when CData contains only NaN values (transparent cursor), we set the cursor value to 'None'
                % this is to workaround an issue with chrome / CEF g2177866
                newPointer.Pointer = 'none';
            else
                newPointer.Pointer = this.Model.Pointer;
            end
            % CData might consist of NaNs. This makes encoding the data to
            % fire across the wire difficult. Instead we state the specific
            % conversions we are okay with at the application level instead
            % of passing the CData value directly to the View Model
            newPointer.CData = jsonencode(this.Model.PointerShapeCData);
            newPointer.HotSpot = this.Model.PointerShapeHotSpot;
        end

        function exportToPDF(this, fileName, includeFigureTools)
            % Ensure figure's view is ready before capturing an image
            waitfor(this, 'IsFigureViewReady', true);
            this.verifyTablesReadyForExport();

            % In Java Desktop use CEFFigurePlatformHost.exportToPDF() This will then call
            % CEF's printToPDF api to generate pdf output.
            if ~feature('webui')
                channelID = ['/gbt/figure/AppCaptureService/' this.getId()];
                exportFuncHandle = @() this.PlatformHost.exportToPDF(fileName, includeFigureTools, channelID);
                matlab.ui.internal.dialog.DialogHelper.dispatchWhenViewIsReady(this.Model, exportFuncHandle);
                return
            end

            % In JSD use the graphics/fig_to_pdf component to export. graphics/fig_to_pdf utilizes
            % dom-snapshot-utils and CEF printToPDF to generate pdf output.
            % Create invisible CEF web window (this will be deleted when once Figure is deleted)
            this.webExportWindow = matlab.graphics.internal.export.WebExportWindowManager.getInstance();
            if ~isempty(this.ViewModel) && isvalid(this.ViewModel)
                % Ensure the window is valid
                if ~isvalid(this.webExportWindow)
                    throwAsCaller(MException('MATLAB:ui:figure:ExportUnsuccessful', 'Export unsuccessful'));
                end

                % Match the figure's position
                this.webExportWindow.cef.Position = this.ViewModel.getProperty('Position');

                % delete old export Event listener
                if (~isempty(this.ExportEventListener))
                    delete(this.ExportEventListener);
                    this.ExportEventListener = [];
                end
                % Create the export event listener
                this.ExportEventListener = ...
                    this.ViewModel.addEventListener('CloneDOMDone', @(src, event) onCloneDOMDone(src, event));

                % Add ViewModel properties
                props = struct;
                props.ExportOperation = 'cloneDOM';
                this.ViewModel.setProperties(props);
                % Mark figure dirty to commit properties
                this.markModelDirty();

                % Wait for clone to be done
                waitfor(this, 'ExportDone', true);
                
                % Clear flag and reset export properties
                this.ExportDone = false;
                props.ExportOperation = '';
                this.ViewModel.setProperties(props);
                this.markModelDirty();

                % Export to pdf
                exportSuccessful = this.webExportWindow.cef.printToPDF(fileName);

                % Verify the export was successfully created
                if ~exportSuccessful
                    throwAsCaller(MException('MATLAB:ui:figure:ExportUnsuccessful', 'Export unsuccessful'));
                end
            end

            % Block MATLAB execution until the client has returned with
            % the clone and then insert it into the webwindow.
            function onCloneDOMDone(~, event)
                this.webExportWindow.insertDom(event.data.result);
                this.ExportDone = true;
            end
        end

        function base64string = exportToPngBase64(this, includeFigureTools)
            % Ensure figure's view is ready before capturing an image
            waitfor(this, 'IsFigureViewReady', true);
            this.verifyTablesReadyForExport();

            base64string = '';
            this.ExportDone = false;
            if ~isempty(this.ViewModel) && isvalid(this.ViewModel)
                % Remove previous listener
                if (~isempty(this.ExportEventListener))
                    delete(this.ExportEventListener);
                    this.ExportEventListener = [];
                end
                % Add export listener
                this.ExportEventListener = ...
                    this.ViewModel.addEventListener('RasterExportDone', @(src, event) onGetPngBase64(src, event));

                % Add ViewModel properties
                props = struct;
                props.ExportOperation = 'getPngBase64';
                props.IncludeFigureTools = includeFigureTools;
                this.ViewModel.setProperties(props);
                % Mark figure dirty to commit properties
                this.markModelDirty();

                % Block MATLAB execution until the client has returned with
                % the requested data
                waitfor(this, 'ExportDone', true);

                % Clear flag and reset export properties
                this.ExportDone = false;
                props.ExportOperation = '';
                props.IncludeFigureTools = '';
                this.ViewModel.setProperties(props);
                this.markModelDirty();
                
                % If client returns an empty string, something on the
                % client failed such that no base64 string could be
                % generated. Throws an error in this case.
                if isempty(base64string)
                    throwAsCaller(MException('MATLAB:ui:figure:ExportUnsuccessful', 'Export unsuccessful'));
                end
            end

            % Populate the output with base64 encoded string provided
            % from the client
            function onGetPngBase64(~, event)
                base64string = event.data.result;
                this.ExportDone = true;
            end
        end

        function isViewReady = get.IsFigureViewReady(this)
            isViewReady = this.Model.isViewReady;
        end

        function className = getViewModelType(obj, ~)
            if obj.Model.HasAppBuildingDefaults
                className = 'matlab.ui.Figure';
            else
                className = 'matlab.ui.LegacyFigure';
            end
        end

        function ret = updateCloseRequestFcn(this)
            %Along with the CloseRequestFcn, return a boolean to signify
            %if the CloseRequestFcn is default.  This is a view only property for the client.
            isDefault = this.Model.isCloseRequestFcnDefault();
            ret = struct('value', this.Model.CloseRequestFcn, 'IsDefault', isDefault);
       end

    end % unqualified (public) methods

    methods (Access = {....
            ?matlab.ui.internal.controller.platformhost.FigurePlatformHost, ...
            ?matlab.ui.internal.controller.FigureUpdatesFromClient ...
            })
        function notifyWindowUUIDChanged(this)
            % sprintf('Notifying WindowUUID Changed %s', this.getWindowUUID())
            notify(this, 'WindowUUIDChanged')
        end

        function notifyWindowUUIDClosed(this)
            notify(this, 'WindowUUIDClosed')
        end
    end

    methods (Access = private)
        function color = getBackgroundColor (this)
            color = this.Model.Color;
            % Return the color to be used as the on-screen BackgroundColor if the Model's Color
            % is set to 'none', which means to make the Figure background transparent when printing.
            % (Black is used as the on-screen representation of this setting.  See g1698056.)
            if strcmp(color, 'none')
                color = this.COLOR_NONE;
            end
        end

        % Using the Property Management Service ( PMS ), the 'Title' property has
        % defined dependency on the 'NumberTitle', 'IntegerHandle' and 'Name' properties.
        % If any of these properties change this update function will be invoked by the PMS.
        function title = getTitle (this)
            title = matlab.ui.internal.FigureServices.getTitle(this.Model);
        end

        function visible = getVisible (this)
            visible = false;
            if (this.is(this.Model.Visible))
                visible = true;
            end
        end

        function resizable = getResizable (this)
            resizable = false;
            if (this.is(this.Model.Resize))
                resizable = true;
            end
        end

        function windowState = getWindowState (this)
            windowState = this.Model.WindowState;
        end

        function windowStyle = getWindowStyle (this)
            windowStyle = this.Model.WindowStyle;
        end

        function numberTitle = getNumberTitle (this)
            numberTitle = this.Model.NumberTitle;
        end

        function updateToolMenuBarHeight(this, newToolsMenuBarHeight)
            this.FigureToolsHeightChanged = false;
            if (this.FigureToolsHeight ~= newToolsMenuBarHeight)
                this.FigureToolsHeight = newToolsMenuBarHeight;
                this.FigureToolsHeightChanged = true;
                this.PlatformHost.updateToolMenuBarHeight(newToolsMenuBarHeight);
            end
        end

        function verifyTablesReadyForExport (this)
            % VERIFYTABLESREADYFOREXPORT - Helper function to verify that
            % all uitables are rendered (thereby ready to be exported)
            tables = findall(this.Model, 'Type', 'uitable');

            for idx = 1:length(tables)
                tableController = tables(idx).getControllerHandle();
                lazyLoadEnabled = tableController.getLazyLoadingStatus();
                if(~lazyLoadEnabled)
                    waitfor(tableController, 'DataRenderedInView', true);
                end
            end
        end

        function updatePropOrder(this)
            propOrderValue = this.Model.getOrderedProperties();
            if ~isempty(propOrderValue)
                this.EventHandlingService.setProperty('PropOrder', propOrderValue);
            end
        end

        function checkMOFigureBasedAppHeuristics(this)
            fig = this.Model;

            % In MO, if the figure has: a tag, a name, or no NumberTitle,
            % we can assume that the figure should be undocked if
            % the WindowStyleMode on the figure is still auto, and the user
            % did not change the DefaultFigureWindowStyle in MO
            shouldAlwaysLaunchUndocked = ...
                (~isempty(fig.Tag)...
                || ~isempty(fig.Name)...
                || strcmp(fig.NumberTitle,'off'))...
                && strcmp(fig.WindowStyleMode,'auto')...
                && strcmp(get(groot,'DefaultFigureWindowStyle'),'docked');

            if shouldAlwaysLaunchUndocked
                fig.WindowStyle = 'normal';
            end
        end

    end % Methods access private



    methods (Access = protected)

        function defineViewProperties( this )
            defineViewProperties@matlab.ui.internal.controller.WebCanvasContainerController(this);
            this.PropertyManagementService.defineViewProperty('Position');
            this.PropertyManagementService.defineViewProperty('OuterPosition');
            this.PropertyManagementService.defineViewProperty('Theme');
            this.PropertyManagementService.defineViewProperty('ThemeMode');
            this.PropertyManagementService.defineViewProperty('Visible');
            this.PropertyManagementService.defineViewProperty('Resize');
            this.PropertyManagementService.defineViewProperty('AutoResizeChildren');
            this.PropertyManagementService.defineViewProperty('WindowState');
            this.PropertyManagementService.defineViewProperty('WindowStyle');

            this.PropertyManagementService.defineViewProperty('Pointer');
            this.PropertyManagementService.defineViewProperty('PointerShapeCData');
            this.PropertyManagementService.defineViewProperty('PointerShapeHotSpot');

            this.PropertyManagementService.defineViewProperty('DockControls');

            this.PropertyManagementService.defineViewProperty('Color');
            this.PropertyManagementService.defineViewProperty('NumberTitle');
            this.PropertyManagementService.defineViewProperty('Name');
            this.PropertyManagementService.defineViewProperty('IntegerHandle');

            this.PropertyManagementService.defineViewProperty('Icon');
            this.PropertyManagementService.defineViewProperty('DefaultTools');
            this.PropertyManagementService.defineViewProperty('Uuid');
            this.PropertyManagementService.defineViewProperty('ShowMenuBarForView');
            this.PropertyManagementService.defineViewProperty('NumToolBarsForView');

            this.PropertyManagementService.defineViewProperty('CloseRequestFcn');
        end

        function definePropertyDependencies( this )
            % Define property dependencies specific to the figure, then call super
            this.PropertyManagementService.definePropertyDependency("Color","BackgroundColor");
            this.PropertyManagementService.definePropertyDependency("NumberTitle","Title");
            this.PropertyManagementService.definePropertyDependency("IntegerHandle","Title");
            this.PropertyManagementService.definePropertyDependency("Name","Title");
            this.PropertyManagementService.definePropertyDependency("PointerShapeCData","Pointer");
            this.PropertyManagementService.definePropertyDependency("PointerShapeHotSpot","Pointer");
            this.PropertyManagementService.definePropertyDependency("Icon", "IconView");
            definePropertyDependencies@matlab.ui.internal.componentframework.WebComponentController(this);
        end

        function defineRequireUpdateProperties(this)
            this.PropertyManagementService.defineRequireUpdateProperty('Visible');
            this.PropertyManagementService.defineRequireUpdateProperty('Resize');
            this.PropertyManagementService.defineRequireUpdateProperty('WindowState');
            this.PropertyManagementService.defineRequireUpdateProperty('WindowStyle');
            this.PropertyManagementService.defineRequireUpdateProperty('Position');
            this.PropertyManagementService.defineRequireUpdateProperty('OuterPosition');
            this.PropertyManagementService.defineRequireUpdateProperty('Pointer');
            this.PropertyManagementService.defineRequireUpdateProperty('CloseRequestFcn');
        end

        function parentView = getParentView(~, ~)
            % The Figure has no parent peer node, so it returns empty.
            parentView = [];
        end

        function createView(this, ~, ~)
            import matlab.ui.internal.FigureCapability;

            % Get this Figure's unique channel ID to send to FigurePeerModelInfo
            % N.B. getUniqueChannelId() caches the channel in a map if it is not already there
            channel = matlab.ui.internal.FigureServices.getUniqueChannelId(this.Model);

            this.ViewModelManager = this.createViewModelManager(channel);
            vmRoot = this.ViewModelManager.getRoot();

            this.MapKey = this.Model.Uuid;

            % Leverage base class method to create ViewModel
            createView@matlab.ui.internal.controller.WebCanvasContainerController(this,...
                        [], vmRoot);

            % FigurePeerModelInfo
            this.PeerModelInfo = matlab.ui.internal.controller.FigurePeerModelInfo(this.PlatformHost.getHTMLFile(), channel, ...
                this.ViewModelManager, this.ViewModel, ...
                this.Model, this.getAdditionalPropertiesToSetOnFigureViewModel());

            % When a transaction is started, mark the model dirty because the c6117955
            % has been modified to only flush changes to client side if the model is dirty,
            % which would not trigger transaction to be commmited since figure is using
            % manual commit strategy, that relies on flushing to commit, if any transaction
            % would not make the model dirty, for instance, a PeerEvent or a PeerNode/ViewModel Node
            % only property set/update.
            % As a result of that, client side transaction would not make to the server side
            % because there's an open transaction on the server side.
            this.ViewModelTransactionBegunListener = addlistener(this.ViewModelManager, 'transactionBegun', ...
                @(s,e)this.markModelDirty);

            % KLUDGE: This bleeds the abstraction.
            % The Component Framework should provide a hook as the model is being destroyed,
            % so the controller can do any cleanup needed where the model is still required.
            returnACTChannel = this.ViewModel.getProperty('ReturnACTChannel');
            logText = jsonencode(struct(...
                'LogType', 'Server', ...
                'Event', 'createView for Figure', ...
                'EventData', struct(...
                'ReturnACTChannel', char(returnACTChannel), ...
                'PlatformHostClass', class(this.PlatformHost) ...
                ), ...
                'Source', 'FigureController', ...
                'Channel', char(channel) ...
                ));
            matlab.graphics.internal.logger('log', 'DrawnowTimeout', logText);

            % Set DrawnowSyncReady according to PlatformHost
            this.Model.setDrawnowSyncReady(this.PlatformHost.isDrawnowSyncSupported());

            % Compare the PlatformHost class name to that of the DivFigurePlatformHost and ...
            dfphClassName = 'matlab.ui.internal.controller.platformhost.DivFigurePlatformHost';
            if isa(this.PlatformHost, dfphClassName)

                % ... use this section for the DivFigurePlatformHost, going forward, or ...

                % Create a structure containing the information to be sent to the platform host
                % and used for the initialization
                cvStruct.peerModelInfo = this.PeerModelInfo;
                cvStruct.uuid = this.Model.Uuid;

                % Add the DivFigurePacket to the structure if it should be sent to
                % the client by the DivFigurePlatformHost
                if ~FigureCapability.hasCapability(this.Model, FigureCapability.Embedded)
                    dataForClientFirstRendering = matlab.ui.internal.FigureServices.getClientFirstRenderingDataForClient(this.Model, this.PeerModelInfo.AdditionalFigurePropsOnViewModel);
                    dfPacket = matlab.ui.internal.FigureServices.getDivFigurePacket(this.Model, dataForClientFirstRendering);
                    cvStruct.dfPacket = dfPacket;
                end

                % Perform platform-specific view creation operations
                this.PlatformHost.createView(cvStruct);

            else    % ... use this section, for old PlatformHosts.

                % Cache the Figure's URL -- note that for DivFigure and
                % EmbeddedFigure, this URL is sent over from the client side
                % once the view has been created, since we can not a priori
                % know the URL on the server side.
                matlab.ui.internal.FigureServices.setFigureURL(this.MapKey, this.PeerModelInfo.URL);

                % Get the Properties to be send to the specific platform host
                % used for the initialization
                pos = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getPositionInPixelsForView(this.Model, 'Position');
                title = this.getTitle();
                visible = this.getVisible();
                resizable = this.getResizable();
                windowState = this.getWindowState();
                windowStyle = this.getWindowStyle();

                % Perform platform-specific view creation operations
                this.PlatformHost.createView(this.PeerModelInfo, pos, title, visible, resizable, windowState, windowStyle, this.Model.Uuid);
            end

            % Wire up the close behavior to invoke the hg closereq function, for CEF
            this.PlatformHost.overrideClose(@(o,e)this.Model.hgclose());

        end

        function handleEvent( this, src, event )
            try
                if( this.EventHandlingService.isClientEvent( event ) )

                    eventStructure = this.EventHandlingService.getEventStructure( event );
                    this.handleClientEvent(src, eventStructure);
                end
            catch exception
                % g2768010 -- We do not have control of the code executed
                % in user defined callbacks that execute as a result of
                % processing client events.  Any arbitrary observable
                % property change can result in a user callback running
                % which deletes the underlying figure and figure
                % controller.
                %
                % Therefore, any event handled in this controller that
                % generates user callbacks may, as a result, throw an
                % exception if the this pointer is suddenly deleted.
                %
                % In that case, the caught exception would have an invalid
                % this object, and in that case, the desired behavior would
                % be to ignore that exception.
                %
                % If the this object is valid, we should instead rethrow
                % the exception.
                if isvalid(this)
                    rethrow(exception);
                end
            end
        end

        function handleFigureContainerSettings(this)
            persistent figureContainerDefaultLastValue;
            
            if feature('webui')
                newFeatureContainerDefaultValue = feature('FigureContainerDefault');

                if(isempty(figureContainerDefaultLastValue) || ...
                        newFeatureContainerDefaultValue ~= figureContainerDefaultLastValue)
                    initVals.launchUndockedWindow = newFeatureContainerDefaultValue;
                    initVals.defaultFigurePosition = get(0,'defaultFigurePosition');
                    message.publish('/figureContainerDefault', initVals);
                end

                if(newFeatureContainerDefaultValue)
                    this.updateLaunchFigureDockedSetting();
                end

                figureContainerDefaultLastValue = feature('FigureContainerDefault');
            end
        end

        function updateLaunchFigureDockedSetting(this)
            fig = this.Model;

            if feature('LiveEditorRunning')
                return;
            end

            % Supress the InfoPanel
            matlab.graphics.internal.InteractionInfoPanel.hasBeenOpened(true);

            if ~isvalid(fig)
                return;
            end

            isJavaFigure = ~isempty(matlab.graphics.internal.getFigureJavaFrame(fig));
            if isJavaFigure
                return;
            end

            isLiveEditorFigure = ~isempty(fig.Tag) && strcmp(fig.Tag,'LiveEditorCachedFigure');
            if isLiveEditorFigure
                return;
            end

            % Returns true if hFig is an embedded morphable figure
            isEmbeddedMorphableFigure = isWebFigureType(fig,'EmbeddedMorphableFigure');
            if isEmbeddedMorphableFigure
                return;
            end

            % If the Figure's WindowStyleMode was manually set, then always
            % honor whatever that setting is.
            if strcmp(fig.WindowStyleMode,'manual')
                return
            end

            % TODO: Once we switch shipping default to docked in desktop
            % MATLAB, we should be able to unify this with the MO heuristic
            % in checkMOFigureBasedAppHeuristics
            shouldAlwaysLaunchUndocked = ...
                ~strcmp(this.Model.WindowStyle,'modal') && ~strcmp(this.Model.DefaultTools,'toolstrip');

            if shouldAlwaysLaunchUndocked
                fig.WindowStyle = 'normal';  
                fig.WindowStyleMode = 'auto';
            end
        end

        function handleClientEvent(this, src, eventStructure)
            if ~isvalid(this.Model)
                return;
            end
            if this.scrollableBehavior.handleClientScrollEvent( src, eventStructure, this.Model )
                return;
            end
            contextMenuEventHandled = this.hasContextMenuBehavior.handleEvent(this, this.Model, src, eventStructure);
            if contextMenuEventHandled
                return;
            end
            timeStamp = -1;
            switch ( eventStructure.Name )
                case 'viewReady'
                    handleClientEvent@matlab.ui.internal.controller.WebCanvasContainerController( this, src, eventStructure );
                case 'viewRebuilding'
                    this.Model.FigureViewReady = false;
                case {'processButtonEvent', 'processMouseMoveEvent'}
                    if eventStructure.data.timeStamp
                        timeStamp = eventStructure.data.timeStamp;
                    end
                    switch eventStructure.data.button
                        case 0
                            button = 'left';
                        case 2
                            button = 'right';
                        case 1
                            button = 'middle';
                        otherwise
                            button = 'left';
                    end

                    this.Model.processButtonEventFromClient(eventStructure.data.type, ...
                        eventStructure.data.position, ...
                        eventStructure.data.selectionType, ...
                        button, ...
                        timeStamp);

                case 'processKeyEvent'
                    if (~isempty(eventStructure.data.key) && ...
                            (eventStructure.data.key ~= "'") && ...
                            (eventStructure.data.key ~= "") && ...
                            (eventStructure.data.key ~= "Unidentified"))

                        modifier = eventStructure.data.modifier;
                        if isempty(modifier)
                            modifier = {};
                        end

                        this.Model.processKeyEventFromClient(eventStructure.data.type, ...
                            eventStructure.data.character, ...
                            modifier, ...
                            eventStructure.data.key, ...
                            eventStructure.data.keyTarget);
                    end


                case 'processButtonScrollEvent'
                    this.Model.processScrollEventFromClient(eventStructure.data.verticalCnt,...
                        eventStructure.data.verticalAmt, ...
                        eventStructure.data.position);

                case 'positionChangedEvent'
                    validStruct = isfield(eventStructure.innerPos,'x') && isfield(eventStructure.outerPos,'x') ;
                    % This is an internal assert here while development work is
                    % underway.  This function is not expected to error in
                    % practice.
                    assert(validStruct, "Position Changed Event has a bad event structure");

                    figureInnerPosition = [eventStructure.innerPos.x eventStructure.innerPos.y eventStructure.innerPos.width eventStructure.innerPos.height];
                    figureOuterPosition = [eventStructure.outerPos.x eventStructure.outerPos.y eventStructure.outerPos.width eventStructure.outerPos.height];

                    if (isfield(eventStructure, 'refFrameSize'))
                        dockedFigureReferenceFrame = [0 0 eventStructure.refFrameSize(1) eventStructure.refFrameSize(2)];
                        % Be sure to update reference frame before updating
                        % position
                        this.Model.setDockedRefFrameFromClient(dockedFigureReferenceFrame);
                    end

                    %Update the Model with rendered position
                    this.Model.setPositionFromClient(figureInnerPosition, figureOuterPosition);

                    %Set the height of the Figure tools area from the
                    %client which used in setting the position

                    if (isfield(eventStructure.innerPos, 'figToolsHeight'))
                        this.updateToolMenuBarHeight(eventStructure.innerPos.figToolsHeight);
                    end
                case 'windowStateChanged'
                    this.updateWindowStateFromClient(eventStructure.winStateValue, false);
                case 'dockControlsClicked'
                    this.Model.WindowStyle = eventStructure.winStyleValue;
                case 'titleChanged'
                    this.updateTitleFromClient(eventStructure.titleValue);
                case 'windowStyleChanged'
                    this.updateWindowStyleFromClient(eventStructure.winStyleValue)
                case 'visibleChanged'
                    this.updateVisibleFromClient(eventStructure.visibleValue)
                case 'updateFigureURL'
                    this.updateFigureURL(eventStructure.url);
                otherwise
                    % Now, defer to the base class for common event processing
                    handleClientEvent@matlab.ui.internal.controller.WebCanvasContainerController( this, src, eventStructure );
            end

            % After all matlab events for this client side event have been
            % emitted and callbacks processed, send an event to the client
            % if the event is registered to use an event coalescing
            % mechanism.
            % Need to check if controller is valid or not because the
            % user's callback could delete the app or the component
            % see g1336677
            coalescedEventIsField = isfield(eventStructure, 'CoalescedEvent');
            if(isvalid(this) && coalescedEventIsField && eventStructure.CoalescedEvent)
                this.sendFlushEventToClient(this.Model, eventStructure.Name, this.EventHandlingService);
            end
        end

        function postSet( obj, property )
            % Customizable method provided by the MATLAB Component Framework (MCF)
            % that will be invoked after to the setting of the property.
            if isa(obj.ViewModel, "appdesservices.internal.interfaces.view.EmptyViewModel") || ...
                    (~obj.ViewModel.hasProperty(property) && ~strcmp(property, 'BeingDeleted'))
                return;
            end

            if (strcmp(property, 'BeingDeleted'))
                % Note: We are using the postSet method to react when
                % BeingDeleted is updated instead of adding the property
                % to the peer node and using updateBeingDeleted because
                % currently, the view does not need BeingDeleted to be
                % sent. If that becomes the case, this code can move
                % into updateBeingDeleted.
                value = obj.Model.get( property );
            else
                value = obj.ViewModel.getProperty(property);
            end

            switch property
                case 'OuterPosition'
                    obj.updatePropOrder();

                case 'Position'
                    obj.postUpdatePosition(value);
                    obj.updatePropOrder();

                case 'Resize'
                    obj.postUpdateResize(value);

                case 'Title'
                    obj.postUpdateTitle(char(value));

                case 'Visible'
                    obj.postUpdateVisible(value);

                case 'WindowState'
                    obj.postUpdateWindowState(value);
                    obj.updatePropOrder();

                case 'WindowStyle'
                    obj.postUpdateWindowStyle(value);

                case 'BeingDeleted'
                    if(strcmp(value, 'on'))
                        obj.PlatformHost.onBeingDeleted();
                    end

                case 'IconView'
                    if ~isempty(value)
                        obj.postUpdateIconView(value);
                    end
            end

            postSet@matlab.ui.internal.controller.WebCanvasContainerController(obj, property);
        end

        function setViewReady(this)
            this.PlatformHost.setViewReady();
            setViewReady@matlab.ui.internal.controller.WebCanvasContainerController(this);
            this.Model.FigureViewReady = true;

            % Update CurrentFigure, since Linux windows are not guaranteed to receive activation events on launch
            if this.Model.Visible
                set(groot,"CurrentFigure",this.Model);
            end

        end

        function propStructToAdd = getAdditionalPropertiesForViewDuringConstruction(this)
            propStructToAdd = getAdditionalPropertiesForViewDuringConstruction@matlab.ui.internal.controller.WebCanvasContainerController(this);

            if isempty(propStructToAdd)
                propStructToAdd = struct();
            end

            propStructToAdd = this.getAdditionalPropertiesToSetOnFigureViewModel(propStructToAdd);
        end

    end % protected methods

    methods (Access = public)
        % These functions constitute the FigureController's implementation of the FigureUpdatesFromClient interface

        function onViewKilled(this)
            delete(this.Model);
        end % onViewKilled()

        function updateDrawnowSyncReady(this, syncReady)
            this.Model.setDrawnowSyncReady(syncReady);
        end % updateDrawnowSyncReadyFromClient()

        function updatePositionFromClient(this, position, peerNodeData)
            % update the model's position only if it differs from its current position
            posChanged = ~isequal(position, this.Model.Position);

            % update the peer node before the model because of what could happen when
            % the model invokes any ResizeFcn that might be present (see g1950099)
            if (posChanged || this.FigureToolsHeightChanged)
                %Sync the peernode with position from the model
                this.EventHandlingService.setProperty( 'Position', peerNodeData );
                this.FigureToolsHeightChanged = false;

                this.Model.setPositionFromClient(position, position);

                % Mark model as dirty to make sure any transaction that is opened by
                % setting the position property will be committed in the next update traversal
                this.markModelDirty();
            end
        end % updatePositionFromClient()

        function updateTitleFromClient(this, newTitle)
            if ~isequal(newTitle, this.Model.Name) && ~this.getNumberTitle()
                % Setting the title from the client does not support using
                % the NumberTitle property-- the Title is always set
                % to the value sent from the client. The model will set
                % NumberTitle to "off."
                this.Model.setTitleFromClient(newTitle);
            end
        end % updateTitleFromClient()

        function updateVisibleFromClient(this, newVisible)
            if ~isequal(newVisible, this.Model.Visible)
                this.Model.Visible = newVisible;
            end
        end % updateVisibleFromClient()

        function wasSet = updateWindowStateFromClient(this, newState, forcedByPositionChange)
            wasSet = true;
            if nargin < 3
                forcedByPositionChange = false;
            end
            if ~isequal(newState, this.Model.WindowState)
                wasSet = this.Model.requestSetWindowStateFromClient(newState, forcedByPositionChange);
                this.PlatformHost.updateWindowState(newState);   % update current WindowState for the PlatformHost
            end
        end % updateWindowStateFromClient()

        function updateWindowStyleFromClient(this, newWindowStyle)

            if ~isequal(newWindowStyle, this.Model.WindowStyle)
                %update the modal with new windowStyle
                this.Model.setWindowStyleFromClient(newWindowStyle);
            end
        end

        function updateFigureURL(this, newURL)
            matlab.ui.internal.FigureServices.setFigureURL(this.MapKey, newURL);
            this.PeerModelInfo.updateFigureURL(newURL);
        end

        % This sends a message to the model that causes this Figure to become
        % the CurrentFigure if allowed. It also triggers the FigureActivated event.
        % ### It is currently used by the CEFFigurePlatformHost.
        % ### we may need to implement this for the general DivFigure case as well
        function figureActivated(this)
            this.Model.figureActivatedFromClient();
            this.IsActive = true;
            notify(this.Model, "FigureActivated");
        end % figureActivated()

        function figureDeactivated(this)
            this.Model.figureDeactivatedFromClient();
            this.IsActive = false;
            notify(this.Model, "FigureDeactivated");
        end % figureDeactivated()


        function windowClosed(this)
            this.Model.hgclose();
        end % windowClosed()

        function onViewDestroyed(this)
            this.updateFigureURL('');
            this.Model.FigureViewReady = false;
        end %onViewDestroyed

        function sendACT( obj, act)
            %SENDACT Sends a request to Client for ACT when completed
            %   Requests that Client send an ACT when current batch of requests is complete
            %
            %   arguments:
            %       act - ID of request to be acknowleged
            obj.ViewModel.setProperty('DrawnowACT', act);
            obj.SynchronizationMetadata = struct('ACT', act, 'ReturnChannel', obj.ViewModel.getProperty('ReturnACTChannel'));

            % g2309636 - make sure client gets this ACT request immediately
            obj.commitPropertyChanges();
        end
    end % public methods

    methods (Access = private)

        function vmm = createViewModelManager(this, channel)
            vmm = matlab.ui.internal.componentframework.services.core.eventhandling.WebEventHandlingService.getViewModelManager(...
                'MF0ViewModel', char(channel), true, 'manual');
            vmm.setAsyncFlag(true);

            vmRoot = vmm.getRoot();
            if isempty(vmRoot)
                vmm.setRoot('ContainerRoot');
                this.commitPropertyChanges();
            end
        end

        function commitPropertyChanges(this)
            % It's possible that PeerModelInfo has not been set yet. If
            % that's the case, then there is no synchronizer, and therefore
            % no coalescer to flush.
            if ~isempty(this.ViewModelManager)
                this.ViewModelManager.manualCommit(this.SynchronizationMetadata);

                % Log timestamp for ServerEnded (which means the initial transaction)
                % if and only if its the first one
                if(~this.HasCommittedFirstViewModelTransaction)
                    logServerEndedEvent(this);
                end
            end
        end

        function logServerEndedEvent(this)
            % If this Figure is part of a running App
            %
            % - log the time
            % - mark as not needed to log again
            runningAppInstance = matlab.ui.internal.FigureServices.getRunningAppInstance(this.Model);
            if(~isempty(runningAppInstance))
                runningAppInstance.TimingFields.ServerEnded = string(datetime('now', 'TimeZone', 'GMT', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            end
            this.HasCommittedFirstViewModelTransaction = true;

        end

        function warnIfTextScalingOn(this)
            % When the accessibility text scaling is > 100%, most apps are
            % cut-off.
            import matlab.internal.capability.Capability;
            isLocalClient = Capability.isSupported(Capability.LocalClient);
            textScaling = matlab.ui.internal.getTextScaleFactor;
            resize = this.Model.Resize;
            if (isLocalClient && textScaling > 1 && ~resize)
                % Throw a warning to point users to the EBR when the app is
                % non-resizable as it is the worse case.
                % Exclude MO as the a11y text scaling doesn't affect MO.

                % Show the link to suppress this warning as there might be
                % many apps or dialogs running into this
                warnState = warning('verbose', 'on');
                
                messageText = getString(message('MATLAB:ui:containers:a11yTextScalingNotSupported'));
                matlab.ui.control.internal.model.PropertyHandling.displayWarning(this.Model, 'a11yTextScalingNotSupported', messageText);
                
                % Restore the previous warning state
                warning(warnState);
            end
        end


    end

    methods (Access = {?appdesservices.internal.interfaces.view.ViewModelFactoryManager, ...
            ?gbttest.util.FigureControllerTestHelper})
        function updatedPropStruct = getAdditionalPropertiesToSetOnFigureViewModel(this, propStruct)
            arguments
                this
                propStruct = struct();
            end
            import matlab.ui.internal.FigureCapability;

            updatedPropStruct = propStruct;

            % Add the type of host to figure peernode so it can be
            % used for creating corresponding platform strategy in the java script
            ht = this.PlatformHost.getHostType();
            updatedPropStruct.hostType = ht;

            % CommandSender setup
            if isempty(this.PubsubChannels)
                this.PubsubChannels = this.Model.createPubSubConnection;
            end
            pubsubChannels = this.PubsubChannels;
            updatedPropStruct.NewViewEventChannel = pubsubChannels{1};
            updatedPropStruct.ReconnectEventChannel = pubsubChannels{2};
            updatedPropStruct.ReturnACTChannel = pubsubChannels{3};

            % Add undockInWindow and hideDockControlsInDeployment as ViewProperty
            s = settings;
            updatedPropStruct.undockInWindow = matlab.ui.internal.FigureServices.inEnvironmentForInWindowDialogFigures();
            updatedPropStruct.hideDockControlsInDeployment = (isdeployed && ~s.matlab.ui.figure.DockFigureInDeployment.ActiveValue);
            updatedPropStruct.IsEmbedded = FigureCapability.hasCapability(this.Model, FigureCapability.Embedded);

		    import matlab.internal.capability.Capability;
            isLocalClient = Capability.isSupported(Capability.LocalClient);
            if isLocalClient && feature('ScaleFiguresByWindowsAccessibleTextSetting')
                % In MO, the figure content is not scaled by the accessibility text scaling
                % so we don't want to scale the figure size.
		        updatedPropStruct.TextScaling = matlab.ui.internal.getTextScaleFactor;
            end
        end
    end

    methods (Access = { ?matlab.ui.Figure, ?tFigureController, ?matlab.ui.internal.DesignTimeUIFigureController } )

        % Used by Figure.flushCoalescer() to implement the short-term solution
        % for drawnow property updates. When the long-term solution is
        % implemented, this method can be removed; see g1658467.
        function flushCoalescer(this)
            this.commitPropertyChanges();
        end

        function rebuildView(this)
            import matlab.ui.internal.FigureCapability;

            % This is a lightweight modification of createView used to destroy
            % the existing view and recreate it.

            if ~FigureCapability.hasCapability(this.Model, FigureCapability.Embedded)
                dfPacket = matlab.ui.internal.FigureServices.getDivFigurePacket(this.Model);
                cvStruct.dfPacket = dfPacket;

                % Set the peer model property for WindowStyle here so that it will be seen by the client side.
                % Some cases where we rebuild the view, we change the window style before it is rebuilt, and we
                % want that change to take effect *when* the view is rebuilt, not as an action that triggeres
                % a dock/undock action.
                this.setProperty('WindowStyle');
                this.Model.FigureViewReady = false;
                this.PlatformHost.rebuildView(cvStruct.dfPacket);
            end
        end

        % Requests that the Figure's window be brought to the front
        % ### this message is used only by the old MO-specific code now
        % ### we may need to implement this for the general DivFigure case as well
        function toFront(this)
            toFront(this.PlatformHost);
        end

        % Brings the Figure into focus
        function bringToFocus(this)
            toFront(this.PlatformHost);
            func = @() this.EventHandlingService.dispatchEvent('FocusComponent');
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(this.Model, this.ViewModel, func);
        end

        function fitToContentWithAnchor(this, anchor)
            pvPairs = {...
                'Anchor', anchor
                };
            func = @() this.EventHandlingService.dispatchEvent('fitToContentRequested', pvPairs);
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(this.Model, this.ViewModel, func);

        end
    end % FigureHelper limited access methods

    methods ( Access = { ?gbttest.util.FigureControllerTestHelper } )
        function val = getPropertyFromView(this, prop)
            val = this.ViewModel.getProperty(prop);
        end
    end

    methods (Static=true, Access = {?gbttest.util.FigureControllerTestHelper})

        % disableWindowCreation() - used by FigureControllerTestHelper to enable and disable window creation
        function status = disableWindowCreation(dohide)
            status = matlab.ui.internal.controller.platformhost.CEFFigurePlatformHost.disableWindowCreation(dohide);
        end % disableWindowCreation()

    end % static limited access methods
end
