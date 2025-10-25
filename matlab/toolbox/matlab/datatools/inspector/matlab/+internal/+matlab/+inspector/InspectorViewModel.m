classdef InspectorViewModel < internal.matlab.variableeditor.ObjectViewModel

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % View Model for the Property Inspector.  Extends the ObjectViewModel
    % to provide functionality specific to the Inspector

    % Copyright 2015-2022 The MathWorks, Inc.

    properties(Constant)
        % A Group
        GroupType = 'group'

        % A Subgroup within a group
        SubGroupType = 'subgroup'

        % A group of properties, within another group, that share an editor
        EditorGroupType = 'editorgroup'

        % A property
        PropertyType = 'property'
    end

    properties(Constant, Access = protected)
        WIDGET_REG_LOOKUP = "internal.matlab.inspector.peer.PeerInspectorViewModel";
    end

    properties(Access = public)
        getHelpSearchTerm = @(x) class(x);
    end

    properties(Access = protected)
        helpDocTooltipMap;
    end

    methods (Access = public)
        % Constructor
        function this = InspectorViewModel(dataModel, viewID)
            if nargin <= 1
                viewID = '';
            end
            this@internal.matlab.variableeditor.ObjectViewModel(dataModel, viewID);
        end

        function groupData = getRenderedGroupData(this)
            % Retrieve the group information defined for the object being
            % inspected
            %
            % The format of the group will look like this, using Gauge's
            % tick section as an example:
            %
            %	{
            %     "type": "group",
            %     "name": "MATLAB:ui:propertygroups:TickValuesandLabelsGroup",
            %     "displayName": "Tick Values and Labels",
            %     "tooltip": "",
            %     "expanded": true,
            %     "items": [{
            %         "type": "editorgroup",
            %         "items": [{
            %             "type": "property",
            %             "name": "MajorTicks"
            %         }, {
            %             "type": "property",
            %             "name": "MajorTickLabels"
            %         }]
            %     }, {
            %         "type": "subgroup",
            %         "items": [{
            %             "type": "property",
            %             "name": "MinorTicks"
            %         }, {
            %             "type": "property",
            %             "name": "MajorTicksMode"
            %         }, {
            %             "type": "property",
            %             "name": "MajorTickLabelsMode"
            %         }, {
            %             "type": "property",
            %             "name": "MinorTicksMode"
            %         }]
            %     }]
            % }
            %
            % Note:
            %
            % - Every construct has a 'type'
            % - Every construct with sub objects stores them in 'items'
            %
            % When creating this data structure, what is assembled looks like
            % this in MATLAB:
            %
            %
            %	struct
            %     type =  "group",
            %     name =  "My Group"
            %     ...
            %     items: cell array of structs having fields:
            %
            %         type  = 'editorgroup' | 'subgroup | 'group' | 'property'
            %         items = cell array of structs for sub components
            %         ...
            %         other type specific fields
            %         ...
            %
            % A cell array of structs is used, rather than a regular array
            % of structs, so that each type can have fieldnames unique to its
            % type.  An array of structs forces homogeneous fieldnames.

            rawData = this.getData();
            groups = rawData.getGroups();
            if ~isempty(groups)
                for groupRow = 1:length(groups)
                    % For each group, create the data which includes the
                    % groupID, title, description, and the properties included
                    % in the group
                    group = groups(groupRow);

                    % Handle top level properties
                    groupItemsData = createGroupItemsData(this, group.PropertyList);

                    groupData(groupRow) = struct( ...
                        'type', 'group', ...
                        'name', group.GroupID, ...
                        'displayName', internal.matlab.inspector.Utils.getPossibleMessageCatalogString(group.Title), ...
                        'tooltip', internal.matlab.inspector.Utils.getPossibleMessageCatalogString(group.Description), ...
                        'expanded', group.Expanded, ...
                        ... Note: the group data needs to be wrapped in a cell array, otherwise it results in incorrect hierarchy
                        'items', {groupItemsData} ...
                        );
                end
            else
                groupData = [];
            end
        end

        function groupItems = createGroupItemsData(this, allGroupProps)
            % For the given group object, creates all 'items' under the
            % group

            groupItems = {};

            for idx = 1:length(allGroupProps)
                property = allGroupProps{idx};

                if(isa(property, 'internal.matlab.inspector.InspectorEditorGroup'))
                    %
                    % editor group
                    %
                    % Ex: Group of {'Ticks', 'Labels'}
                    editorGroupItems = cellfun(@(x) {this.createPropertyData(x)}, property.PropertyList);

                    thisProperty = struct;
                    thisProperty.type = this.EditorGroupType;
                    thisProperty.items = editorGroupItems;
                elseif(isa(property, 'internal.matlab.inspector.InspectorSubGroup'))
                    % Creates a sub group by iterating over all given properties

                    subGroupItems = this.createGroupItemsData(property.PropertyList);

                    thisProperty = struct;
                    thisProperty.type = this.SubGroupType;
                    thisProperty.items = subGroupItems;

                else
                    % just a regular property
                    thisProperty = this.createPropertyData(property);
                end
                groupItems = [groupItems {thisProperty}]; %#ok<*AGROW>
            end
        end

        % Override the getFieldData method to call the getPropertyValue
        % method on the InspectorProxyMixin class.
        function fieldData = getFieldData(~, data, fn)
            if nargin == 2
                % Gaurd against the field name not being specified
                fieldData = [];
            else
                fieldData = data.getPropertyValue(fn);
            end
        end
    end

    methods(Access = protected)
        function [dataType,isEnumeration] = getInspectedClassType(this, propName)
            % Called to get the class type for the property name, and if
            % it is an enumeration or categorical.
            rawData = this.DataModel.getData();
            dataType = 'any';
            isEnumeration = false;

            if isKey(rawData.PropertyTypeMap, propName)
                % The type may have been defined with the property, for
                % example propName@logical
                propType = rawData.PropertyTypeMap(propName);

                % The type will either be a meta.type object, or it could
                % be just a class name, depending on if the metaclass
                % object had data for the property or not
                if isa(propType, 'meta.type') || isa(propType, 'meta.class')
                    if ~strcmp(propType.Name, 'any')
                        % Use the type as defined
                        dataType = propType.Name;
                    end

                    rawPropVal = rawData.(propName);
                    if internal.matlab.inspector.Utils.isEnumerationFrompropType(propType)
                        % If its a meta.EnumeratedType, then its an
                        % enumeration
                        isEnumeration = true;
                    elseif iscategorical(rawPropVal)
                        % The property may not be typed, but if the current
                        % value is categorical, then treat it as a
                        % categorical variable
                        isEnumeration = true;
                    elseif isstring(rawPropVal)
                        isEnumeration = false;
                    elseif isobject(rawPropVal)
                        % But it can also be a user-defined MCOS
                        % enumeration, in which case the call to
                        % enumeration() will return the valid values
                        [~, values] = enumeration(rawPropVal);
                        isEnumeration = ~isempty(values);
                    end
                else
                    dataType = propType;
                end
            end

            % Treat categoricals as enumerations as well
            isEnumeration = isEnumeration || ismember(dataType, ...
                {'categorical', 'nominal', 'ordinal'});

            if isEnumeration
                prop = findprop(rawData, propName);
                if ~isempty(prop)
                    % If the property doesn't have setAccess, set it to not
                    % be an enumeration, so the client doesn't show a drop
                    % down menu for this property
                    isEnumeration = strcmp(prop.SetAccess, 'public');
                end
            end
        end

        function replacementValue = getInspectedEmptyValueReplacement(this, propName)
            % Called to return the replacement value for empties when
            % setting a new value
            [dataType,isEnumeration] = this.getInspectedClassType(propName);

            if internal.matlab.datatoolsservices.FormatDataUtils.isNumericType(dataType)
                % For numerics, its 0
                replacementValue = '0';
            elseif isEnumeration
                % Return the original value for an enumeration
                replacementValue = this.DataModel.getData.getPropertyValue(propName);
            else
                switch dataType
                    case 'logical'
                        replacementValue = '0';
                    otherwise
                        % Default to empty for other cases
                        replacementValue = '[]';
                end
            end
        end

        function property = createPropertyData(this, propertyName)
            % Creates specification for a property
            property = struct;
            property.type = this.PropertyType;
            property.name = propertyName;
        end

        function [helpTooltipsMap, searchTerm] = initHelpTooltips(this, rawData)
            % keep a  persistent tooltipContainerMap so that if user close
            % that inspector and open again the same inspector, the
            % helpTooltipsMap will be there for using, no need to fetch the
            % data one more time, which will save the time

            mlock; % Keep persistent variables until MATLAB exits
            persistent tooltipCacheMap;
            if isempty(tooltipCacheMap)
                tooltipCacheMap = containers.Map;
            end

            helpTooltipsMap = containers.Map;
            originalObj = rawData.OriginalObjects;
            if ~isa(originalObj, "internal.matlab.inspector.EmptyObject")
                try
                    if ~isempty(rawData.HelpSearchTerm)
                        % Use the HelpSearchTerm set on the ProxyObject if possible
                        searchTerm = rawData.HelpSearchTerm;
                    else
                        % Try to get the help search term
                        searchTerm = this.getHelpSearchTerm(originalObj);
                    end
                catch
                    % But if this fails, use the classname for lookup (which is the default for help lookup)
                    searchTerm = class(originalObj);
                end
    
                try
    
                    % if the CacheMap has the tooltip map for the search term,
                    % then just use this. if not, fetch the data and add this
                    % into CachMap;
                    if tooltipCacheMap.isKey(searchTerm)
                        helpTooltipsMap = tooltipCacheMap(searchTerm);
                    else
                        tooltipProp = internal.matlab.inspector.Utils.getObjectProperties(searchTerm);

                        for index = 1:size(tooltipProp, 2)
                            propertyName = tooltipProp(index).property;
                            tooltip = strcat(tooltipProp(index).description, '||', tooltipProp(index).inputs);
                            helpTooltipsMap(propertyName) = tooltip;
                        end
    
                        tooltipCacheMap(searchTerm) = helpTooltipsMap;
                    end
                catch
                end
            end
        end

        function isValid = validateInspectorInput(this, propName, value, ...
                currentValue)
            % Called to see if the value is valid for the property propName
            [dataType,isEnumeration] = this.getInspectedClassType(propName);
            isValid = true;

            if internal.matlab.datatoolsservices.FormatDataUtils.isNumericType(dataType)
                % If its numeric, just verify the new value is also numeric
                isValid = isnumeric(value);
            elseif isEnumeration
                % Check enumeration values
                propType = this.DataModel.getData.PropertyTypeMap(propName);
                if isa(propType, 'meta.EnumeratedType') && ischar(value)
                    % If the possible values is set, make sure that the new
                    % value is one of them
                    isValid = isempty(propType.PossibleValues) || ...
                        ismember(strrep(value, '''', ''), ...
                        propType.PossibleValues);
                elseif isobject(currentValue)
                    % Otherwise, if its currently an object, check to see
                    % if its a user-defined enumeration.  If it is,
                    % enumeration() will return the valid values.
                    [~, enumValues] = enumeration(currentValue);
                    isValid = isempty(enumValues) || ...
                        ismember(strrep(value, '''', ''), enumValues);
                end
            else
                % Default to valid for other cases
                isValid = true;
            end
        end

        function objectData = getObjectDataForProperty(this, propertyName, ...
                dataValue, varValue, classType, isCatOrEnum, metaData, workspaceStr, requiresFullPrecision)

            % Get the display value for the object
            editValue = varValue;
            isScalarDataValue = isscalar(dataValue);

            % If we have a numeric value, that isn't a value summary
            % create the full-precision representation of it.
            if isnumeric(dataValue)
                if ~metaData || requiresFullPrecision
                    if isempty(dataValue)
                        editValue = '[]';
                    else
                        [editValue, scaleFactor] = matlab.internal.display.numericDisplay(dataValue, 'Format', 'long');
                        %g1809884, if scaleFactor is not one, we use the old way to
                        %get the editValue
                        if ~isequal(scaleFactor, 1)
                            editValue = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(dataValue);
                        elseif length(editValue) > 1
                            % Inspector expects array brackets for non-scalar
                            % values
                            if size(editValue, 2) == 1
                                % This is one column, rejoin with semi-colons only
                                editValue = char("[" + join(editValue, ";") + "]");
                            else
                                % This is either a row vector or an NxM matrix
                                editValue = char("[" + join(join(editValue, ","), ";") + "]");
                            end
                        end
                    end
                    if isScalarDataValue
                        if contains(editValue, '.')
                            % Strip off excess 0's for display
                            editValue = strip(editValue, 'right', '0');
                            if iscell(varValue)
                                % Use first item since we know this is a scalar
                                % value
                                varValue = strip(varValue{1}, 'right', '0');
                            elseif ischar(varValue) || isstring(varValue)
                                varValue = strip(varValue, 'right', '0');
                            end
                        end
                        if (isstring(varValue) || ischar(varValue)) && strlength(editValue) > strlength(varValue)
                            varValue = [varValue '...'];
                        end
                    else
                        % Strip off excess 0's from the array for display
                        editValue = internal.matlab.inspector.Utils.getArrayWithZerosStripped(editValue);
                        if ischar(editValue) && startsWith(editValue, '[')
                            editValue = editValue(2:end-1);
                        end
                        varValue = internal.matlab.inspector.Utils.getArrayWithZerosStripped(varValue);
                        if ischar(varValue) && startsWith(varValue, '[')
                            varValue = varValue(2:end-1);
                        elseif iscellstr(varValue)
                            for n = 1:length(varValue)
                                if startsWith(varValue{n}, '[')
                                    varValue{n} = varValue{n}(2:end-1);
                                end
                            end
                        end
                    end
                end
            elseif strcmp(classType, 'logical') && isScalarDataValue && ~requiresFullPrecision
                % requiresFullPrecision means there is no editor converter
                % for this property. This is true for the value property
                % in buttons and false for the columneditable property in
                % uitable

                % For scalar logicals, use '1' and '0'
                if strcmp(varValue, 'true') || strcmp(varValue, '1')
                    varValue = '1';
                else
                    varValue = '0';
                end
                editValue = varValue;
            elseif (strcmp(classType, 'cell') && ~ischar(varValue))
                editValue = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(dataValue);

                if length(varValue) > 1
                    % Check if varValue is of type cell and format (lineStyleOrder sends in line/markers as cell)
                    varValue = strjoin(varValue, ', ');
                else
                    varValue = varValue{1};
                end
            elseif isCatOrEnum || iscategorical(dataValue)
                % For categoricals and enumerations, if varValue isn't
                % already a char, then typically this means it isn't scalar
                % and varValue is the actual value.  Use FormatDataUtils to
                % format this (to something like '4x1 categorical').
                if ~ischar(varValue)
                    [valueSummary, ~, metaData] = this.formatSingleDataForMixedView(dataValue);
                    varValue = char(valueSummary);
                    if isScalarDataValue
                        editValue = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(dataValue);
                    else
                        editValue = varValue;
                    end
                end
            elseif strcmp(classType, 'datetime') && ...
                    ~contains(editValue, " datetime")
                metaData = false;
            elseif strcmp(classType, 'duration') && ...
                    ~contains(editValue, " duration")
                metaData = false;
            elseif any(strcmp(classType, {'function_handle', 'char'}))
                metaData = false;
            elseif isnumeric(dataValue) && ~isScalarDataValue
                editValue = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(dataValue);
            end

            % Only set the variable name if it is something valid
            if ~isempty(this.DataModel.VariableName) && ...
                    ~strcmp(this.DataModel.VariableName, internal.matlab.inspector.Inspector.INTERNAL_REF_NAME) && ...
                    strlength(this.DataModel.VariableName) > 0 && ...
                    ~isempty(this.DataModel.VariableWorkspace)
                variableName = this.DataModel.VariableName;
                variableWorkspace = this.DataModel.VariableWorkspace;
            else
                variableName = "";
                variableWorkspace = "";
            end

            objectData = struct('value', varValue, ...
                'editValue', editValue, ...
                'editorValue', char(this.DataModel.Name + "." + propertyName), ...
                'isMetaData', metaData, ...
                'variableName', variableName, ...
                'variableWorkspace', variableWorkspace ...
                );
        end

        function widgets = getCommonWidgetRegistryEntries(this)
            % Get an instance of the WidgetRegistry, and cache some of the
            % commonly used widget sets

            import internal.matlab.datatoolsservices.WidgetRegistry;

            persistent objectWidgets;
            persistent charWidgets;
            persistent categoricalWidgets;
            persistent openvarWidgets;
            persistent spinnerWidgets;
            persistent labelWidgets;

            if isempty(objectWidgets)
                widgetRegistry = WidgetRegistry.getInstance;
                objectWidgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, 'object');
                charWidgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, 'char');
                categoricalWidgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, 'categorical');
                openvarWidgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, '_objectInBase');
                spinnerWidgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, '_numberWithValidation');
                labelWidgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, '_readOnlyLabel');
            end

            widgets = struct;
            widgets.objects = objectWidgets;
            widgets.chars = charWidgets;
            widgets.categoricals = categoricalWidgets;
            widgets.openvars = openvarWidgets;
            widgets.spinners = spinnerWidgets;
            widgets.labels = labelWidgets;
        end

        function workspaceStr = getWorkspaceStr(this)
            if ischar(this.DataModel.Workspace)
                workspaceStr = this.DataModel.Workspace;
            else
                workspaceStr = ['internal.matlab.inspector.peer.InspectorFactory.createInspector(''' ...
                    this.DataModel.Workspace.Application ''','''...
                    this.DataModel.Workspace.Channel ''')'];
            end
        end

        function [origObjSetAccessNames, origObjectPropNames] = getSetAccessPropsForRendering(this)
            import internal.matlab.inspector.InspectorViewModel;

            % Retreive a list of the SetAccess of each of the properties,
            % and the original object's property names  outside of the loop.
            if isempty(this.DataModel.getData.OrigObjSetAccessNames)
                % Retrieve the lists and save them on the Proxy Object
                o = this.DataModel.getData.getOriginalObjectAtIndex(1);

                [origObjSetAccessNames, origObjectPropNames] = InspectorViewModel.getPublicSetAccessProps(o);
                this.DataModel.getData.OrigObjSetAccessNames = origObjSetAccessNames;
                this.DataModel.getData.OrigObjectPropNames = origObjectPropNames;
            else
                % Use the cached values from the Proxy Object
                origObjSetAccessNames = this.DataModel.getData.OrigObjSetAccessNames;
                origObjectPropNames = this.DataModel.getData.OrigObjectPropNames;
            end
        end

        function [propValue, metaData] = getPropValueForRendering(this, rawDataVal)
            metaData = false;
            if ischar(rawDataVal)
                propValue = char("'" + rawDataVal + "'");
            elseif isstring(rawDataVal) && isscalar(rawDataVal) && ~ismissing(rawDataVal)
                propValue = char("""" + rawDataVal + """");
            elseif isobject(rawDataVal) && ~istall(rawDataVal)
                cls = class(rawDataVal);
                if contains(cls, ".")
                    % Only display class names for full matlab classes,
                    % For example: 'Text' instead of
                    % 'matlab.graphics.primitive.Text'
                    cls = reverse(extractBefore(reverse(cls), "."));
                end
                propValue = strtrim([num2str(size(rawDataVal,1)) this.TIMES_SYMBOL num2str(size(rawDataVal,2)) ...
                    ' ' cls]);
            elseif isnumeric(rawDataVal) && isempty(rawDataVal)
                propValue = '[ ]';
            else
                [rd, ~, metaData] = this.formatSingleDataForMixedView(rawDataVal);
                propValue =  rd{1};
            end
        end

        function [propType, isCatOrEnum, dataType] = getPropAndDataType(~, prop, classType, rawData, rawDataVal)
            % The type may have been defined with the property, for
            % example propName@logical
            if isKey(rawData.PropertyTypeMap, prop.Name)
                propType = rawData.PropertyTypeMap(prop.Name);
            else
                propType = class(rawDataVal);
            end

            [isCatOrEnum, dataType] = ...
                internal.matlab.editorconverters.ComboBoxEditor.isCategoricalOrEnum(...
                classType, propType, rawDataVal);

            if (ischar(propType) || isstring(propType)) &&...
                    propType == "internal.matlab.editorconverters.datatype.StringEnumeration"
                dataType = propType;
            end
        end

        function validation = getValidationStruct(~, prop, rawData)
            if isKey(rawData.PropertyValidationMap, prop.Name)
                validation = rawData.PropertyValidationMap(prop.Name);
            else
                validation = internal.matlab.inspector.Utils.getPropValidationStruct([]);
            end
        end

        function [widgets, isOpenvar] = getWidgetForProperty(this, dataType, classType, ...
                dataValue, rawDataVal, isCatOrEnum, validation, supportsPopupWindowEditor)
            import internal.matlab.inspector.InspectorViewModel;
            import internal.matlab.datatoolsservices.WidgetRegistry;

            isOpenvar = false;
            commonWidgets = this.getCommonWidgetRegistryEntries();
            widgetRegistry = WidgetRegistry.getInstance;

            [widgets, ~, matchedVariableClass] = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, dataType);
            if ~isequal(matchedVariableClass, dataType) && isCatOrEnum
                % If the variable class we matched against is different than
                % the actual class (so we matched a superclass), but the
                % value is a categorical or enum, we should show the
                % property as a dropdown menu.  (This can happen with
                % enumerations which extend other types like logicals or
                % doubles -- these should be edited as enumerations)
                widgets = commonWidgets.categoricals;
            elseif widgetRegistry.isUnknownView(widgets.Editor)
                % If there isn't one, try to get the editor based on
                % the property's current data type
                if isCatOrEnum
                    widgets = commonWidgets.categoricals;
                else
                    [widgets, ~, matchedClass] = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, classType);
                    if matchedClass == "categorical" && ~isscalar(dataValue)
                        % Non-scalar categorical values should show as 1xN
                        % categorical, and not as a dropdown
                        widgets = commonWidgets.objects;
                    elseif isempty(widgets.CellRenderer) && isobject(dataValue) && ...
                            isequal(widgets, commonWidgets.objects) && ...
                            InspectorViewModel.shouldShowOpenvarEditor(...
                            matchedVariableClass, rawDataVal)
                        widgets = commonWidgets.openvars;
                        isOpenvar = true;
                    elseif isempty(widgets.CellRenderer)
                        widgets = commonWidgets.chars;
                    end
                end
            elseif (matchedVariableClass == "datetime" || matchedVariableClass == "categorical") && ~isscalar(dataValue)
                % g1806245, Non-scalar datetime/categorical values should show as 1xN
                % datetime/categorical, and not as a dropdown
                widgets = commonWidgets.objects;
            elseif ~isempty(validation.IsScalar) && validation.IsScalar && (~isinf(validation.MinValue) || ~isinf(validation.MaxValue))
                widgets = commonWidgets.spinners;
            elseif isequal(widgets, commonWidgets.objects) && ...
                    InspectorViewModel.shouldShowOpenvarEditor(...
                    matchedVariableClass, rawDataVal)
                % Show the 'openvar' editor only if we were going to show the
                % default renderer/editor (if the widgets being shown are the
                % commonWidgets.objects)
                widgets = commonWidgets.openvars;
                isOpenvar = true;
            end

           if isequal(widgets.InPlaceEditor, commonWidgets.openvars.InPlaceEditor) && ~supportsPopupWindowEditor
               % If we selected the openvar editor, but it isn't supported, then
               % use the objects widgets.
               widgets = commonWidgets.objects;
            end
        end

        function [propertySheetData, objectValueData] = renderDataStruct(this, propList, varargin)
            % Creates the rendered data specific to the Inspector

            import internal.matlab.inspector.InspectorViewModel;
            if nargin == 3
                cacheData = varargin{1};
            else
                cacheData = true;
            end

            rawData = this.getData();

            if ~isempty(propList)
                fieldNames = propList';
            else
                fieldNames = string(fieldnames(rawData));
                propList = string(fieldNames);
            end

            this.helpDocTooltipMap = initHelpTooltips(this, rawData);
            workspaceStr = this.getWorkspaceStr();

            isProxy = isa(this.DataModel.getData, 'internal.matlab.inspector.InspectorProxyMixin');
            if isProxy
                [origObjSetAccessNames, origObjectPropNames] = this.getSetAccessPropsForRendering();
            end
            converterMap = containers.Map;

            % Pass through the InspectorID to the converters if it is available
            if isprop(this, "MsgSvcChannel")
                inspectorID = this.MsgSvcChannel;
            else
                inspectorID = "";
            end

            % For each of the rows of rendered data, create the object data for
            % each row's data.  Use a while loop because the number of
            % properties may grow.
            row = 0;
            while row < size(fieldNames, 1)
                row = row + 1;
                propName = fieldNames{row,1};

                if ~any(propName == propList)
                    continue;
                end

                if isProxy && isKey(this.DataModel.getData.ObjRenderedData, propName)
                    % The rendered data for this property name is already
                    % cached, just reuse it.
                    try
                        propertySheetData(row,1) = this.DataModel.getData.ObjRenderedData(propName);
                        objectValueData(row,1) = this.DataModel.getData.ObjectViewMap(propName);
                        continue;
                    catch ex
                        if ex.identifier == "MATLAB:heterogeneousStrucAssignment"
                            row = 0;
                            remove(this.DataModel.getData.ObjRenderedData, keys(this.DataModel.getData.ObjRenderedData));
                            remove(this.DataModel.getData.ObjectViewMap, keys(this.DataModel.getData.ObjectViewMap));
                            continue;
                        else
                            rethrow(ex);
                        end
                    end
                end

                try
                    rawDataVal = rawData.(propName);
                catch
                    % If we can't access the value, just continue.  This can
                    % happen in the case of dynamic properties, because the
                    % property attributes need to be set after the property is
                    % added.
                    continue;
                end

                [propValue, metaData] = this.getPropValueForRendering(rawDataVal);
                dataValue = rawDataVal;
                classType = this.getClassString(rawDataVal, false, true);

                % Find the metaclass property data, so it can be used for
                % the description, detailed description, etc...
                prop = findprop(rawData, propName);
                [propType, isCatOrEnum, dataType] = this.getPropAndDataType(prop, classType, rawData, rawDataVal);
                validation = this.getValidationStruct(prop, rawData);

                richEditorProps = [];

                % Setup the widgets to be used.  First, check to see if
                % there is an editor in place for this data type
                [widgets, isOpenvar] = this.getWidgetForProperty(dataType, classType, ...
                    dataValue, rawDataVal, isCatOrEnum, validation, rawData.SupportsPopupWindowEditor);

                converter = [];
                if ~isempty(widgets.EditorConverter)
                    % If a converter is set, use it to convert to the
                    % client value
                    if isKey(converterMap, widgets.EditorConverter)
                        converter = converterMap(widgets.EditorConverter);
                    else
                        converter = eval(widgets.EditorConverter);
                        converter.InspectorID = inspectorID;
                        converterMap(widgets.EditorConverter) = converter;
                    end
                    converter.setValidation(validation);
                    converter.setServerValue(dataValue, propType, propName);
                    propValue = converter.getClientValue();

                    % Its possible the converter changes the class type, so
                    % get the value again
                    classType = this.getClassString(propValue, false, true);

                    % In Place Editor
                    richEditorProps = converter.getEditorState;
                    if isfield(richEditorProps, 'richEditorDependencies') %&& length(fieldNames) > 1
                        % Make sure dependent properties are included in the list
                        for dep = 1:length(richEditorProps.richEditorDependencies)
                            dependentProp = string(richEditorProps.richEditorDependencies{dep});
                            if ~any(fieldNames == dependentProp)
                                if isprop(rawData, dependentProp)
                                    % Add tihs property to the end of the list, and increment everything
                                    fieldNames(end+1) = dependentProp;
                                    propList(end+1) = dependentProp;
                                elseif isprop(rawData.OriginalObjects(1), dependentProp)
                                    richEditorProps.(dependentProp) = ...
                                        internal.matlab.inspector.PropertyAccessor.getValue(...
                                        rawData.OriginalObjects(1), dependentProp);
                                end
                            end
                        end
                    end
                elseif isOpenvar
                    openvarUsingBaseVE = this.getProperty('openvarWithBaseVE');
                    if isempty(openvarUsingBaseVE)
                        openvarUsingBaseVE = false;
                    end
                    richEditorProps = struct('openvarUsingBaseVE', openvarUsingBaseVE);
                end

                % Add in flag if this is a property requiring hover over
                % events
                if any(strcmp(propName, rawData.PropsForHoverOver))
                    richEditorProps.HoverOverEvent = true;
                end

                if any(strcmp(propName, rawData.PropsForValueChanging)) 
                    richEditorProps.ValueChangingEvent = true;
                end

                cellEditor = widgets.Editor;
                if ~isequal(prop.SetAccess, 'public')
                    % If the property value doesn't have setAccess =
                    % public, it should be displayed as read-only on the
                    % client.  (This is done by having no editor for the
                    % cell).
                    cellInPlaceEditor = '';
                else
                    cellInPlaceEditor = widgets.InPlaceEditor;
                end

                % Assume that we need the full precision of numeric values if
                % there is an EditorConverter.  The Rich Editor either requires
                % the full precision (like ticks) or its EditorConverter would
                % have already resolved the value to something ilke a text summary.
                requiresFullPrecision = ~isempty(widgets.EditorConverter);

                % Create the rendered data for the row
                rowData = this.getObjectDataForProperty(...
                    propName, dataValue, propValue, classType, isCatOrEnum, metaData, workspaceStr, requiresFullPrecision);
                objectValueData(row,1) = rowData;

                hasSetAccess = true;
                if ~isempty(prop)
                    hasSetAccess = strcmp(prop.SetAccess, 'public');
                    if isProxy && hasSetAccess && any(origObjectPropNames == prop.Name)
                        % this is a proxy class, check the original
                        % object's SetAccess because the proxy may not have
                        % it set properly.  Use the original object's
                        % SetAccess as truth.
                        hasSetAccess = any(origObjSetAccessNames == prop.Name);
                    end

                    if ~hasSetAccess
                        if this.DataModel.getData.UseLabelForReadOnly
                            commonWidgets = this.getCommonWidgetRegistryEntries();
                            widgets = commonWidgets.labels;
                        elseif InspectorViewModel.requiresReadOnlyText(isCatOrEnum, dataType, rawData)
                            % Some ReadOnly properties should be shown as
                            % text
                            commonWidgets = this.getCommonWidgetRegistryEntries();
                            widgets = commonWidgets.chars;
                        end
                    end
                end

                % If the help doc was available for this class/property, use it
                % as the tooltip.  If not, check if the proxy view provided one.
                if isKey(this.helpDocTooltipMap, propName)
                    tooltipValue = this.helpDocTooltipMap(propName);
                else
                    tooltipValue = this.DataModel.getData.getPropertyTooltip(propName);
                end

                % Properties are editable if they have setAccess, the cell
                % editor is not empty, and they are not tall.  (There is no way
                % to provide some features for editing talls, like undo/redo).
                isEditable = hasSetAccess && ~isempty(cellInPlaceEditor) ...
                    && ~istall(rawDataVal);

                %change the isEditable if it is specified in EditorState
                if ~isempty(converter)
                    inPlaceEditorPropsWithEditable = converter.getEditorState;
                    if isfield(inPlaceEditorPropsWithEditable, 'editable')
                        isEditable = inPlaceEditorPropsWithEditable.editable;
                    end
                end

                displayName = this.DataModel.getData.getPropertyDisplayName(propName);

                % Create the property sheet data for the property, which
                % includes the display name, tooltip, and renderers.
                % (Specifying dataType as 'char' just effects the
                % justification - so the Property Inspector shows
                % everything left justified)
                % any changes in order may effect the InspectorFactory's functionality for updating the help information
                propertySheetData(row,1) = ...
                    struct('name', propName, ...
                    'displayName', displayName, ...
                    'tooltip', tooltipValue, ...
                    'dataType', 'char', ...
                    'className', dataType, ...
                    'renderer', widgets.CellRenderer, ...
                    'inPlaceEditor', cellInPlaceEditor, ...
                    'editor', cellEditor, ...
                    'editable', isEditable, ...
                    'richEditorProperties', richEditorProps ...
                    );

                if cacheData
                    % Cache values on the Proxy Object
                    this.DataModel.getData.ObjRenderedData(propName) = propertySheetData(row,1);
                    this.DataModel.getData.ObjectViewMap(propName) = objectValueData(row,1);
                end
            end

            if row == 0
                propertySheetData = [];
                objectValueData = [];
            end
        end

        function [rowData, editorProps] = getRowDataForProperty(this, propertyName, varargin)
            if nargin == 3
                cacheData = varargin{1};
            else
                cacheData = true;
            end
            rowData = [];
            editorProps = [];
            fieldNames = fieldnames(this.DataModel.getData);

            row = find(strcmp(fieldNames, propertyName));

            % Make sure the row for the property is found
            if ~isempty(row)
                % This function is called to get the _current_ value for the
                % property, so we need to first clear out any cached values that
                % may exist
                if cacheData
                    if isKey(this.DataModel.getData.ObjRenderedData, propertyName)
                        remove(this.DataModel.getData.ObjRenderedData, propertyName);
                    end
                    origObjProp = [];
                    if isKey(this.DataModel.getData.ObjectViewMap, propertyName)
                        origObjProp = this.DataModel.getData.ObjectViewMap(propertyName);
                        remove(this.DataModel.getData.ObjectViewMap, propertyName);
                    end
                end

                % Get the rendered data for just a single property.
                % propertySheetData and objectValueData are single-cell cell
                % arrays
                [propertySheetData, objectValueData] = this.renderDataStruct(...
                    string(propertyName), cacheData);

                if cacheData
                    newObjProp = this.DataModel.getData.ObjectViewMap(propertyName);
                    if isstruct(origObjProp) && isfield(origObjProp, "variableName")
                        % The cached struct contained the variableName and workspace, so
                        % we need to make sure the new struct has the same
                        newObjProp.variableName = origObjProp.variableName;
                        newObjProp.variableWorkspace = origObjProp.variableWorkspace;
                        this.DataModel.getData.ObjectViewMap(propertyName) = newObjProp;
                    end
                end
                editorProps = propertySheetData.richEditorProperties;
                rowData = objectValueData;
            end
        end
    end

    methods(Static = true)
        function requiresROText = requiresReadOnlyText(isCatOrEnum, dataType, proxyObject)
            arguments
                isCatOrEnum (1,1) logical
                dataType (1,1) string
                proxyObject = [];
            end

            % If the property doesn't have setAccess, set it to not be an
            % enumeration, so the client doesn't show a drop down menu for this
            % property
            if isa(proxyObject, "internal.matlab.inspector.ProxyAddPropMixin")
                requiresROText = false;
            else
                requiresROText = isCatOrEnum || ...
                    dataType == "internal.matlab.editorconverters.datatype.StringEnumeration";
            end
        end

        function [origObjSetAccessNames, origObjectPropNames] = getPublicSetAccessProps(obj)
            % Returns a list of properties which have SetAccess == public
            m = metaclass(obj);
            if isempty(m)
                % If the metaclass is empty, just return.  This can happen for
                % java objects, for example.
                origObjSetAccessNames = strings(0);
                origObjectPropNames = strings(0);
                return
            end
            origObjProps = m.PropertyList;
            hidden = [origObjProps.Hidden];
            origObjProps = origObjProps(~hidden);

            numProps = length(origObjProps);
            origObjSetAccess = false(size(origObjProps));
            for i=1:numProps
                try
                    origObjProp = origObjProps(i);
                    access = origObjProp.SetAccess;

                    % Set isPublicAccess to true if the SetAccess == "public"
                    isPublicAccess = ischar(access) && access == "public";

                    % But also check for Dependent properties.  Dependent
                    % properties with no SetMethod should be treated as if the
                    % SetAccess is not public (except for graphics objects,
                    % which have Dependent properties with no SetMethod, which
                    % you can set just fine)
                    if origObjProp.Dependent && ~isa(origObjProp, "matlab.graphics.internal.GraphicsMetaProperty")
                        origObjSetAccess(i) = isPublicAccess && ~isempty(origObjProp.SetMethod);
                    else
                        origObjSetAccess(i) = isPublicAccess;
                    end
                catch
                    % Ignore errors.  If there are properties that error when we
                    % try to get their access, just assume they are not
                    % accessible.
                end
            end
            origObjectPropNames = string({origObjProps.Name});
            origObjSetAccessNames = origObjectPropNames(origObjSetAccess);

            % Dynamic properties don't show up in the property list -- but its
            % quicker to traverse the metaclass PropertyList first and only use
            % calls to findprop if we need to.
            if ismethod(obj, "findprop") && ~isequal(properties(obj), origObjectPropNames)
                extraProps = setdiff(properties(obj), origObjectPropNames);
                for i = 1:length(extraProps)
                    extraPropName = extraProps(i);
                    p = findprop(obj, extraPropName);
                    origObjectPropNames(end+1) = extraPropName;
                    if isempty(p) || (ischar(p.SetAccess) && p.SetAccess == "public")
                        origObjSetAccessNames(end+1) = extraPropName;
                    end
                end
            end
        end

        function showOpenvar = shouldShowOpenvarEditor(...,
                matchedVariableClass, ...
                rawDataVal)

            matchedVariableClass = string(matchedVariableClass);
            showOpenvar = false;

            if any(matchedVariableClass == ...
                    [internal.matlab.variableeditor.NumericArrayDataModel.NumericTypes]) && ...
                    ~isscalar(rawDataVal)

                % Show the openvar editor if the length is enough to show the
                % value as metadata (for example, 1x15 double)
                showOpenvar = true;

            elseif matchedVariableClass == "cell"
                if iscellstr(rawDataVal) && ~isscalar(rawDataVal) %#ok<*ISCLSTR>
                    % Show the openvar editor for non-scalar cellstr
                    showOpenvar = true;
                elseif ~iscellstr(rawDataVal)
                    % And for any other cell arrays
                    showOpenvar = true;
                end

            elseif any(matchedVariableClass == ...
                    ["datetime", "duration", "calendarDuration", ...
                    "string", "categorical"])

                if ~isscalar(rawDataVal)
                    % Show the openvar editor for other data types, unless they
                    % are scalar
                    showOpenvar = true;
                end

            elseif any(matchedVariableClass == ["struct", "table", "timetable"])

                % Show the openvar editor for container types
                showOpenvar = true;

            elseif isobject(rawDataVal)

                % Show the openvar editor for objects as well
                showOpenvar = true;
            end
        end
    end
end
