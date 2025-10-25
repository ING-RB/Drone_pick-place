classdef DesignTimeWebUIContainerController < ...
        matlab.ui.internal.WebUIContainerController & ...
        matlab.ui.internal.DesignTimeGbtParentingController  &...
        appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController
    % DesignTimeWebUIContainerController. Design Time Matlab Controller for User Components

    % Copyright 2020-2024 The MathWorks, Inc.
    properties
        NumericProperties = {};
        ConverterMap
        PropertyView
        Adapter
        PreUpdateListener
        PostUpdateListener

        InitialComponents
    end

    methods
        function obj = DesignTimeWebUIContainerController(model, parentController, proxyView, adapter)
            %CONSTRUCTOR

            %Input verification
            narginchk( 4, 4 );

            % Construct the run-time controller first
            obj = obj@matlab.ui.internal.WebUIContainerController(model, parentController, proxyView);

            % Now, construct the appdesigner base class controllers
            obj = obj@matlab.ui.internal.DesignTimeGbtParentingController(model, parentController, proxyView, adapter);

            % Listen to events from the model for when components are added
            % to a container outside the model's hierarchy.  When these are
            % added we need to mark them so they can be removed when saving
            % the app.
            obj.PreUpdateListener = addlistener(obj.Model, 'PreUpdate', @obj.handlePreUpdate);
            obj.PostUpdateListener = addlistener(obj.Model, 'PostUpdate', @obj.handlePostUpdate);

            obj.Adapter = adapter;
            obj.ConverterMap = containers.Map;

            props = properties(obj.Model);

            for i = 1:length(props)
                try
                    prop = props{i};
                    propValue = obj.Model.(prop);
                catch exception
                    error(message('MATLAB:ui:componentcontainer:ErrorWhileAcessingProperty', ...
                        prop, exception.message));
                end

                if isnumeric(propValue)
                    obj.NumericProperties{end + 1} = props{i};
                end
            end
        end

        function delete(obj)
            delete(obj.PropertyView);
            delete(obj.Adapter);
            delete(obj.PreUpdateListener);
            delete(obj.PostUpdateListener);
        end

        function populateView(obj, proxyView)
            % 1) When loading an app, the proxyView can be empty.  The
            % following methods set properties on the proxyView, so defer
            % them until a proper proxyView has been created.
            % 2) During UAC component construciton, if the user closes app
            % or App Designer immediately, ProxyView would be deleted
            % when this populateView() is called.
            if ~isvalid(obj) || isempty(obj.ViewModel) || ~isvalid(obj.ViewModel)
                return;
            end

            populateView@matlab.ui.internal.DesignTimeGbtParentingController(obj, proxyView);

            % Any processing related to the inspector should only be done
            % when the component is actually created in App Designer.
            % Defer that computation until the controller has a real
            % ProxyView.
            function asyncRunPostPopulateViewTasks()
                if isvalid(obj) && ~isempty(obj.ViewModel) && isvalid(obj.ViewModel)
                    figureParent = ancestor(obj.Model, 'figure');
                    initialChildren = obj.findFigureChildren(figureParent);

                    obj.initializeInspectorPropertyView();

                    obj.detectAddedComponents(figureParent, initialChildren);
                end
            end

            % Property Inspector View Initialization and detection of added
            % components do not need to run synchoronously for UAC rendering,
            % so they could be deferred for better reponsiveness of UAC rendering.
            appdesigner.internal.async.AsyncTask(@asyncRunPostPopulateViewTasks).run();

            obj.Adapter.defineInternalComponentInplaceEditors(obj.Model);

            % This event will let the client know that server side processing is
            % completed for a user component.
            obj.ClientEventSender.sendEventToClient('ServerReady', {});
        end

        function newPos = updatePosition(obj)
            newPos = updatePosition@matlab.ui.internal.WebUIContainerController(obj);

            % For design-time, we should use Position value directly instead of 
            % an updated struct
            newPos = newPos.Value;
        end
    end

    methods
        function testHandleEvent(obj, src, event)
            % Test specific method
            handleDesignTimeEvent(obj,src,event)
        end
    end

    methods (Access=protected)
        function pvPairsForView = getPropertiesForView(obj, propertyNames)
            pvPairsForView = getPropertiesForView@matlab.ui.internal.DesignTimeGbtParentingController(obj, propertyNames);

            callbackPropertyNames = appdesigner.internal.usercomponent.getCallbackPropertyNames(obj.Model);

            % When loading an app, this particular property must be sent to
            % the view to ensure the client-side peer node is created with
            % the property.  This property controls how ViewModel handles
            % the child peer nodes of the user-authored component.
            pvPairsForView = [pvPairsForView, ...
                {'IsUserComponent', true, 'CallbackPropertyNames', callbackPropertyNames}];
        end

        function handleDesignTimeEvent(obj,src,event)
            % For the Panel Component, we need to ensure that the
            % InnerPosition is set properly.  This impacts the setup of the
            % container's canvas and the placement of axes in the container.
            % By having this if-statement, we ensure that InnerPosition is
            % set on the MATLAB Handle.
            % Handle changes in the property editor that needs a
            % server side validation
            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))

                updatedPropertyName = event.Data.PropertyName;
                updatedPropertyValue = event.Data.PropertyValue;
                commandId = event.Data.CommandId;

                if any(strcmp(obj.NumericProperties, updatedPropertyName))
                    updatedPropertyValue = convertClientNumbertoServerNumber(obj, updatedPropertyValue);
                end

                switch ( updatedPropertyName )
                    case {'Location', 'OuterLocation', 'Size', 'OuterSize'}
                        try
                            obj.handlePositionUpdate(updatedPropertyName, updatedPropertyValue);
                            obj.propertySetSuccess(updatedPropertyName, commandId);
                        catch ex
                            obj.propertySetFail(updatedPropertyName, commandId, ex);
                        end
                    otherwise
                        % Before setting the property, find all initial
                        % children of the figure.  This is to detect any
                        % components added by the user component in a
                        % property setter or the update() method.
                        figureParent = ancestor(obj.Model, 'figure');
                        initialChildren = obj.findFigureChildren(figureParent);

                        try
                            obj.setServerSideProperty(obj.Model, updatedPropertyName, updatedPropertyValue, event.Data.CommandId)
                            obj.propertySetSuccess(updatedPropertyName, commandId);
                        catch ex
                            obj.propertySetFail(updatedPropertyName, commandId, ex);
                        end

                        % After setting a property, mark any components
                        % that have been added to the figure outside the
                        % model.
                        obj.detectAddedComponents(figureParent, initialChildren);
                end

                obj.flushProperties();

            elseif (strcmp(event.Data.Name, 'InplaceEdited'))
                try
                    eventData = event.Data;
                    editValue = eventData.EditValue;
                    editorInfo = obj.Adapter.getUserComponentInplaceEditorData(obj.Model);

                    if any(strcmp(obj.NumericProperties, eventData.PublicProperties{1}))
                        editValue = convertClientNumbertoServerNumber(obj, editValue);
                    end
                    editorInfo{eventData.EditIndex}.(eventData.InternalComponentProperty).EditCallbackFcn(obj.Adapter, obj.Model, eventData.PublicProperties, editValue)

                    obj.flushProperties();

                    obj.ClientEventSender.sendEventToClient('inplaceEditResult',...
                        { ...
                        'ErrorMessage', '', ...
                        'Success', true
                        });
                catch ex
                    obj.ClientEventSender.sendEventToClient('inplaceEditResult',...
                        { ...
                        'ErrorMessage', ex.message, ...
                        'Success', false
                        });
                end
            end

            obj.handleEvent(src, event);

            if strcmp(event.Data.Name,'positionChangedEvent') ||strcmp(event.Data.Name,'insetsChangedEvent')
                obj.positionBehavior.handleClientPositionEvent( src, event.Data, obj.Model );
            end
        end

        function handleDesignTimePropertiesChanged(obj, peerNode, valuesStruct)
            % handleDesignTimePropertiesChanged( obj, peerNode, valuesStruct )
            % Controller method which handles property updates in design time.

            % Handle property updates from the client

            % Do not set position related properties when UAC is in a grid
            % but allow other properties to be set (g3460669)
            if isa(obj.Model.Parent,'matlab.ui.container.GridLayout')
                positionRelatedProperties = {
                    'Size', ...
                    'Location',...
                    'OuterSize', ...
                    'OuterLocation',...
                    'Position',...
                    'InnerPosition',...
                    'OuterPosition'
                    };
                for idx = 1:length(positionRelatedProperties)
                    prop = positionRelatedProperties{idx};
                    if isfield(valuesStruct, prop)
                        valuesStruct = rmfield(valuesStruct, prop);
                    end
                end
            end

            handleDesignTimePropertiesChanged@matlab.ui.internal.DesignTimeGbtParentingController(obj, peerNode, valuesStruct);
        end

        function updateToPositionBehavior(obj, src, eventData)
            obj.positionBehavior.handleClientPositionEvent( src, eventData, obj.Model );
        end

        function configureController(obj, model, proxyView)
            % This method is responsible for setting the Controller
            % property of the model.  For user-authored components, when
            % the Controller property is populated, its internal child
            % components can initialize their controllers.
            %
            % When the user component does not have a real ProxyView, the
            % internal child controllers should not be created.  Thus avoid
            % populating the model's Controller property until a real
            % ProxyView is installed.
            if ~(isa(proxyView, "appdesigner.internal.componentview.EmptyProxyView") && ~proxyView.IsLoaded) && (isempty(obj.ViewModel) || ~isvalid(obj.ViewModel))
                return;
            end

            if ~isempty(obj.ViewModel) && isvalid(obj.ViewModel)
                model.configureCanvasController(obj);
            end
            % Defer to superclass implementation
            configureController@matlab.ui.internal.DesignTimeGbtParentingController(obj, model);
        end

        function children = findFigureChildren(~, figureParent)
            children = findall(figureParent);
        end

        function detectAddedComponents(obj, figureParent, initialComponents)
            % Find any components that are not present in the initial
            % components list.  Mark those components as rogues.
            allComponents = obj.findFigureChildren(figureParent);

            addedComponents = setdiff(allComponents, initialComponents);

            obj.markExternalComponents(addedComponents);
        end

        function handlePreUpdate(obj, model, event)
            % When the user component is about to run its update method,
            % it will fire an event.  At this time capture the children of
            % the figure.

            obj.InitialComponents = obj.findFigureChildren(ancestor(model, 'figure'));
        end

        function handlePostUpdate(obj, model, event)
            figureParent = ancestor(model, 'figure');
            obj.detectAddedComponents(figureParent, obj.InitialComponents);

            obj.InitialComponents = [];
        end
    end

    methods
        function initializeInspectorPropertyView(obj)
            propertyViewClass = obj.Adapter.getComponentPropertyView();
            obj.PropertyView = feval(propertyViewClass, obj.Model);

            obj.appendInspectorInfo();

            callbackNames = appdesigner.internal.usercomponent.getCallbackPropertyNames(obj.Model);
            pvPairs = {'CallbackPropertyNames', callbackNames};

            for i = 1: numel(callbackNames)
                callbackValue = obj.Model.(callbackNames{i});
                % Ensure callback value is a string var name (see g2378386)

                % Client uses the peer node properties to fetch the callback names, so set the property
                % even if it is empty to make sure the property is not undefined.
                if isvarname(callbackValue) || isempty(callbackValue)
                    pvPairs = [pvPairs, {callbackNames{i}, callbackValue}];
                end
            end

            viewmodel.internal.factory.ManagerFactoryProducer.setProperties(obj.ViewModel, pvPairs);
        end

        function appendInspectorInfo(obj)
            % appendInspectorInfo(obj)
            % In the method, addtional properties will be added to ProxyView peer node
            % These properties provide the information which is
            % required to render property sheet at the client.

            inspectorInfo = struct();
            inspectorInfo.groups = obj.createGroups();
            inspectorInfo.properties = string(properties(obj.PropertyView));
            inspectorInfo.inheritedPropertyNames = properties('matlab.ui.componentcontainer.ComponentContainer');

            [renderers, classNames] = arrayfun(@(prop) obj.getInspectorRenderer(prop, inspectorInfo.inheritedPropertyNames), ...
                inspectorInfo.properties, 'UniformOutput', false);

            inspectorInfo.rendererInfo = cell2struct(renderers, inspectorInfo.properties);
            inspectorInfo.classNameInfo = cell2struct(classNames, inspectorInfo.properties);

            inspectorInfo = obj.removePropertiesWithNoEditor(inspectorInfo);
            designProps = obj.getDesignProperties(inspectorInfo.properties);
            designProps = rmfield(designProps, 'Position'); % Position is determined by client.
            pvPairs = [namedargs2cell(designProps), {'InspectorInfo', inspectorInfo, 'ReadyToInspect', true}];
            viewmodel.internal.factory.ManagerFactoryProducer.setProperties(obj.ViewModel, pvPairs);
        end

        function inspectorInfo = removePropertiesWithNoEditor(~, inspectorInfo)
            rendererInfo = inspectorInfo.rendererInfo;
            propertiesWithNoEditor = [];

            for i = 1:numel(inspectorInfo.properties)
                if isempty(rendererInfo.(inspectorInfo.properties(i)).InPlaceEditor)
                    propertiesWithNoEditor = [propertiesWithNoEditor, inspectorInfo.properties(i)];
                end
            end

            if ~isempty(propertiesWithNoEditor)
                inspectorInfo.properties = setdiff(inspectorInfo.properties, propertiesWithNoEditor);
                filteredIndices = cellfun(@(x) ~any(strcmp(propertiesWithNoEditor, x.name )) , inspectorInfo.groups(1).items);
                inspectorInfo.groups(1).items = inspectorInfo.groups(1).items(filteredIndices);
            end
        end

        function [renderer, dataType] = getInspectorRenderer(obj, propertyName, inheritedPropertyNames)
            % getInspectorRenderer(obj, property)
            % Get the inspector renderer information for each property.
            % This is required to show the right editor type for a property in inspector.
            import internal.matlab.datatoolsservices.FormatDataUtils
            import internal.matlab.datatoolsservices.WidgetRegistry
            import matlab.ui.internal.DesignTimeWebUIContainerController
            widgetRegistry = WidgetRegistry.getInstance;

            supportedDataTypes = DesignTimeWebUIContainerController.getInspectorSupportedDataTypes();
            multiLineEditorDataTypes = DesignTimeWebUIContainerController.getMultiLineEditorSupportedDataTypes();
            multiLineEditorType = 'internal.matlab.editorconverters.datatype.MultipleItemsValue';

            property = findprop(obj.PropertyView, propertyName);
            value = obj.PropertyView.(propertyName);

            classType = FormatDataUtils.getClassString(value, false, true);
            [propType, isCatOrEnum, dataType] = obj.getPropAndDataType(property, classType, obj.PropertyView);

            [renderer, ~, matchedVariableClass] = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', dataType);

            if ~isequal(matchedVariableClass, dataType) && isCatOrEnum
                renderer = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', 'categorical');
            elseif isempty(renderer.CellRenderer)
                renderer = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', classType);
            end

            % Reset the editor if the property type is not in the list of
            % supported data types and the property is not part of the
            % 'PassthroughProps' on the PropertyView object.
            if ~isCatOrEnum && ~any(strcmp(inheritedPropertyNames, propertyName)) ...
                    && ~any(strcmp(supportedDataTypes, matchedVariableClass)) ...
                    && ~any(strcmp(matchedVariableClass, supportedDataTypes)) ...
                    && ~(isprop(obj.PropertyView, 'PassthroughProps') && any(strcmp(propertyName, obj.PropertyView.PassthroughProps)))
                renderer.InPlaceEditor = '';
                renderer.CellRenderer = '';
            end

            % Modify the renderer to be a multi-line editor if property
            % supports multi-line editing.
            if any(strcmp(multiLineEditorDataTypes, matchedVariableClass))
                renderer = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', multiLineEditorType);
            end

            renderer = obj.setInPlaceEditorProperties(renderer, value, propType, propertyName);
        end

        function renderer = setInPlaceEditorProperties(obj, renderer, value, propertyType, propertyName)
            converter = [];
            if ~isempty(renderer.EditorConverter)
                if isKey(obj.ConverterMap, renderer.EditorConverter)
                    converter = obj.ConverterMap(renderer.EditorConverter);
                else
                    converter = eval(renderer.EditorConverter);
                    obj.ConverterMap(renderer.EditorConverter) = converter;
                end

                converter.setServerValue(value, propertyType, propertyName);

                % In Place Editor
                renderer.richEditorProperties = converter.getEditorState;
            end
        end

        function designProps = getDesignProperties(obj, propertiesInInspector)
            % getDesignProperties(obj)
            % Get the design properties required for property inspector and remove read only properties.

            designProps = obj.convertObjectPropertiesToStruct(propertiesInInspector);
            fieldNames = fieldnames(designProps);

            readOnlyProps = appdesigner.internal.componentadapter.uicomponents.adapter.UserComponentAdapter.listNonPublicProperties(obj.Model)';

            propsToRemove = intersect(fieldNames, readOnlyProps);

            for i = 1:numel(propsToRemove)
                designProps = rmfield(designProps, propsToRemove{i});
            end
        end

        function groups = createGroups(obj)
            % createGroups(obj)
            dataModel = internal.matlab.inspector.MLInspectorDataModel('inspector', '', false);
            dataModel.Data = obj.PropertyView;
            viewModel = internal.matlab.inspector.InspectorViewModel(dataModel);
            groups = viewModel.getRenderedGroupData();

            % Clean up the instances.
            delete(viewModel);
            delete(dataModel);
        end

        function st = convertObjectPropertiesToStruct(obj, propertiesInInspector)
            st = struct();

            for i = 1:length(propertiesInInspector)
               if (isprop(obj.Model, propertiesInInspector{i}))
                st.(propertiesInInspector{i}) = obj.Model.(propertiesInInspector{i});
               end
            end
        end

        function [propType, isCatOrEnum, dataType] = getPropAndDataType(~, prop, classType, rawData)
            % getPropAndDataType(obj, prop, classType, rawData)

            if isKey(rawData.PropertyTypeMap, prop.Name)
                propType = rawData.PropertyTypeMap(prop.Name);
            else
                propType = class(rawData.(prop.Name));
            end

            [isCatOrEnum, dataType] = ...
                internal.matlab.editorconverters.ComboBoxEditor.isCategoricalOrEnum(...
                classType, propType, rawData.(prop.Name));
        end

        function flushProperties(obj)
            % flushProperties - This method is used to flush properties from model to peerNode.
            % There are some dependency properties which will be auto-calculated when some
            % other properties change, and it's hard to find all the dependency properties.

            modelProperties = obj.Model;
            modelPropertiesFields = fields(modelProperties);
            modelPropertiesFields = [modelPropertiesFields; 'BackgroundColorMode'];

            for k=1:length(modelPropertiesFields)
                field = modelPropertiesFields{k};
                if(obj.EventHandlingService.hasProperty(field))
                    if strcmp(field, 'Position') 
                        % Do not set position information when component is in a grid
                        % as the server side model will not have accurate position.
                        % Grid manages the position using the Row & Column details.
                        if ~isa(obj.Model.Parent,'matlab.ui.container.GridLayout')
                            obj.EventHandlingService.setProperty('Position', obj.Model.Position);
                            obj.EventHandlingService.setProperty('Location', obj.Model.Position(1:2));
                            obj.EventHandlingService.setProperty('OuterLocation', obj.Model.Position(1:2));
                            obj.EventHandlingService.setProperty('Size', obj.Model.Position(3:4));
                            obj.EventHandlingService.setProperty('OuterSize', obj.Model.Position(3:4));
                        end
                    else
                        obj.EventHandlingService.setProperty(field, obj.Model.(field));
                    end
                end
            end
        end
    end

    methods(Static=true)
        function supportedTypes = getInspectorSupportedDataTypes()
            % getInspectorSupportedDataTypes - This method returns the list of
            % properties for which we have a good editor in inspector. Properties with any of
            % below data type will only be shown in inspector.
            supportedTypes = {
                'double', ...
                'single', ...
                'int8', ...
                'int16', ...
                'int32', ...
                'int64', ...
                'uint8', ...
                'uint16', ...
                'uint32', ...
                'uint64', ...
                'logical', ...
                'char', ...
                'string', ...
                'cell'
                };
        end

        function multiTypeEditorTypes = getMultiLineEditorSupportedDataTypes()
            % getMultiLineEditorSupportedDataTypes - This method returns the list of
            % properties for which a multi-line editor will be shown in inspector.
            multiTypeEditorTypes = {'cell'};
        end

        function isOptimizedLoad = isOptimizedForAppLoad(~)
            isOptimizedLoad = false;
        end
    end

    methods (Access = private)
        function markExternalComponents(obj, addedComponents)
            % Set Serializable to off for these components so they are not
            % saved in the figure.
            set(addedComponents, 'Serializable', 'off');
        end
    end
end
