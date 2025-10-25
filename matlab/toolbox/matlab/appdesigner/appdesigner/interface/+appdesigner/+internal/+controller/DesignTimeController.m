classdef DesignTimeController < appdesservices.internal.interfaces.controller.AbstractControllerMixin & ...
        appdesservices.internal.interfaces.controller.mixin.ClientEventReceiver
    %DESIGNTIMECONTROLLER This is a class that handles
    % AppDesigner specific actions such as generating code, CodeName or grouping.

    % Copyright 2015-2023 The MathWorks, Inc.

    % Controller properties
    properties (Access = 'private')
        % This is the component model that will be updated in response to
        % design time events.
        DesignTimeModel

        % Specifies what AppType this instance is a child of for codegen
        AppType

        CurrentTheme

        ThemeChangedListener

        FileFormat
    end

    properties (GetAccess=protected, SetAccess=immutable)
        % Component specific adapter instance.  This adapter will be of
        % class 'VisualComponentAdapter.
        ComponentAdapter
    end

    methods (Abstract, Access = 'protected')
        % HANDLEDESIGNTIMEPROPERTIESCHANGED - Delegates the logic of
        % handling the event to the runtime controllers via the
        % handlePropertiesChanged method
        handleDesignTimePropertiesChanged(obj, src, valuesStruct);

        % HANDLEDESIGNTIMEEVENT - Delegates the logic of
        % handling the peerEvent to the runtime controllers via the
        % handleEvent method
        handleDesignTimeEvent(obj, src, event);
    end

    properties (Constant)
        % Class responsible for using the adapter to create code for a
        % component.  This object will be shared by all components.
        ComponentCodeGenerator = appdesigner.internal.codegeneration.ComponentCodeGenerator();

        % These are properties that are appdesigner specific
        DesignTimePropertiesToHandle = {'CodeName', 'GroupId', 'ImageRelativePath', 'AppTypeProperties'};
    end


    methods

        function obj = DesignTimeController(model, proxyView, adapter)

            %
            % Inputs:
            %
            %   model             The model being controlled by this
            %                     controller
            %
            %
            %   proxyView         Used when  the ProxyView is already
            %                     created.  When passed in, instead of
            %                     creating a new ProxyView, this ProxyView
            %                     is used instead.
            %
            %                     Should be [ ] when a view does not
            %                     exist.
            %
            %   codeGenerator     Object that knows how to generate code
            %                     using the component and the adapter.

            narginchk(2,3)
            obj.DesignTimeModel = model;
            obj.ComponentAdapter = adapter;

            % Add dynamic design time property to the model
            obj.addDesignTimeProperties();

            if ~isempty(proxyView) && ~isempty(proxyView.PeerNode) ...
                    && ~isa(proxyView, 'appdesigner.internal.componentview.EmptyProxyView')

                % Set how to respond to client on property sets
                if feature('AppDesignerPlainTextFileFormat')
                    obj.setFileFormat();
                end

                % Set up ClientEventReceiver listeners
                obj.PropertiesSetHandlerFcn = @obj.handleClientPropertiesSet;
                obj.PeerEventHandlerFcn = @obj.handleClientPeerEvent;
                obj.startReceivingClientEvents(proxyView.PeerNode);

                % During loading, the proxyView would be either empty or
                % an EmptyProxyView object
                % Need to update DesignTimeProperties immediately after
                % controller creation when a component is created from client
                % side, otherwise there's a timing issue which ends up with
                % empty CodeName:
                % On client side, if undo deletiong of a component and reparent
                % very quickly, reparent event would come from PeerModel
                % Java thread before the following populateView() has a chance
                % to update CodeName on DesignTimeProperties. It could be
                % reproduced in Gridify
                obj.updateDesignTimePropertiesFromViewModel(proxyView.PeerNode);
            end

            % Retrieve the DirtyPropertyStrategy after adding
            % DesignTimeProperties to ensure the correct strategy is
            % returned.
            if isa(obj.Model, 'appdesservices.internal.interfaces.model.AbstractModel')
                dirtyPropertyStrategy = appdesservices.internal.interfaces.model.DirtyPropertyStrategyFactory.getDirtyPropertyStrategy(obj.Model);
                obj.Model.setDirtyPropertyStrategy(dirtyPropertyStrategy);
            end
        end

        function populateView(obj, proxyView)
            % ProxyView will be empty when controller is created in the
            % context of getting the design time defaults.  This may happen
            % in the method getComponentDesignTimeDefaults in the adapters
            % The controller class listens to GuiEvent of ProxyView so that
            % it can respond to events from the view.


            function asyncUpdateGeneratedComponentCode()
                if isvalid(obj) && ~isempty(obj.Model) && isvalid(obj.Model) ...
                        && ~isempty(proxyView.PeerNode) && isvalid(proxyView.PeerNode)
                    obj.updateGeneratedCode();
                end
            end

            if nargin == 2 && ~isempty(proxyView)
                if ~isempty(proxyView.PeerNode)
                    if ~proxyView.HasSyncedToModel
                        % If the model is a component model, and it is created
                        % during loading an app, the properties in the model
                        % are already synced with the proxy view because the
                        % model object is loaded from the saved app.
                        %
                        % Otherwise, the model is created through client-driven,
                        % model needs to apply properties from the view

                        % Apply the state of the view to the model
                        %
                        % This is done in a view-driven workflow where the model
                        % needs to be hooked up to the view

                        % Update 'Layout' property which is shared among
                        % all components, and needs special handling. All
                        % other property would be handled by
                        % AbstractController for VC components, and
                        % DesignTimeGBTComponentController for GBT
                        % components
                        % Todo: need to refactor in the future how App
                        % Designer handles component property initial
                        % syncing and updating:
                        % 1) Keep design-time logic out of runtime
                        % controller as possible as we could
                        % 2) Make all components share the same logic to
                        % sync properties.
                        % 3) Design a unfified way for all components to
                        % leverage runtime logic to update properties.
                        % 4) How to share common logic among non-component
                        % controllers and component design-time
                        % controllers.
                        obj.handleLayoutProperty(obj.getViewModelProperties(proxyView.PeerNode));

                        % Check for ContextMenuID and assign the
                        % ContextMenu graphics handle, normally this only
                        % done via properties set, but while undo'ing the
                        % deletion of a component with a context menu, we
                        % will need to handle it during creation
                        % g2128279
                        obj.handleContextMenuProperties(obj.getViewModelProperties(proxyView.PeerNode));
                    end

                    % When loading an app, no peer node associated to the
                    % proxyview.
                    % otherwise need to update code gen
                    % Code generation does not need to happen immediately,
                    % so we can put it into taks queue of MATLAB.
                    appdesigner.internal.async.AsyncTask(@asyncUpdateGeneratedComponentCode).run();
                end

            end

        end

        function props = getViewModelProperties(obj, viewModel)
            if isempty(viewModel)
                props = [];
            else
                originalProps = viewmodel.internal.factory.ManagerFactoryProducer.getProperties(viewModel);
                props = obj.ComponentAdapter.processPropertiesToSet(originalProps);
            end
        end

        function delete(obj)
            % Clean up listeners
            obj.stopReceivingClientEvents();

            if ~isempty(obj.ThemeChangedListener)
                delete(obj.ThemeChangedListener);
            end
        end

        function updateGeneratedCode(obj)
            % Refreshes the generated code for this controller's component

            % CodeGen update for client and server-side property updates
            % we use isvalid to make sure the event does not fire to the deleted object.
            if isvalid(obj) && ~isempty(obj.ViewModel)
                % todo: with mf0, for ButtonGroup, it would be triggered to
                % call this updateGeneratedCode() for a child when it's
                % proxyview is not created yet during loading phase. Need
                % to figure out why?

                if isempty(obj.AppType)
                    obj.AppType = obj.getAppType(obj.DesignTimeModel);
                end

                % Remove the feature flags once the Themes is OBD in WebUI.
                if feature('webui') && isempty(obj.CurrentTheme)
                    obj.CurrentTheme = obj.getCurrentTheme(obj.DesignTimeModel);
                end

                % Remove the feature flags when plain-text app is live
                if feature('AppDesignerPlainTextFileFormat') && isempty(obj.FileFormat)
                    obj.FileFormat = 'mlapp';
                end

                if feature('AppDesignerPlainTextFileFormat') && strcmp(obj.FileFormat, 'm')
                    dirtyProps = viewmodel.internal.factory.ManagerFactoryProducer.getProperty(obj.ViewModel, 'DirtyProps');
                    obj.DesignTimeModel.DesignTimeProperties.DirtyProps = obj.ComponentAdapter.getComponentDirtyProps(obj.DesignTimeModel, obj.CurrentTheme);

                    if isempty(dirtyProps) || ~isequaln(obj.DesignTimeModel.DesignTimeProperties.DirtyProps, dirtyProps)
                        pvPairs = {'DirtyProps', obj.DesignTimeModel.DesignTimeProperties.DirtyProps};
                        viewmodel.internal.factory.ManagerFactoryProducer.setProperties(obj.ViewModel, pvPairs, []);
                    end
                else
                    code = viewmodel.internal.factory.ManagerFactoryProducer.getProperty(obj.ViewModel, 'ComponentCode');

                    if (~isempty(code))
                        code = cell(code);
                        obj.DesignTimeModel.DesignTimeProperties.ComponentCode = code;
                    end

                    obj.DesignTimeModel.DesignTimeProperties.ComponentCode = obj.ComponentCodeGenerator.getComponentGenerationCode(...
                        obj.DesignTimeModel, obj.ComponentAdapter, obj.AppType, obj.CurrentTheme);

                    if isempty(code) || ~strcmp(char(code), char(obj.DesignTimeModel.DesignTimeProperties.ComponentCode))
                        pvPairs = {'ComponentCode', obj.DesignTimeModel.DesignTimeProperties.ComponentCode};
                        viewmodel.internal.factory.ManagerFactoryProducer.setProperties(obj.ViewModel, pvPairs, []);
                    end
                end
            end
        end

        function arrangedChildren = adjustChildrenOrderBasedOnPeerNodes(obj, model)
            % Get all children regardless of HandleVisibility value
            children = obj.getAllChildren(model);

            numberOfChildren = numel(children);

            controller = model.getControllerHandle();

            arrangedChildren = cell(1, numberOfChildren);

            % Construct a map to store all child models by using CodeName
            % as key
            % Also create a list of runtime models, which don't have
            % DesignTimeProperties or a CodeName.  These runtime models
            % must be included to create a true permutation of the Children
            % array; otherwise we would only generate a subset of Children.
            childrenModelMap = struct;
            runtimeChildren = {};
            for ix = 1: numberOfChildren
                if isprop(children(ix), 'DesignTimeProperties')
                    childrenModelMap.(children(ix).DesignTimeProperties.CodeName) = children(ix);
                else
                    runtimeChildren(end + 1) = {children(ix)};
                end
            end

            % Loop each child peer node
            childPeerNodes = viewmodel.internal.factory.ManagerFactoryProducer.getChildren(controller.ViewModel);
            numberOfChildPeerNodes = numel(childPeerNodes);
            for ix = 1 : numberOfChildPeerNodes
                peerNodeIx = ix;
                if obj.isChildOrderReversed()
                    peerNodeIx = numberOfChildPeerNodes - ix + 1;
                end
                peerNodeCodeName = childPeerNodes(peerNodeIx).getProperty('CodeName');

                if isfield(childrenModelMap, peerNodeCodeName)
                    arrangedChildren{ix} = childrenModelMap.(peerNodeCodeName);
                    childrenModelMap = rmfield(childrenModelMap, peerNodeCodeName);
                end
            end

            arrangedChildren = [arrangedChildren{:}];
            unorderedChildren = struct2cell(childrenModelMap);
            arrangedChildren = [arrangedChildren unorderedChildren{:} runtimeChildren{:}];

            % Axes must be placed at the end of the list of children.
            % If axes are not at the end, a warning is shown related to 'Illegal
            % permutation'. See g2258723

            % Determine which components are axes
            isComponentAnAxes = false(size(arrangedChildren));
            for i = 1:length(arrangedChildren)
                % Use UIAxes superclass here as a user component may have
                % injected a normal axes rather than a UIAxes.
                isComponentAnAxes(i) = isa(arrangedChildren(i), 'matlab.graphics.axis.Axes');
            end

            % Place axes at the end of the list of children.
            arrangedChildren = [arrangedChildren(~isComponentAnAxes), arrangedChildren(isComponentAnAxes)];
        end

        function arrangeChildren = adjustChildOrder(~, parentController, child, newIndex)
            % Returns an updated child list based on the new index
            % the specified child needs to be at in its parent
            %
            % This method is used by
            % 1. reparentComponent() i.e. when components are
            % reparented/re-positioned
            % into a different index within the same parent
            % Eg: Reorder Tabs in Tabgroups
            % and
            % 2. processClientCreatedPeerNode() i.e. when components are
            % placed in specific indexes on creation
            % Eg: Menus are maintained at the bottom of Figure
            % hierarchy

            % Get all children regardless of HandleVisibility value
            children = parentController.getAllChildren(parentController.Model);

            numberOfChildren = length(children);

            % Remove the newly added child from the Children list
            % to add it back later at the right index
            children(child == children) = [];

            if(parentController.isChildOrderReversed())
                % Imagine the view has said "insert child at index 3 in an
                % children array of length 10"
                %
                % For components that store children in opposite order of
                % insertion (panels, figure, etc...) then inserting at
                % index 3 really means "3 from the end"

                % adding max here because the wrong creating order of peernode
                % will cause the newIndex to be negative.
                % ex. let's say 5 models have already been added to children of parent
                % model. But now, if a peerNode with index 7 come in, 5 - 7
                % will be -2 which is negative, in that case we put this
                % peerNode in the first of children.

                % Even though the child order is reversed, all Axes must be
                % at the end of the children list.  This is a run-time
                % requirement.  The newIndex must be calculated such that
                % all axes are always at the end.
                numberOfAxes = 0;
                for i = 1:length(children)
                    numberOfAxes = numberOfAxes + double(isa(children(i), 'matlab.ui.control.UIAxes'));
                end

                % If the child is an axes, always place it immediate above the top axes.
                if isa(child, 'matlab.ui.control.UIAxes')
                    newIndex =  max(1, numberOfChildren - numberOfAxes);
                else
                    newIndex = max(1, numberOfChildren - numberOfAxes - (newIndex - 1));
                end
            end

            arrangeChildren =  [...
                children(1 : newIndex - 1); ...
                child; ...
                children(newIndex : end)...
                ];
        end

        function handleComponentReparented(~)
            % no-op.  Allow components to optionally implement this method in order
            % to complete custom logic when they are reparented.
        end

        function handleParentSizeLocationChanged(~)
            % no-op.  Allow components to optionally implement this method in order
            % to complete custom logic when their parent is resized.
        end

        function adjustedProps = adjustParsedCodegenPropertiesForAppLoad(~, parsedProperties)
            % Provides an opportunity for controllers to modify what was
            % considered dirty, parsed from generated code.
            % eg: DesignTimeUIAxes needs to convert aliases
            % eg: TreeNode needs to force 'NodeId'
            % eg: Panel Title default is different between runtime and
            %     designtime

            % always include layout properties
            adjustedProps = [parsedProperties, {'LayoutConstraints', 'Layout'}];

            % always include tick-mode properties
            for i=1:length(parsedProperties)
                if contains(parsedProperties{i}, 'Ticks')
                    adjustedProps = [adjustedProps, {append(parsedProperties{i}, 'Mode')}];
                end
            end
        end

        function adjustedProps = adjustPositionalPropertiesForAppLoad(obj, properties)
            % Provides an opportunity for controllers to modify what
            % positional properties are sent to the client during app load.
            % This is required because some components treat position
            % (inner/outer) different than others and there is no
            % 'one-size-fits-all' which works for all components.

            % By default 'Position' 'OuterPosition' and 'InnerPosition'
            % will be applied if it is a property of the model, and
            % inherited controllers can make adjustments where needed.

            adjustedProps = properties;
            propNames = adjustedProps(1:2:end);

            needPosition = true;
            needOuterPosition = true;
            needInnerPosition = true;

            for i = 1:length(propNames)
                if strcmp(propNames{i}, 'Position')
                    needPosition = false;
                elseif strcmp(propNames{i}, 'OuterPosition')
                    needOuterPosition = false;
                elseif strcmp(propNames{i}, 'InnerPosition')
                    needInnerPosition = false;
                end
            end

            if needPosition && isprop(obj.Model, 'Position')
                adjustedProps = [adjustedProps, {'Position', obj.Model.Position}];
            end

            if needOuterPosition && isprop(obj.Model, 'OuterPosition')
                adjustedProps = [adjustedProps, {'OuterPosition', obj.Model.OuterPosition}];
            end

            if needInnerPosition && isprop(obj.Model, 'InnerPosition')
                adjustedProps = [adjustedProps, {'InnerPosition', obj.Model.InnerPosition}];
            end
        end

        function updatedProps = addPropertyModeValues(obj, properties)
            % Add mode property values to corresponding properties
            %
            % This function adds mode property values for properties that have a
            % corresponding mode property. It iterates through the input properties,
            % checks for the existence of a mode property, and adds it to the output
            % if it exists and is not excluded for view.
            %
            % Inputs:
            %   properties - Cell array of property names and values
            %
            % Outputs:
            %   updatedProps - Cell array of property names and values, including
            %                  added mode properties
            % Associated gecks: g3477748,g3532103

            % Preallocate the maximum amount of space required for the array
            maxPairs = floor(length(properties) / 2);
            modePVPairs = cell(1, maxPairs * 2);
            pairCount = 0; % Counter for actual pairs added

            for idx = 1:2:length(properties)
                modeName = strcat(properties{idx}, 'Mode');
                if isprop(obj.Model, modeName) && ...
                        ~any(ismember(modeName, obj.ExcludedPropertyNamesForView))
                    pairCount = pairCount + 1;
                    modePVPairs{2 * pairCount - 1} = modeName;
                    modePVPairs{2 * pairCount} = obj.Model.(modeName);
                end
            end

            % Trim the preallocated array to the actual number of pairs added
            modePVPairs = modePVPairs(1:2 * pairCount);

            updatedProps = [properties, modePVPairs];
        end

        function isOptimizedLoad = isOptimizedForAppLoad(~)
            isOptimizedLoad = true;
        end

        function isThemed = propertyVariesByTheme(obj, property, objType)

            % Certain properties in some components are not properly
            % identified using getThemePropertyMapping(), so we test for
            % them specifically.
            themedProperties = dictionary;
            themedProperties('matlab.ui.Figure') = {'Theme'};
            themedProperties('matlab.ui.container.Tab') = {'ForegroundColor'};
            themedProperties('matlab.ui.control.HTML') = {'CurrentTheme'};
            themedProperties('matlab.ui.control.Table') = {'BackgroundColor'};
            themedProperties('matlab.ui.control.UIAxes') = {'ColorOrder'};

            if ismember(objType, themedProperties.keys) && any(strcmp(property, themedProperties(objType)))
                isThemed = true;
                return;
            end
            isThemed = obj.Model.getThemePropertyMapping(property, 'on') ~= "";
        end
    end

    methods(Access=protected, Sealed)

        function filteredValuesStruct = handleChangedPropertiesWithMode(obj, model, changedValuesStruct, includeHiddenProperty, priorModePropertyOnModel)
            % value not changed for those properties with corresponding
            % 'xxxMode' property
            % if the value passed in is the same as the value on the model
            % object, and the corresponding 'xxxMode' value is 'auto'
            % Remove it to avoid unncessary setting to the model object.
            % Otherwise a side effect is that during drag/drop creating a
            % new component, 'xxxMode' property would be updated from 'auto'
            % to 'manual' regardless the value is the same as default value
            % or not.

            % Use the cached properties for mode and matched properties
            if isempty(obj.PropertiesWithModePropertyNames) || isempty(obj.ModePropertyNames)
                [obj.PropertiesWithModePropertyNames, obj.ModePropertyNames] = obj.parseClassPropertyNamesForMode(class(obj.Model), includeHiddenProperty);
            end

            % Mode properties should be set on the model after its corresponding property is set.
            % To ensure the order is preserved, sort the fields in struct using orderfields.
            filteredValuesStruct = orderfields(changedValuesStruct);
            allChangedFieldNames = fields(filteredValuesStruct);

            % Loop through changed properties
            for idx = 1:numel(allChangedFieldNames)
                propName = allChangedFieldNames{idx};

                % Analyze properties that have corresponding mode property
                if any(strcmp(obj.PropertiesWithModePropertyNames, propName))
                    shouldRemoveField = false;

                    % Property has corresponding Mode
                    modeName = obj.ModePropertyNames(strcmp(obj.PropertiesWithModePropertyNames, propName));
                    if any(strcmp(allChangedFieldNames, modeName))
                        modeValue = filteredValuesStruct.(modeName);

                        if strcmp(modeValue, 'auto') && strcmp(obj.Model.(modeName), 'auto')

                            % The mode was passed in with 'auto', and so do not
                            % update sibling property
                            shouldRemoveField = true;
                        end

                        % Property name does not have corresponding Mode
                    else
                        modeValue = model.(modeName);

                        if isequal(filteredValuesStruct.(propName), model.(propName)) || ...
                                priorModePropertyOnModel && strcmp(modeValue, 'auto')

                            shouldRemoveField = true;
                        end
                    end

                    if(shouldRemoveField)
                        % Remove the property, it should not be updated
                        % manually since the mode should stay as 'auto'.
                        filteredValuesStruct = rmfield(filteredValuesStruct, propName);
                    end
                end
            end
        end

        function setFileFormat(obj)
            % Sets what is ultimately returned to client after property
            % sets - dirty properties or generated MATLAB code

            fig = ancestor(obj.DesignTimeModel, 'matlab.ui.Figure');

            if isprop(fig, 'AppModel') && isprop(fig.AppModel, 'FileFormat')
                obj.FileFormat = fig.AppModel.FileFormat;
            else
                obj.FileFormat = 'mlapp';
            end

        end
    end

    methods(Access = 'private')

        function peerNodeIndex = getPeerNodeIndexByCodeName(obj, codeName, parentPeerNode)

            % use code name to find the peerNode for specific model
            % this solution is based on the fact: the CodeName is unique
            children = viewmodel.internal.factory.ManagerFactoryProducer.getChildren(parentPeerNode);

            for i=1:size(children)
                child = children(i);
                if strcmp(codeName, child.getProperty('CodeName'))
                    peerNode = child;
                    break;
                end
            end
            peerNodeIndex = viewmodel.internal.factory.ManagerFactoryProducer.getChildIndex(peerNode, parentPeerNode);
        end

        function realIdx = getIndexToInsertChild(obj, startIdx, endIdx, newIdx, children, parentController)
            % binary search the children model array to find the correct index
            % to inset the new component model
            %
            % children - array of model for the children of parentPeerNode
            % newIdx - 1 based index of the new component peerNode in the children of parentPeerNode
            parentPeerNode = parentController.ViewModel;
            if startIdx > endIdx
                realIdx = startIdx;
            else
                midIdx = ceil((startIdx + endIdx)/2);
                codeName = children(midIdx).DesignTimeProperties.CodeName;
                childIdx = obj.getPeerNodeIndexByCodeName(codeName, parentPeerNode);
                if(parentController.isChildOrderReversed())
                    % Imagine the view has said "insert child at index 3 in an
                    % children array of length 10"
                    %
                    % For components that store children in opposite order of
                    % insertion (panels, figure, etc...) then inserting at
                    % index 3 really means "3 from the end"
                    dir = -1;
                else
                    dir = 1;
                end
                if newIdx*dir > childIdx*dir
                    realIdx = obj.getIndexToInsertChild(midIdx+1,endIdx, newIdx, children, parentController);
                else
                    realIdx = obj.getIndexToInsertChild(startIdx, midIdx-1, newIdx, children, parentController);
                end
            end
        end

        function updateDesignTimePropertiesFromViewModel(obj, viewModel)
            % Update CodeName and groupId and AppTypeProperties if exists
            for index = 1: numel(obj.DesignTimePropertiesToHandle)
                propertyName = obj.DesignTimePropertiesToHandle{index};
                value = viewmodel.internal.factory.ManagerFactoryProducer.getProperty(viewModel, propertyName);

                if ~isempty(value)
                    obj.DesignTimeModel.DesignTimeProperties.(propertyName) = value;
                end
            end
        end

        function appType = getAppType(~, designTimeModel)
            % Travels upwards from the argued designTimeModel until finding appModel
            appModel = designTimeModel;

            % Default to standard app, only set the value if we found a
            % figure, with app model, with metadata model
            appType = appdesigner.internal.serialization.app.AppTypes.StandardApp;

            while ~isa(appModel, 'appdesigner.internal.model.AppModel')
                if isa(appModel, 'matlab.ui.Figure')
                    if isprop(appModel, 'AppModel')
                        appModel = appModel.AppModel;
                    else
                        break;
                    end
                else
                    appModel = appModel.Parent;
                end
            end

            % MetadataModel is created on the client, it will not be
            % available for tests who run without a client.
            if isprop(appModel, 'MetadataModel') && isa(appModel.MetadataModel, 'appdesigner.internal.model.MetadataModel')
                appType = appModel.MetadataModel.AppType;
            end
        end

        function currentTheme = getCurrentTheme(obj, designTimeModel)
            currentTheme = '';

            if ~isempty(obj.ThemeChangedListener)
                delete(obj.ThemeChangedListener);
            end

            uiFigureModel = ancestor(designTimeModel, 'matlab.ui.Figure');

            if isa(uiFigureModel, 'matlab.ui.Figure') && isprop(uiFigureModel, 'Theme') && ...
                    ~isempty(uiFigureModel.Theme)
                currentTheme = uiFigureModel.Theme.BaseColorStyle;
                obj.ThemeChangedListener = ...
                    addlistener(uiFigureModel, 'ThemeChanged', @(src, e)handleThemeChanged(obj, e));
            end
        end

        function handleThemeChanged (obj, event)
            obj.CurrentTheme = event.Theme.BaseColorStyle;
        end

        function handleClientPropertiesSet(obj, source, event, ~)
            isFromClient = event.isFromClient;
            valuesStruct = event.Data.newValues;

            filteredValuesStruct = obj.handleComponentDynamicDesignTimeProperties(valuesStruct, isFromClient);

            if ~isempty(filteredValuesStruct)
                % Excluding dynamic design time properties, e.g,
                % CodeName, GroupId, there are still other component's
                % own properties changed
                if isFromClient
                    % Update the model if the properties set happened
                    % from the client
                    obj.handlePeerNodePropertiesSet(source, filteredValuesStruct);
                end
            end

            if obj.shouldUpdateCodeGenerationAfterPropertiesSet(source, event)
                updateGeneratedCodePostEvent(obj);
            end
        end

        function handleClientPeerEvent(obj, source, event, ~)
            obj.handlePeerNodePeerEvent(source, event);

            if obj.shouldUpdateCodeGenerationAfterPeerEvent(source, event)
                updateGeneratedCodePostEvent(obj);
            end
        end

        function updateGeneratedCodePostEvent(obj)
            updateGeneratedCode(obj);

            % Once this component has generated its code, bubble up the
            % action to the parent (g1764748)
            if(isvalid(obj) && ~isempty(obj.ParentController))
                obj.ParentController.handleChildCodeGenerated(obj.Model);
            end
        end

        function handlePeerNodePropertiesSet(obj, src, valuesStruct)
            % Handle Property Change events explicitly

            % Update Layout property if a component is moved within a
            % GridLayout
            unhandledValuesStruct = obj.handleLayoutProperty(valuesStruct);

            % Handle Context Menu
            unhandledValuesStruct = obj.handleContextMenuProperties(unhandledValuesStruct);

            % By default delegate to the abstract method which will be
            % implemented by the sub class to handle it
            obj.handleDesignTimePropertiesChanged(src, unhandledValuesStruct);
        end

        function handlePeerNodePeerEvent(obj, src, event)
            % Handler for 'peerEvent' from the Peer Node

            switch event.Data.Name
                case 'childrenReParented'
                    % Client side has re-parented a bunch of child
                    % components, and now sync the matlab side component
                    % models. This event is to batch operate re-parenting
                    % components for performance.
                    obj.handleChildrenReParented(event);
                case 'SizeLocationChanged'
                    % The component has had its size or locatino changed.
                    % Handle the event.
                    obj.handleSizeLocationChanged(src, event);
                otherwise
                    % Delegate to the abstract method which will be implemented by
                    % the subclass
                    obj.handleDesignTimeEvent(src, event);
            end
        end

        function unhandledPropertyValuesStruct = handleLayoutProperty(obj, valuesStruct)
            % Update Layout property of component which is within a
            % GridLayout
            unhandledPropertyValuesStruct = valuesStruct;

            if isfield(valuesStruct, 'LayoutConstraints')
                % Some components, like Tab, do not have Layout
                % property since they are not layoutable
                layoutConstraints = valuesStruct.LayoutConstraints;
                unhandledPropertyValuesStruct = rmfield(valuesStruct, 'LayoutConstraints');

                if isprop(obj.DesignTimeModel, 'Layout')

                    if ~isfield(layoutConstraints, 'Type')
                        if (isa(obj.DesignTimeModel.Parent, 'matlab.ui.container.GridLayout'))
                            % During moving a component between cells in Grid, client-side would set
                            % LayoutConstraints to an empty value first, and
                            % then move the component, and finally set the correct
                            % LayoutConstraints. Server-side should ignore initial
                            % invalid value setting.
                            return;
                        else
                            % Client-side would send an empty LayoutConstraints
                            % value to server-side when moving a component out
                            % of Grid, so in such a scenario set to Absolute
                            % layout
                            % Todo: maybe we could take a look at client-side
                            % to ensure alwasy sending correct value, however
                            % giving that there're a bunch of places on
                            % client-side to prepare LayoutConstraints value,
                            % like in copy/paste, move, duplicate, we could
                            % create this as a tech-debt to resolve in the
                            % future
                            layoutConstraints.Type = 'Absolute';
                        end
                    else
                        % There's a timing issue for undoing Gridify.
                        % 1) Gridify a few components
                        % 2) Delete two of them
                        % 3) Undo deletion and Gridify very quickly
                        % At such a cirucumstance, undo deletion of Component
                        % populateView() would be interuppted by reParent
                        % event, as a result, after undoing Gridify, the
                        % component is already under non-Grid container,
                        % applying Layout property to the component in
                        % pouplateView() would be invalid since it's still
                        % the value of within Grid from undoing deletion.
                        if strcmp(layoutConstraints.Type, 'Absolute') && isa(obj.DesignTimeModel.Parent, 'matlab.ui.container.GridLayout')
                            return;
                        end

                        if strcmp(layoutConstraints.Type, 'Grid') && ~isa(obj.DesignTimeModel.Parent, 'matlab.ui.container.GridLayout')
                            return;
                        end
                    end
                    matlab.ui.control.internal.controller.mixin.LayoutableController.updateLayoutFromClient(...
                        obj.DesignTimeModel, layoutConstraints);
                end
            end
        end

        function handleSizeLocationChanged(obj, src, event)
            % g2468867: ShowHiddenHandles must be off when querying the
            % children of a container
            originalShowHiddenHandlesPropertyValue = get(groot,'ShowHiddenHandles');
            if originalShowHiddenHandlesPropertyValue
                cleanup = onCleanup(@() set(groot, 'ShowHiddenHandles', originalShowHiddenHandlesPropertyValue));
                set(groot, 'ShowHiddenHandles', 'off')
            end

            % Delegate the size and location changed event
            changeSizeLocationProps = rmfield(event.Data, 'Name');
            obj.handlePeerNodePropertiesSet(src, changeSizeLocationProps);

            % If the component has children, allow each child's controller
            % to complete custom logic during the size/location change
            % event processing.  This is important for axes, for example,
            % where the AxesRenderingID changes when the parent is resized.
            if isprop(obj.Model,'Children') && ~isempty(obj.Model.Children)
                children = obj.Model.Children;
                for i = 1:length(children)

                    % If the component doesn't have DesignTimeProperties,
                    % don't call handleParentSizeLocationChanged.  This is
                    % the case when the component is a runtime component
                    % created by a user component.
                    if ~isprop(children(i), 'DesignTimeProperties')
                        continue;
                    end

                    componentController = children(i).getControllerHandle();
                    componentController.handleParentSizeLocationChanged();
                end
            end
        end

        function handleChildrenReParented(obj, event)
            % g2468867: ShowHiddenHandles must be off when querying the
            % children of a container
            originalShowHiddenHandlesPropertyValue = get(groot,'ShowHiddenHandles');
            if originalShowHiddenHandlesPropertyValue
                cleanup = onCleanup(@() set(groot, 'ShowHiddenHandles', originalShowHiddenHandlesPropertyValue));
                set(groot, 'ShowHiddenHandles', 'off')
            end

            status = 'success';
            message = '';

            try
                % Find the uifigure object
                model = obj.DesignTimeModel;
                while(~isa(model, 'matlab.ui.Figure'))
                    model = model.Parent;
                end
                uifigureModel = model;

                % Get all children in the uifigure, including uifigure itself
                componentListMap = appdesigner.internal.application.getDescendantsMapWithCodeName(uifigureModel);

                % Find the new parent component
                newParentComponent = componentListMap.(event.Data.NewParentCodeName);
                newParentController = newParentComponent.getControllerHandle();

                % Find the old parent component
                oldParentComponent = componentListMap.(event.Data.OldParentCodeName);
                oldParentController = oldParentComponent.getControllerHandle();

                % Handle the reparented components
                numberOfChildren = numel(event.Data.ChildrenCodeName);

                for ix = 1:numberOfChildren
                    childCodeName = event.Data.ChildrenCodeName{ix};
                    reparentedComponent = componentListMap.(childCodeName);
                    % Tell the moved component it has a new parent
                    %
                    % This has the side effect of removing the component from the
                    % old parent's Children
                    reparentedComponent.Parent = newParentComponent;

                    % reset this controller's parent controller to the new parent's
                    % controller
                    componentController = reparentedComponent.getControllerHandle();
                    componentController.ParentController = newParentController;

                    % Allow for custom component logic when the component is
                    % reparented.
                    componentController.handleComponentReparented();

                    % Let the old parent controller handle the fact that a peer
                    % node has been removed because of a reparenting
                    reParentedComponentPeerNode = componentController.ViewModel;
                    handlePeerNodeReparentedFrom(oldParentController, reParentedComponentPeerNode);

                    % Let the new parent controller handle the fact that a peer
                    % node has been added because of a reparenting
                    handlePeerNodeReparentedTo(newParentController, reParentedComponentPeerNode);

                    % this PropertiesMap only exist when doing gridify.
                    % once we do gridify, we update the properties directly through server, so that in the client
                    % we don't need to wait for the server response and then update the properties.
                    if isfield(event.Data,'PropertiesMap')
                        componentController.handlePeerNodePropertiesSet(reparentedComponent,event.Data.PropertiesMap.(childCodeName));
                        componentController.updateGeneratedCode();
                    end
                end

                % Re-order children.
                newParentComponent.Children = obj.adjustChildrenOrderBasedOnPeerNodes(newParentComponent);

                % If the children contain axes, it wil be helpful to force a
                % drawnow after reordering the children.  This helps the axes
                % be displayed in the correct z-order.
                drawnow;
            catch me
                status = 'error';
                message = me.message;
            end

            obj.ClientEventSender.sendEventToClient([event.Data.Name 'Result'], {
                'Status', status, ...
                'CallbackId', event.Data.CallbackId, ...
                'Message', message});
        end

        function addDesignTimeProperties(obj)

            % Dynamic design time properties for the model
            % In the loading case, the property is already in the model
            if ~isprop(obj.DesignTimeModel, 'DesignTimeProperties')
                prop = addprop(obj.DesignTimeModel, 'DesignTimeProperties');

                % create a structure of DesignTime properties
                obj.DesignTimeModel.DesignTimeProperties = struct();
                obj.DesignTimeModel.DesignTimeProperties.CodeName = '';
                obj.DesignTimeModel.DesignTimeProperties.GroupId = '';
                obj.DesignTimeModel.DesignTimeProperties.ComponentCode = {};
                obj.DesignTimeModel.DesignTimeProperties.ImageRelativePath = '';
                obj.DesignTimeModel.DesignTimeProperties.DirtyProps = struct();
            end
        end
    end

    methods(Access = 'protected')
        function unhandledPropertyValuesStruct = handleComponentDynamicDesignTimeProperties(obj, valuesStruct, isClientEvent)
            % HANDLECOMPONENTDYNAMICDESIGNTIMEPROPERTIES - Filter app designer specific
            % properties that do not need to be handled by the component
            % controllers.
            % It is assumed that valuesStruct has two fields, 'newValues'
            % and 'oldValues'

            % Initialize struct
            unhandledPropertyValuesStruct = valuesStruct;

            % These are properties that are appdesigner specific, these do
            % not need to be processed by the component controllers. After
            % processing them, remove form valuesStruct
            for index = 1: numel(obj.DesignTimePropertiesToHandle)
                % Verify that property is in the newValues field, and
                % update to the model's dynamic property before trying to
                % remove
                propertyName = obj.DesignTimePropertiesToHandle{index};
                if isfield(valuesStruct, propertyName)
                    if isClientEvent
                        % Update the properties if the properties set happened
                        % from the client
                        obj.DesignTimeModel.DesignTimeProperties.(propertyName) = valuesStruct.(propertyName);
                    end

                    unhandledPropertyValuesStruct = rmfield(unhandledPropertyValuesStruct, propertyName);
                end
            end


            if(isClientEvent)
                if(isfield(valuesStruct, 'ComponentCode'))
                    unhandledPropertyValuesStruct = rmfield(unhandledPropertyValuesStruct, 'ComponentCode');
                end
            end

            % If there are no longer any property updates after filtering,
            % return empty.
            if isempty(fields(unhandledPropertyValuesStruct))
                unhandledPropertyValuesStruct = [];
            end

        end

        function unhandledPropertyValuesStruct = handleContextMenuProperties(obj, valuesStruct)
            % g2468867: ShowHiddenHandles must be off when querying the
            % children of a container
            originalShowHiddenHandlesPropertyValue = get(groot,'ShowHiddenHandles');
            if originalShowHiddenHandlesPropertyValue
                cleanup = onCleanup(@() set(groot, 'ShowHiddenHandles', originalShowHiddenHandlesPropertyValue));
                set(groot, 'ShowHiddenHandles', 'off')
            end

            unhandledPropertyValuesStruct = valuesStruct;


            if(isfield(valuesStruct, 'ContextMenuID'))
                % If the ContextMenuID is non empty, then find the
                % ContextMenu handle and associate it

                id = valuesStruct.ContextMenuID;
                if(isempty(id))
                    % Context Menu has been unassigned
                    obj.Model.ContextMenu = [];
                else

                    % Find the uifigure object
                    model = obj.Model;
                    while(~isa(model, 'matlab.ui.Figure'))
                        model = model.Parent;
                    end
                    figure = model;

                    % Find the relevant context menu
                    contextMenuIdxs = arrayfun(@(x) strcmp(class(x), 'matlab.ui.container.ContextMenu'), figure.Children);
                    contextMenus = figure.Children(contextMenuIdxs);

                    contextMenu = contextMenus(strcmp({contextMenus.ObjectID}, id));
                    assert(~isempty(contextMenu), ['No Context Menus were found for id: ', id]);
                    obj.Model.ContextMenu = contextMenu;
                end

                unhandledPropertyValuesStruct = rmfield(unhandledPropertyValuesStruct, 'ContextMenuID');
            end
        end

        function bool = shouldUpdateCodeGenerationAfterPeerEvent(~, src, event)
            % SHOULDUPDATECODEGENERATIONAFTERPEEREVENT Should generated code
            % be updated on receipt of the given event
            %
            % We don't need to update code generation when the component is in
            % a GridLayout and position/size is changed.  Making this check
            % greatly improves load performance of some apps (g2535107).

            bool = true;

            if strcmp(src.Parent.Type, 'matlab.ui.container.GridLayout')
                ignorableEventsForCodeGen = { ...
                    'positionChangedEvent',  ...
                    'SizeLocationChanged'};

                isIgnorableEventForCodeGen = contains(event.Data.Name, ignorableEventsForCodeGen);

                if isIgnorableEventForCodeGen
                    % Updating generated code not necessary so result is false
                    bool = false;
                end
            end
        end

        function bool = shouldUpdateCodeGenerationAfterPropertiesSet(~, src, event)
            % SHOULDUPDATECODEGENERATIONAFTERPROPERTIESSET Should generated code
            % be update in response to the given property change event
            %
            % See comments in SHOULDUPDATECODEGENERATIONAFTERPEEREVENT

            bool = true;

            if strcmp(src.Parent.Type, 'matlab.ui.container.GridLayout')
                positionProperties = { ...
                    'Size', ...
                    'OuterSize',  ...
                    'Location',  ...
                    'OuterLocation',  ...
                    'Position',  ...
                    'InnerPosition',  ...
                    'OuterPosition'};

                propertiesChanged = fields(event.Data.newValues);
                isPropertiesChangedEventIgnorable = isempty(setdiff(propertiesChanged, positionProperties));

                if isPropertiesChangedEventIgnorable
                    % Updating generated code not necessary so result is false
                    bool = false;
                end
            end
        end
    end
end
