classdef DesignTimeUIFigureController < ...
        matlab.ui.internal.controller.FigureController & ...
        matlab.ui.internal.DesignTimeGbtParentingController & ...
        appdesigner.internal.componentcontroller.DesignTimeIconHandler
    %DESIGNTIMEUIFIGURECONTROLLER - This class contains design time logic
    %specific to the uifigure

    % Copyright 2016-2024 The MathWorks, Inc.

    methods
        function obj = DesignTimeUIFigureController(component, parentController, proxyView, adapter)
            % This constructor is called twice on the same component in the
            % case of loading, so we need to check for the presence of the
            % GUIDEFigure property.
            if (~isprop(component, 'GUIDEFigure'))
                guideFigureProp = addprop(component, 'GUIDEFigure');
                guideFigureProp.Transient = true;
            end

            obj = obj@matlab.ui.internal.controller.FigureController(component, parentController, proxyView);
            obj = obj@matlab.ui.internal.DesignTimeGbtParentingController(component, parentController, proxyView, adapter);
            
            obj.prepareThemeChangedFcnProperty();
            obj.prepareColormapStringProperty();
        end

        function id = getId(obj)
            % GETID(OBJ) returns a string that is the ID of the peer node
            id = obj.ViewModel.Id;
        end

        function adjustedProps = adjustParsedCodegenPropertiesForAppLoad(obj, parsedProperties)
            adjustedProps = adjustParsedCodegenPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, parsedProperties);

            % Always send Theme & ThemeMode properties for the client side to determine the theme of the current figure.
            adjustedProps = [adjustedProps, {'Theme', 'ThemeMode'}];
        end
    end

    methods ( Access=protected )
        function handleDesignTimePropertyChanged(obj, peerNode, data)

            % handleDesignTimePropertyChanged( obj, peerNode, data )
            % Controller method which handles property updates in design time. For
            % property updates that are common between run time and design time,
            % this method delegates to the corresponding run time controller.

            % Handle property updates from the client

            updatedProperty = data.key;
            updatedValue = data.newValue;

            switch (updatedProperty)
                case 'Color'
                    obj.Model.Color = convertClientNumbertoServerNumber(obj, updatedValue);

                case 'AD_ColormapString'
                    obj.prepareColormapStringProperty();
                    obj.Model.AD_ColormapString = updatedValue;
                    obj.Model.Colormap = feval(updatedValue);

                case 'ThemeChangedFcn'
                    obj.prepareThemeChangedFcnProperty();
                    obj.Model.AD_AliasedThemeChangedFcn = updatedValue;
                    

                case 'Theme'
                    % no op for now as Theme cannot be changed from AD Client

                case 'DockControls'
                    % no op for now

                case 'BeingDeleted'
                    % no op

                case 'Uuid'
                    % no op

                case 'ShowMenuBarForView'
                    % no op

                case 'NumToolBarsForView'
                    % no op
                
                otherwise
                    % call base class to handle it
                    handleDesignTimePropertyChanged@matlab.ui.internal.DesignTimeGBTComponentController(obj, peerNode, data);
            end
        end

        function prepareColormapStringProperty(obj)
            % PREPARECOLORMAPSTRINGPROPERTY - Set up the aliased
            % AD_ColormapString property if the property does not already
            % exist on the design-time UIFigure.

            % If the AD_ColormapString property doesn't exist, add it as a
            % design-time transient property and set its value
            % appropriately.
            if ~isprop(obj.Model, 'AD_ColormapString')
                dynamicProperty = addprop(obj.Model, 'AD_ColormapString');
                dynamicProperty.Transient = true;
            end
            obj.Model.AD_ColormapString = inspector.internal.getColormapString(obj.Model.Colormap);
        end

        function prepareThemeChangedFcnProperty(obj)
            % PREPARETHEMECHANGEDFCNPROPERTY - Set up the aliased
            % AD_AliasedThemeChangedFcn property if it doesn't already exist.

            if ~isprop(obj.Model, 'AD_AliasedThemeChangedFcn')
                dynamicProperty = addprop(obj.Model, 'AD_AliasedThemeChangedFcn');
                dynamicProperty.Transient = true;
                if ~isempty(obj.Model.ThemeChangedFcn)
                    obj.Model.AD_AliasedThemeChangedFcn = obj.Model.ThemeChangedFcn;
                    obj.Model.ThemeChangedFcn = "";
                else
                    obj.Model.AD_AliasedThemeChangedFcn = obj.Model.ThemeChangedFcn;
                end
            end
        end

        function handleDesignTimeEvent(obj, src, event)
            %HANDLEDESIGNTIMEEVENT - Handler for 'peerEvent' from the Peer Node.

            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                % Handle changes in the property editor that needs a
                % server side validation

                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;

                switch propertyName
                    case 'Alphamap'

                        % The propertyValue arrives as a character vector.  Convert the
                        % propertyValue to a double array before assigning it
                        % to the Alphamap property.
                        convertedPropertyValue = convertClientNumbertoServerNumber(obj, propertyValue);

                        % Set the property on the server and then set it on the
                        % object handle.
                        setServerSideProperty(obj, ...
                            obj.Model, ...
                            propertyName, ...
                            convertedPropertyValue, ...
                            event.Data.CommandId...
                            )

                        obj.setProperty('Alphamap');
                        obj.setProperty('Alphamap_I');

                        % stop handling other events
                        return;

                    case 'Resize'

                        % If WindowState is 'maximized', the Resize property
                        % cannot be 'off'.
                        % The run-time component behaves as follows:
                        % 1.  If WindowState is maximized and Resize is set to
                        % 'off', the UIFigure is no longer maximized (no
                        % warning is given).
                        % 2.  If Resize is 'off', and WindowState is set to
                        % 'maximized', a warning is shown.

                        % In case 2 above, we inherit the run-time component
                        % warning.
                        % In case 1 above, we want to give a warning because
                        % this makes the most sense at design-time (there is no
                        % major visual feedback for WindowState at design-time).

                        % This if-statement provides the warning in Case 1
                        % above.
                        if strcmp(obj.Model.WindowState,'maximized') && propertyValue == matlab.lang.OnOffSwitchState.off
                            errorDialogForClient.message = getString(message('MATLAB:Figure:NonResizableFiguresCannotMaximize', obj.Model.WindowState));
                            propertySetFail(obj, propertyName, event.Data.CommandId, errorDialogForClient);
                            return
                        end

                        setServerSideProperty(obj, ...
                            obj.Model, ...
                            propertyName, ...
                            propertyValue, ...
                            event.Data.CommandId...
                            )

                        obj.setProperty('Resize');
                        obj.setProperty('Resize_I');

                        % stop handling other events
                        return;

                    case 'WindowState'

                        % Set the property on the server and then set it on the
                        % object handle.
                        setServerSideProperty(obj, ...
                            obj.Model, ...
                            propertyName, ...
                            propertyValue, ...
                            event.Data.CommandId...
                            )

                        obj.setProperty('WindowState');
                        obj.setProperty('WindowState_I');

                        % stop handling other events
                        return;

                    case 'Icon'

                        % Validate the inputted Image file
                        [fileNameWithExtension, validationStatus, imageRelativePath] = obj.validateImageFile(propertyName, event);

                        if validationStatus
                            iconValueToSet =  fileNameWithExtension;
                            viewmodel.internal.factory.ManagerFactoryProducer.setProperties(obj.ViewModel, {'ImageRelativePath', imageRelativePath});
                            % this is an event callback and we're adjusting
                            % the event data. Since it's called from
                            % handleEvent, it's a client event.
                            obj.handleComponentDynamicDesignTimeProperties(struct('ImageRelativePath', imageRelativePath), true);
                        else
                            iconValueToSet = '';
                        end

                        % Setting the property in this way ensures that the
                        % property is added to the client's undo/redo stack.
                        setServerSideProperty(obj, ...
                            obj.Model, ...
                            propertyName, ...
                            iconValueToSet, ...
                            event.Data.CommandId...
                            );

                        % Set the Icon property then send the property set
                        % information to the client.
                        obj.setProperty('Icon');
                        obj.setProperty('Icon_I');
                        obj.EventHandlingService.setProperty('Icon', obj.Model.Icon);

                        % stop handling over events
                        return;

                    case 'Theme'
                        if isstruct(propertyValue) && isfield(propertyValue, 'BaseColorStyle')
                            propertyValue = propertyValue.BaseColorStyle;
                        end

                        setServerSideProperty(obj, ...
                            obj.Model, ...
                            propertyName, ...
                            propertyValue, ...
                            event.Data.CommandId...
                            );

                        obj.EventHandlingService.setProperty(propertyName, obj.Model.(propertyName));

                        return;
                    case 'ThemeMode'
                        setServerSideProperty(obj, ...
                            obj.Model, ...
                            propertyName, ...
                            propertyValue, ...
                            event.Data.CommandId...
                            );
                        obj.EventHandlingService.setProperty(propertyName, obj.Model.(propertyName));

                        return;
                end
            end

            % Defer to super
            handleDesignTimeEvent@matlab.ui.internal.DesignTimeGBTComponentController(obj, src, event);
        end

        function additionalPropertyNamesForView = getAdditionalPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be sent to the view for loading in addition to the
            % ones pushed to the view defined by PropertyManagementService
            %
            % Example:
            % 1) Callback function properties
            % 2) Name, Colormap required by client side
            % 3) TODO: should Position/Units be defined in
            % PropertyManagementService?

            additionalPropertyNamesForView = {
                'Color';
                'Name';
                'Icon';
                'AD_ColormapString';
                'NextPlot';
                'CloseRequestFcn';
                'Units';
                'IntegerHandle';
                'NumberTitle';
                'Alphamap';
                'BeingDeleted';
                };

            additionalPropertyNamesForView = [additionalPropertyNamesForView; ...
                getAdditionalPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj)];

            additionalPropertyNamesForView = setdiff(additionalPropertyNamesForView, ...
                {'IsSizeFixed', 'AspectRatioLimits'});

        end

        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view
            %
            % Examples:
            % - Children, Parent, are not needed by the view
            % - Position, InnerPosition, OuterPosition are not updated by
            % the view and are excluded so their peer node values don't
            % become stale

            excludedPropertyNames = {'Title'; 'PropOrder'; 'OuterPosition'; 'IconView'; 'BackgroundColor'; 'Uuid'};

            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.internal.DesignTimeGbtParentingController(obj); ...
                ];

        end

        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % Override to customize CloseRequestFcn value
            %

            viewPvPairs = {};
            % Return empty for default closereq callback
            closeRequestFcn = '';
            if ~strcmp(obj.Model.CloseRequestFcn, 'closereq')
                closeRequestFcn = obj.Model.CloseRequestFcn;
            end

            % Merge super class return value
            viewPvPairs = [viewPvPairs, ...
                {'CloseRequestFcn', closeRequestFcn},...
                {'SizeChangedFcn', obj.Model.SizeChangedFcn},...
                {'ThemeChangedFcn', obj.Model.ThemeChangedFcn},...
                {'WindowButtonDownFcn', obj.Model.WindowButtonDownFcn},...
                {'WindowButtonUpFcn', obj.Model.WindowButtonUpFcn},...
                {'WindowButtonMotionFcn', obj.Model.WindowButtonMotionFcn},...
                {'WindowScrollWheelFcn', obj.Model.WindowScrollWheelFcn},...
                {'ButtonDownFcn', obj.Model.ButtonDownFcn},...
                {'WindowKeyPressFcn', obj.Model.WindowKeyPressFcn},...
                {'WindowKeyReleaseFcn', obj.Model.WindowKeyReleaseFcn},...
                {'KeyPressFcn', obj.Model.KeyPressFcn},...
                {'KeyReleaseFcn', obj.Model.KeyReleaseFcn}
                ];

            % Aliased Colormap Property and aliased ThemeChangedFcn callback property
            viewPvPairs = [viewPvPairs, {'AD_AliasedThemeChangedFcn', obj.Model.ThemeChangedFcn}, ...
                {'AD_ColormapString', inspector.internal.getColormapString(obj.Model.Colormap)}];

            % Merge super class return value
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.internal.DesignTimeGbtParentingController(obj, propertyNames)];
        end

        function postSet( obj, property )
            if isempty(obj.ViewModel) || ~isvalid(obj.ViewModel)
                % View may not be created in test env.
                return;
            end

            if strcmp(property, 'BackgroundColor')
                value = obj.ViewModel.getProperty(property);
                obj.EventHandlingService.setProperty('Color', value);
            end

            postSet@matlab.ui.internal.controller.FigureController(obj, property);
        end
    end

    methods (Access = { ?matlab.ui.Figure, ?tFigureController, ?matlab.ui.internal.DesignTimeUIFigureController } )
        function flushCoalescer(obj)
            % With user-authored components in App Designer, we have a mix
            % of run-time and design-time state.  Run-time Axes syncs its
            % data during Figure flushCoalescer(), which happens before App
            % Designer ViewModel syncs.  This ordering results in issues
            % rendering Axes in user-authored components because the Axes
            % messages arrive before its parent is ready to handle them.
            %
            % By adding this yield to the design-time version of
            % flushCoalescer(), App Designer MF0 has a chance to sync
            % before the Axes messages are sent to the client.  This
            % re-establishes the correct order of messages and allows Axes
            % to render in user-authored components properly.
            matlab.internal.yield("ViewModelCommit");
            % g3284515: Dequeuing Callbacks could lead to the figure being
            % destroyed. Gaurding against that case
            if ~isvalid(obj)
                return
            end
            flushCoalescer@matlab.ui.internal.controller.FigureController(obj);
        end
    end
end
