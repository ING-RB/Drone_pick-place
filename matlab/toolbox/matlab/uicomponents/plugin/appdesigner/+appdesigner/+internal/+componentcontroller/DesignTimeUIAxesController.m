classdef DesignTimeUIAxesController < ...
        matlab.ui.control.internal.controller.WebUIAxesController & ...
        matlab.ui.internal.DesignTimeGbtParentingController & ...
        appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController

    % DesignTimeUIAxesController - This class contains design time logic
    % specific to the new UIAxes (R2020b), which inherits from
    % matlab.graphics.axis.Axes.  This class establishes the
    % gateway between the Model and the View.

    % Copyright 2015-2023 The MathWorks, Inc.

    properties (Access = private)
        % Current opacity value of this UIAxes
        currentOpacityValue = 1;
    end

    properties (Constant = true, Access = private)
        % Transparency constants
        PartiallyOpaque = 0.35;
        FullyOpaque = 1;
    end

    methods
        function obj = DesignTimeUIAxesController(model, parentController, proxyView, adapter)
            % CONSTRUCTOR

            % Input verification
            narginchk(3, 4);

            % Construct the run-time controller first
            obj = obj@matlab.ui.control.internal.controller.WebUIAxesController(model, ...
                parentController, ...
                proxyView);

            if nargin < 4
                adapter = [];
            end

            % Construct the client-driven controller
            obj = obj@matlab.ui.internal.DesignTimeGbtParentingController(model, ...
                parentController, ...
                proxyView, ...
                adapter);

            if ~isempty(proxyView)
                obj.ViewModel = proxyView.PeerNode;
            end

            if ~isempty(obj.ViewModel)
                % ViewModel would be empty if it's loading an app
                % g2144458: If the UIAxes is added and deleted really
                % quickly, the configureController call will throw an
                % error because the axes peer node is removed from the
                % hierarchy.  Prevent that error here to be robust to
                % timing issues from PeerModel.
                if isempty(obj.ViewModel.getParent())
                    return;
                end

                % Update the canvas object in the controller
                obj.configureCanvas(parentController);

                % g1347249
                obj.EventHandlingService.setProperty('Position', obj.Model.Position);
            end

            obj.prepareAliasedProperties();
        end

        function handleComponentReparented(obj)
            obj.EventHandlingService.setProperty('AxesRenderingID', obj.Model.getObjectID());
        end

        function handleParentSizeLocationChanged(obj)
            obj.EventHandlingService.setProperty('AxesRenderingID', obj.Model.getObjectID());
        end

        function adjustedProperties = adjustParsedCodegenPropertiesForAppLoad(obj, properties)
            adjustedProperties = obj.getAliasedPropertyNames(properties);
        end

        function adjustedProps = adjustPositionalPropertiesForAppLoad(obj, properties)
            adjustedProps = adjustPositionalPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, properties);
            adjustedProps = [adjustedProps, {'LayoutConstraints', obj.updateLayoutConstraints()}];
        end
    end

    methods (Access=protected)

        function flushProperties(obj, propertiesChanged)
            % FLUSHPROPERTIES - This method is used to flush properties from model to peerNode.
            % There are some dependency properties which will be auto-calculated when some
            % other properties change, and it's hard to find all the dependency properties.

            modelProperties = obj.Model;
            modelPropertiesFields = fields(modelProperties);

            for i = 1: length(propertiesChanged)
                if (~any(strcmp(modelPropertiesFields, propertiesChanged{i})) && isprop(obj.Model,  propertiesChanged{i}))
                    modelPropertiesFields{end + 1} = propertiesChanged{i};
                end
            end

            for k=1:length(modelPropertiesFields)
                field = modelPropertiesFields{k};

                % Get the text aliased properties (e.g. XLabelString) and
                % chop off the 'String' (e.g. XLabel).
                textAliasedProperties = obj.ComponentAdapter.getTextAliasedProperties();
                simpleLabelAliasedPropertyNames = replace({textAliasedProperties([textAliasedProperties.isSimpleLabel]).Name}, 'String', '');

                switch (field)
                    case simpleLabelAliasedPropertyNames
                        obj.EventHandlingService.setProperty([field, 'String'], obj.Model.(field).String);
                    case 'Toolbar'
                        if isprop(obj.Model.Toolbar,'Visible')
                           obj.EventHandlingService.setProperty('ToolbarVisible', obj.Model.Toolbar.Visible);
                        end
                    case 'AD_AliasedVisible'
                        obj.EventHandlingService.setProperty('AD_AliasedVisible', obj.Model.AD_AliasedVisible)
                        obj.updateCurrentOpacityValue();
                        obj.applyOpacityToHandle(obj.Model);
                    case 'AD_ColormapString'
                        obj.prepareColormapStringProperty();
                        obj.EventHandlingService.setProperty('AD_ColormapString', obj.Model.AD_ColormapString);
                        obj.Model.Colormap = feval(obj.Model.AD_ColormapString);
                    otherwise
                        if(obj.EventHandlingService.hasProperty(field))
                            obj.EventHandlingService.setProperty(field, obj.Model.(field));
                        end
                end
            end

            % We should only update AxesRenderingID if it is a property of
            % the component
            if isprop(obj.Model,'AxesRenderingID')
                obj.EventHandlingService.setProperty('AxesRenderingID', obj.Model.AxesRenderingID);
            end
        end

        function updatePositionWithSizeLocationPropertyChanges(obj, changedPropertiesStruct)
            propertyList = fields(changedPropertiesStruct);

            % Update each variable by looking at the changed properties
            for idx = 1:length(propertyList)
                propertyName = propertyList{idx};
                propertyValue = changedPropertiesStruct.(propertyName);

                obj.handlePositionUpdate(propertyName, propertyValue);
            end
        end

        function handleDesignTimePropertiesChanged(obj, peerNode, valuesStruct)

            % g2279972: This if-statement is included to handle the
            % situation where the user has a custom defaultAxesFontUnits.
            % If that is the case, we want to be sure to set the
            % FontUnits on the component before setting FontSize.  Setting the FontUnits
            % first ensures that the FontSize is reasonably readable for a
            % new UIAxes component.
            if isfield(valuesStruct, 'FontSize') && isfield(valuesStruct, 'FontUnits')
                obj.Model.FontUnits = valuesStruct.FontUnits;
            end

            handleDesignTimePropertiesChanged@matlab.ui.internal.DesignTimeGBTComponentController(obj, peerNode, valuesStruct);
            propertiesChanged = fields(valuesStruct);
            obj.flushProperties(propertiesChanged);
        end

        function handleDesignTimePropertyChanged(obj, ~, data, ~)
            % handleDesignTimePropertyChanged( obj, peerNode, data )
            % Controller method which handles property updates in design time. For
            % property updates that are common between run time and design time,
            % this method delegates to the corresponding run time controller.

            % Handle property updates from the client

            updatedPropertyName = data.key;
            updatedPropertyValue = data.newValue;

            textAliasedProperties = obj.ComponentAdapter.getTextAliasedProperties();
            simpleLabelAliasedPropertyNames = {textAliasedProperties([textAliasedProperties.isSimpleLabel]).Name};

            switch ( updatedPropertyName )
                case {'Location', 'OuterLocation', 'Size', 'OuterSize'}
                    obj.handlePositionUpdate(updatedPropertyName, updatedPropertyValue);

                case simpleLabelAliasedPropertyNames
                    obj.Model.(replace(updatedPropertyName,'String', '')).String = updatedPropertyValue;

                case 'SubtitleString'
                    % If the property value is {''}, set the property to ''
                    if iscellstr(updatedPropertyValue) && length(updatedPropertyValue)==1 && isempty(updatedPropertyValue{1}) %#ok<ISCLSTR>
                        obj.Model.Subtitle.String = '';
                    else
                        obj.Model.Subtitle.String = updatedPropertyValue;
                    end

                case 'AD_AliasedVisible'
                    obj.prepareAliasedVisibleProperty();
                    obj.Model.AD_AliasedVisible = matlab.lang.OnOffSwitchState(updatedPropertyValue);
                    obj.updateCurrentOpacityValue();

                case 'AD_ColormapString'
                    obj.prepareColormapStringProperty();
                    obj.Model.AD_ColormapString = updatedPropertyValue;
                    obj.Model.Colormap = feval(updatedPropertyValue);

                case 'ToolbarVisible'

                    % By default, the Axes Toolbar is not saved in an mlapp file or
                    % in a uifigure.  Thus, by default, the Toolbar.Visible setting will not be
                    % saved.  In order for this property to be useful for app
                    % authors, the value of Toolbar.Visible must be saved in the
                    % app if the value is not the default.

                    % In order to save the Toolbar.Visible setting, it is necessary
                    % to define a 'custom toolbar'.  By defining a custom
                    % toolbar, all toolbar settings (including Toolbar.Visible) will be saved
                    % and loaded properly.  The following if-statement does the following:
                    % (1) If the ToolbarVisible property is not the default, it defines the
                    % custom toolbar as a default toolbar with the appropriate Visible
                    % property value; this line is key to proper save and load of Toolbar.Visible.
                    % (2) If the ToolbarVisible property is the default and the custom toolbar has
                    % been created (toolbar children existing = custom toolbar), remove the custom toolbar.
                    % This ensures that unneccessary objects are not saved.
                    if isequal(updatedPropertyValue, matlab.lang.OnOffSwitchState('off'))
                        obj.Model.Toolbar = axtoolbar(obj.Model, 'default', 'Visible', updatedPropertyValue);
                    elseif ~isempty(obj.Model.Toolbar.Children)
                        delete(obj.Model.Toolbar);
                        obj.Model.Toolbar = [];
                        obj.Model.ToolbarMode = 'auto';
                    end

                case {'FontSize', 'XLim', 'YLim', 'ZLim', 'XTick', 'YTick', 'ZTick'}
                    updatedPropertyValue = convertClientNumbertoServerNumber(obj, updatedPropertyValue);
                    obj.Model.(updatedPropertyName) = updatedPropertyValue;

                case {
                        'XLimMode', ...
                        'YLimMode', ...
                        'ZLimMode', ...
                        'XTickMode', ...
                        'YTickMode', ...
                        'ZTickMode', ...
                        'XLimitMethod', ...
                        'YLimitMethod', ...
                        'ZLimitMethod', ...
                        'ColorMode', ...
                        'ColorOrderMode'
                        }
                    obj.Model.(updatedPropertyName) = updatedPropertyValue;

                case  {
                        'GridColor', ...
                        'MinorGridColor', ...
                        'AmbientLightColor'...
                        }
                    % Color - related numerics

                    if(isnumeric(updatedPropertyValue))
                        % numeric
                        updatedPropertyValue = convertClientNumbertoServerNumber(obj, updatedPropertyValue);
                        updatedPropertyValue = round(updatedPropertyValue, 4);
                    end
                    % otherwise... assume it is a string such as 'none' and just let the component do the validation at this point
                    obj.Model.(updatedPropertyName) = updatedPropertyValue;

                case obj.ComponentAdapter.getColorProperties()

                    if(isnumeric(updatedPropertyValue))
                        % numeric
                        updatedPropertyValue = convertClientNumbertoServerNumber(obj, updatedPropertyValue);
                        updatedPropertyValue = round(updatedPropertyValue, 4);
                    end

                    % Do not add opacity to the property value if the value
                    % is 'none'.
                    if ~strcmp(updatedPropertyValue, 'none')
                        obj.Model.(updatedPropertyName) = [updatedPropertyValue, obj.currentOpacityValue];
                    else
                        obj.Model.(updatedPropertyName) = updatedPropertyValue;
                    end

                case {'XTickLabel','YTickLabel','ZTickLabel'}

                    if(~isempty(updatedPropertyValue))
                        % g1353261
                        updatedPropertyValue =  cell(updatedPropertyValue);
                    end
                    obj.Model.(updatedPropertyName) = updatedPropertyValue;


                case 'LineStyleOrder'
                    % Value is a char array representing a cell array
                    % of line style orders
                    %
                    % Ex: '{'- *', '-- s'})
                    %
                    % Needs to be evaled
                    %
                    % g1319014
                    if ischar(updatedPropertyValue) && ...
                            strcmp(updatedPropertyValue(1), '{') && ...
                            strcmp(updatedPropertyValue(end), '}')
                        updatedPropertyValue = eval(updatedPropertyValue);
                    end

                    obj.Model.(updatedPropertyName) = updatedPropertyValue;
                case {'ContextMenuID'}

                    valuesStruct.ContextMenuID = updatedPropertyValue;
                    handleContextMenuProperties(obj, valuesStruct);

                case obj.GenericStringProperties
                    % Update all properties other than FontSmoothing,
                    % as FontSmoothing is read-only
                    if(~strcmp(updatedPropertyName,'FontSmoothing'))
                        obj.Model.(updatedPropertyName) = updatedPropertyValue;
                    end

                case obj.GenericNumericProperties
                    % If not explicitly handled above, then there are
                    % no side effects in changing the numeric property
                    updatedPropertyValue = convertClientNumbertoServerNumber(obj, updatedPropertyValue);
                    obj.Model.(updatedPropertyName) = updatedPropertyValue;

                otherwise
            end
        end

        function handleDesignTimeEvent(obj, src, event)
            % Handle changes in the property editor that needs a
            % server side validation
            eventData = event.Data;

            if(strcmp(eventData.Name, 'PropertyEditorEdited'))

                updatedPropertyName = eventData.PropertyName;
                propertySetData.newValue = eventData.PropertyValue;
                propertySetData.key = updatedPropertyName;
                commandId = event.Data.CommandId;

                try
                    % When the user edits a property using the property
                    % inspector, the property updates arrive here.
                    obj.handleDesignTimePropertyChanged(src, propertySetData, event);

                    firePropertySetSuccess(obj, updatedPropertyName, commandId);
                catch ex
                    firePropertySetFail(obj,  updatedPropertyName, commandId, ex);
                end

                % We have to do this flushing regardless of a success or fail,
                % because some modes can be flipped.
                % g1772850 will resolve this and when that happens, all
                % code further in this if() block can be moved to within
                % the try().

                % Check if 'Foo' changed, then update FooMode
                %
                % Ex: XLim changed, automatically update XLimMode
                if(isprop(obj.Model, [updatedPropertyName 'Mode']))
                    obj.EventHandlingService.setProperty([updatedPropertyName 'Mode'], obj.Model.([updatedPropertyName 'Mode']));
                end

                % Check if property was like 'FooMode', then update Foo
                %
                % Ex: XLimMode changed, so XLim was likely re-calculated
                if(regexp(updatedPropertyName, 'Mode$'))
                    % Trim off 'Mode' and update just 'Foo'
                    correspondingProperty = updatedPropertyName(1 : end - 4);
                    obj.EventHandlingService.setProperty(correspondingProperty, obj.Model.(correspondingProperty));
                end
                obj.flushProperties({updatedPropertyName});
            end

            % Defer to runtime handleEvent
            obj.handleEvent(src, event);
        end

        function viewPvPairs = getPropertiesForView(obj, dirtyPropertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.

            % Base class
            basePairs = getPropertiesForView@matlab.ui.internal.DesignTimeGbtParentingController(obj, dirtyPropertyNames);

            % Get the aliased property names and add the names to
            % viewPvPairs.  We must directly reference the static methods
            % because the adapter is not fully setup during loading.
            allAliasedProperties = appdesigner.internal.componentadapter.uicomponents.adapter.UIAxesAdapter.getAllAliasedProperties();

            % Numeric properties
            props = obj.GenericNumericProperties;

            viewPvPairs = cell(1, length(basePairs) + length(allAliasedProperties)*2 + length(props)*2);

            currentInsertIndex = 1;

            for i = 1:length(basePairs)
                viewPvPairs{currentInsertIndex} = basePairs{i};
                currentInsertIndex = currentInsertIndex + 1;
            end

            isToolbarVisible = any(contains(dirtyPropertyNames, 'ToolbarVisible'));

            for i = 1:length(allAliasedProperties)
                name = allAliasedProperties(i).Name;

                % manual optimization which stops toolbar from being created.
                % If toolbar.visible wasn't considered dirty during app
                % load, just write the a hardcode default value and move on
                % instead of querying the toolbar itself (which normally
                % would create it first)
                if strcmp(name, 'ToolbarVisible') && ~isToolbarVisible
                    viewPvPairs{currentInsertIndex} = name;
                    viewPvPairs{currentInsertIndex + 1} = matlab.lang.OnOffSwitchState.on;
                    currentInsertIndex = currentInsertIndex + 2;
                    continue;
                end

                value = appdesigner.internal.componentadapter.uicomponents.adapter.UIAxesAdapter.getPropertyValue(obj.Model, allAliasedProperties(i).PropertyMapping);
                viewPvPairs{currentInsertIndex} = name;
                viewPvPairs{currentInsertIndex + 1} = value;
                currentInsertIndex = currentInsertIndex + 2;
            end

            for idx = 1:length(props)
                name = props{idx};
                value = obj.Model.(name);
                viewPvPairs{currentInsertIndex} = name;
                viewPvPairs{currentInsertIndex + 1} = value;
                currentInsertIndex = currentInsertIndex + 2;
            end
        end

        function additionalPropertyNamesForView = getAdditionalPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be sent to the view for loading in addition to the
            % ones pushed to the view defined by PropertyManagementService
            %
            % Example:
            % 1) Callback function properties

            % Get the aliased properties that can be serialized.
            allSerializableProperties = appdesigner.internal.componentadapter.uicomponents.adapter.UIAxesAdapter.getAllSerializableAliasedProperties();

            additionalPropertyNamesForView = {allSerializableProperties(:).Name}';

            additionalPropertyNamesForView = [additionalPropertyNamesForView; ...
                getAdditionalPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj);...
                ];
        end

        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view
            %
            % Examples:
            % - Title

            excludedPropertyNames = {'Title'; 'SizeChangedFcn'; 'BackgroundColor'; 'PositionConstraint'};

            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj); ...
                ];

        end

    end

    % Methods that enable Aliased Properties on the UIAxes
    methods (Access=protected)
        function prepareAliasedProperties(obj)
            % PREPAREALIASEDPROPERTIES - Complete any required setup for
            % non-serializable aliased properties (e.g. AD_ColormapString
            % and AD_AliasedVisible).

            obj.prepareAliasedVisibleProperty();

            obj.prepareColormapStringProperty();

            obj.updateCurrentOpacityValue();
        end

        function prepareColormapStringProperty(obj)
            % PREPARECOLORMAPSTRINGPROPERTY - Set up the aliased colormap
            % property if the property does not already exist on the
            % design-time UIAxes.

            % If the AD_ColormapString property doesn't exist, add it as a
            % design-time transient property and set its value
            % appropriately.
            if ~isprop(obj.Model, 'AD_ColormapString')
                dynamicProperty = addprop(obj.Model, 'AD_ColormapString');
                dynamicProperty.Transient = true;
            end
            obj.Model.AD_ColormapString = inspector.internal.getColormapString(obj.Model.Colormap);
        end

        function prepareAliasedVisibleProperty(obj)
            % PREPAREALIASEDVISIBLEPROPERTY - Set up the aliased visible
            % property if the property does not already exist on the
            % design-time UIAxes.

            % If the AliasedVisible property doesn't exist, add it as a
            % design-time transient property and set its value
            % appropriately.
            if ~isprop(obj.Model, 'AD_AliasedVisible')
                dynamicProperty = addprop(obj.Model, 'AD_AliasedVisible');
                dynamicProperty.Transient = true;

                % If Visible is 'off', swap the value to AD_AliasedVisible and
                % turn Visible 'on' at design-time.
                if isequal(obj.Model.Visible, 'off')
                    obj.Model.AD_AliasedVisible = matlab.lang.OnOffSwitchState('off');
                    obj.Model.Visible = 'on';
                else
                    obj.Model.AD_AliasedVisible = matlab.lang.OnOffSwitchState('on');
                end
            end
        end

        function applyOpacityToHandle(obj, handleToUIAxes)
            % APPLYOPACITYTOHANDLE - Given a particualar handle to a UIAxes,
            % apply the current stored opacity value to the handle.

            % Modify the interal (_I) opacity properties so that the Property
            % Values include the currently stored opacity value.
            % Do not add opacity if the property value is'none'
            opacityProperties = strcat(obj.ComponentAdapter.getColorProperties(), '_I');
            for i = 1:length(opacityProperties)
                if ~strcmp(handleToUIAxes.(opacityProperties{i}), 'none')
                    handleToUIAxes.(opacityProperties{i}) = [handleToUIAxes.(opacityProperties{i}), obj.currentOpacityValue];
                end
            end

            % Title.Color is dealt with separately from the above for-loop
            % because it is a nested property value that isn't exposed in
            % the property inspector.
            if ~strcmp(handleToUIAxes.Title.Color_I, 'none')
                handleToUIAxes.Title.Color_I = [handleToUIAxes.Title.Color_I, obj.currentOpacityValue];
            end
        end

        function updateCurrentOpacityValue(obj)
            % UPDATECURRENTOPACITYVALUE  - Change the currently stored opacity value
            % based on the value of the AD_AliasedVisible property.

            if isequal(obj.Model.AD_AliasedVisible, 'off')
                obj.currentOpacityValue = obj.PartiallyOpaque;
            else
                obj.currentOpacityValue = obj.FullyOpaque;
            end
        end
    end

    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController,...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin,...
            ?matlab.ui.internal.DesignTimeGBTComponentController,...
            })
        function children = getAllChildren(~, ~)
            % UIAxes has children, but does not behave as children
            % component, and they are in one single component

            children = [];
        end
    end

    methods(Access = protected)
        function configureController(obj, model, ~)
            if ~isprop(model, 'Controller')
                myController = addprop(model, 'Controller');
                myController.Transient = true;
                model.Controller = obj;

                if (~isprop(model, 'getControllerHandle'))
                    addprop(model, 'getControllerHandle');
                    model.getControllerHandle = @() model.Controller;
                end

            else
                model.Controller = obj;
            end
        end

        function configureCanvas(obj, parentController)
            parentController.Canvas = obj.Model.NodeParent.NodeParent;
        end

        function handleClientEvent(obj, ~, event)
            % When the axesReady event is fired from the client to the
            % server, we want to update the AxesRenderingID.
            % This is critical for proper loading of an axes.

            if nargin ==3 && isfield(event, 'Name') && strcmp(event.Name, 'axesReady')
                changedProperties = {};

                % If AxesRenderingID doesn't exist, create the transient
                % dynamic property.  The AxesRenderingID impacts in-place
                % editing.  When a container has many axes, we need a client-side
                % way to differentiate between the axes.  By
                % differentiating between the axes, we can provide the
                % proper information for in-place editing (e.g. title
                % location).
                if ~isprop(obj.Model, 'AxesRenderingID')
                    dynamicProperty = addprop(obj.Model, 'AxesRenderingID');
                    dynamicProperty.Transient = true;
                    obj.Model.AxesRenderingID = obj.Model.getObjectID();
                    changedProperties = [changedProperties, {'AxesRenderingID'}];
                end

                % R2019b Apps that were saved with an axes in a grid were
                % saved with the incorrect Position of the axes.  This
                % if-statement ensures that the axes is properly located in
                % its parent.
                if isa(obj.Model.Parent, 'matlab.ui.container.GridLayout')
                    obj.handlePositionUpdate('Location', event.Data.Location);
                    obj.handlePositionUpdate('OuterLocation', event.Data.OuterLocation);
                end

                obj.flushProperties(changedProperties)
            end
        end
    end

    methods (Access = private)
        % Methods that delegate to ServerSidePropertyHandlingController
        %
        % They exist to eliminate some boiler plate CommandId extraction
        % code
        function firePropertySetSuccess(obj, propertyName, commandId)
            propertySetSuccess(obj, propertyName, commandId);
        end

        function firePropertySetFail(obj, propertyName, commandId, ex)
            propertySetFail(obj, propertyName, commandId, ex);
        end

        function realNameProperties = getAliasedPropertyNames(~, dirtyPropertiesInCode)
            % GETREALNAMEALIASEDPROPERTIES using the argued property name
            % list which was derived from the component code during app
            % load, transform them into their real names via UIAxesAdapter
            % aliased property list

            aliasList = appdesigner.internal.componentadapter.uicomponents.adapter.UIAxesAdapter.getAllSerializableAliasedProperties();

            realNameProperties = cell(1, length(dirtyPropertiesInCode));

            for i = 1:length(dirtyPropertiesInCode)
                nameInCode = dirtyPropertiesInCode{i};
                aliasStruct = [];

                for j = 1:length(aliasList)
                    if strcmp(aliasList(j).CodeGenEntry, nameInCode)
                        aliasStruct = aliasList(j);
                        break;
                    end
                end

                if ~isempty(aliasStruct)
                    realNameProperties{i} = aliasStruct.Name;
                else
                    realNameProperties{i} = nameInCode;
                end
            end
        end
    end
end