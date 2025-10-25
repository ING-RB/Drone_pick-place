classdef UIAxesAdapter <  appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for the new (R2020b) UIAxes, which is a charting component sub-classed
    % from matlab.graphics.axis.Axes

    % Copyright 2015-2022 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {}

        % the "Value" property of the component
        ValueProperty = [];

        ComponentType = 'matlab.ui.control.UIAxes';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = UIAxesAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end

        function propertyNames = getCodeGenPropertyNames(obj, componentHandle)
            % GETCODEGENPROPERTYNAMES - Override the superclass method so
            % that UIAxes' handle properties are ignored for code
            % generation:
            % XLabel, YLabel, ZLabel, Title, Toolbar, XAxis, YAxis, ZAxis,
            % Subtitle

            import appdesigner.internal.componentadapterapi.VisualComponentAdapter;

            % Get all properties as a struct and get the property names
            % as a starting point
            propertyValuesStruct = get(componentHandle);
            allProperties = fieldnames(propertyValuesStruct);

            % Properties that are always ignored and are never set when
            % generating code
            %
            % Remove these from both the properties and order specific
            % properties
            readOnlyProperties = VisualComponentAdapter.listNonPublicProperties(componentHandle);

            % Obtain all the text-based aliased properties (e.g.
            % TitleString), then remove the 'String' suffix (e.g. Title)
            % and 'AD_' prefix.
            textAliasedProperties = obj.getTextAliasedProperties();
            textAliasedPropertyNames = replace({textAliasedProperties(:).Name}, {'String';'AD_'}, '');

            ignoredProperties = [obj.CommonPropertiesThatDoNotGenerateCode, readOnlyProperties, [{...
                'SizeChangedFcn',...
                'ContextMenu',...
                'Units',...
                'Visible',...
                ... % UIAxes properties to ignore since they are sub-objects
                ... % and code-gen cannot handle sub-objects.
                'Toolbar', ...
                'FontSmoothing',...
                'InteractionOptions',...
                'XAxis',...
                'YAxis',...
                'ZAxis',...
                },...
                textAliasedPropertyNames]];

            % Get properties related to mode so some can be excluded
            [autoModeProperties, ~, manualModeProperties] = ...
                matlab.ui.control.internal.model.PropertyHandling.getModeProperties(propertyValuesStruct);
            modePropertiesToIgnore = [autoModeProperties, manualModeProperties];

            propertiesAtEnd = {'InnerPosition','Position'};

            % Filter out properties to be at the end, otherwise there would
            % be duplicated name in the list, e.g. Position occurs twice
            propertyNames = setdiff(allProperties, [ignoredProperties, propertiesAtEnd modePropertiesToIgnore], 'stable');

            % Add the aliased properties to the master list.  Exclude
            % AD_AliasedVisible because it is added as a transient property
            % at design-time.
            aliasedProperties = obj.getAllSerializableAliasedProperties();

            % Create the master list
            propertyNames = [...
                ... % UIAxes Design-time properties that need to be looked at
                ... % for code-gen
                {aliasedProperties(:).Name},...
                propertyNames', ...
                propertiesAtEnd, ...
                ];

        end

        function codeSnippet = getCodeGenPropertySet(obj, component, objectName, propertyName, codeName, parentCodeName)
            % GETCODEGENPROPERTYSET - Generates a line of code that would
            % set the property designated in the input propertyName.
            % This method handles any special code generation requirements
            % for specific UIAxes properties. For all other properties, it
            % calls the superclass that handles the code generation in the
            % default manner.
            % E.g. The title property should have the code
            % title(axeshandle, 'myAxes');

            % g1747317: Generate code for the Interpreter if its changed
            % via the Defaults system instead of the property editing
            % workflow
            % Need to revisit when we expose Interpreter from the
            % inspector
            systemWideDefaults = get(0, 'default');

            shouldGenerateForInterpreter = false;

            interpreter = get(0, 'DefaultTextInterpreter');

            % 'defaultTextInterpreter' is present in the defaults only if it was changed
            if( isfield(systemWideDefaults, 'defaultTextInterpreter'))
                shouldGenerateForInterpreter = true;
            end

            textAliasedProperties = obj.getTextAliasedProperties();
            switchStateAliasedPropertes = obj.getSwitchStateAliasedProperties();

            switch (propertyName)

                case {textAliasedProperties(:).Name}
                    % Example:
                    % 'title(app.ad_CODENAME_ad, 'Title')'
                    % changes to
                    % 'title(app.ad_CODENAME_ad, 'Title', 'Interpreter', 'latex')'

                    [~, index] = ismember(propertyName,{textAliasedProperties(:).Name});
                    propertyValue = obj.getPropertyValue(component, textAliasedProperties(index).PropertyMapping);
                    codeGenEntry = textAliasedProperties(index).CodeGenEntry;

                    if (shouldGenerateForInterpreter && textAliasedProperties(index).isSimpleLabel)
                        codeSnippet = sprintf('%s(%s.%s, %s, %s)',...
                            codeGenEntry,...
                            objectName,...
                            codeName,...
                            formatLabelString(obj, propertyValue),...
                            ['''Interpreter'', ''' interpreter '''']);
                    else
                        codeSnippet = sprintf('%s(%s.%s, %s)',...
                            codeGenEntry,...
                            objectName,...
                            codeName,...
                            formatLabelString(obj, propertyValue));
                    end

                case {switchStateAliasedPropertes(:).Name}

                    [~, index] = ismember(propertyName,{switchStateAliasedPropertes(:).Name});
                    propertyValue = obj.getPropertyValue(component, switchStateAliasedPropertes(index).PropertyMapping);
                    codeGenEntry = switchStateAliasedPropertes(index).CodeGenEntry;

                    codeSnippet = sprintf('%s.%s.%s = ''%s'';',...
                        objectName,...
                        codeName, ...
                        codeGenEntry, ...  % e.g. Toolbar.Visible
                        propertyValue);

                otherwise
                    % Call superclass with the same parameters
                    codeSnippet = getCodeGenPropertySet@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(...
                        obj, component, objectName, propertyName, codeName, parentCodeName);
            end
        end

        function value = formatLabelString(obj, value) %#ok<INUSL>
            % FORMATLABELSTRING - Helper function to format label's String property

            if(iscell(value))

                if(length(value) == 1)
                    % Ex: String = {'foo'}
                    %
                    % label is a cell of 1, print it like a char
                    value = appdesigner.internal.codegeneration.ComponentCodeGenerator.propertyValueToString('char', value{1});
                else
                    % Ex: String = {'foo', 'bar'}
                    %
                    % print as a cell
                    value = appdesigner.internal.codegeneration.ComponentCodeGenerator.propertyValueToString('cell', value);
                end
            else
                % Ex: String = 'foo'
                %
                % print non cell values as a char
                value = appdesigner.internal.codegeneration.ComponentCodeGenerator.propertyValueToString('char', value);
            end
        end

        function isDefaultValue = isDefault(obj, componentHandle, propertyName, defaultComponent)
            % ISDEFAULT - Returns a true or false status based on whether
            % the value of the component corresponding to the propertyName
            % inputted is the default value.  If the value returned is
            % true, then the code for that property will not be displayed
            % in the code at all

            % Override to handle the checks for design-time specific
            % properties: XLabelString, YLabelString, ZLabelString,
            % TitleString, ToolbarVisible, SubtitleString

            textAliasedProperties = obj.getTextAliasedProperties();
            simpleLabelAliasedPropertyNames = {textAliasedProperties([textAliasedProperties.isSimpleLabel]).Name};

            switchStateAliasedPropertes = obj.getSwitchStateAliasedProperties();

            switch (propertyName)
                case simpleLabelAliasedPropertyNames

                    [~, index] = ismember(propertyName,{textAliasedProperties(:).Name});
                    propertyValue = obj.getPropertyValue(componentHandle, textAliasedProperties(index).PropertyMapping);
                    isDefaultValue = isequal(propertyValue, {''}) || isequal(propertyValue, '');

                case {switchStateAliasedPropertes(:).Name}

                    [~, index] = ismember(propertyName,{switchStateAliasedPropertes(:).Name});
                    propertyValue = obj.getPropertyValue(componentHandle, switchStateAliasedPropertes(index).PropertyMapping);
                    isDefaultValue = isequal(propertyValue, 'on') || isequal(propertyValue, 1);

                case 'AD_ColormapString'
                    isDefaultValue = isequal(componentHandle.Colormap, defaultComponent.Colormap);

                case {'Controller','getControllerHandle'}
                    isDefaultValue = 1;

                case 'InnerPosition'
                    isDefaultValue = strcmp(componentHandle.InnerPositionMode,'auto');

                otherwise
                    % Call superclass with the same parameters
                    isDefaultValue = isDefault@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(obj,componentHandle,propertyName, defaultComponent);
            end
        end
    end

    methods (Access = protected)
        function applyCustomComponentDesignTimeDefaults(obj, component) %#ok<INUSL>
            % APPLYCUSTOMCOMPONENTDESIGNTIMEDEFAULT - Apply custom design-time
            % defaults to the component.

            % Set the design time properties for
            % Position/Title/XLabel/YLabel/ZLabel
            component.Position = [0 0 300 185];
            component.Title.String = getString(message('MATLAB:ui:defaults:UIAxesTitle'));
            component.XLabel.String = getString(message('MATLAB:ui:defaults:UIAxesXLabel'));
            component.YLabel.String = getString(message('MATLAB:ui:defaults:UIAxesYLabel'));
            component.ZLabel.String = getString(message('MATLAB:ui:defaults:UIAxesZLabel'));
        end
    end

    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/UIAxesModel';
        end
    end

    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName) %#ok<INUSL>
            codeSnippet = sprintf('uiaxes(%s)', parentName);
        end

        function colorProperties = getColorProperties()
            %GETCOLORPROPERTIES - get the color properties that are
            %modified to enable opacity of the UIAxes

            colorProperties = {'Color', 'XColor', 'YColor', 'ZColor'};
        end

        function hasAliased = hasAliasedProperties (obj)
            hasAliased = true;
        end

        function aliasedProperties = getAllSerializableAliasedProperties()
            %GETALLSERIALIZABLEALIASEDPROPERTIES - Get all of the serializable
            %aliased properties

            % We must directly reference the static methods because the
            % adapter is not fully setup during loading.
            aliasedProperties = appdesigner.internal.componentadapter.uicomponents.adapter.UIAxesAdapter.getAllAliasedProperties();

            % Check for properties that have Serializable as false.  For these
            % properties, remove the aliased property from the returned struct.
            indicesOfNonSerializableProperties = ~[aliasedProperties(:).Serializable];
            aliasedProperties(indicesOfNonSerializableProperties) = [];
        end

        function aliasedProperties = getAllAliasedProperties()
            %GETALLALIASEDPROPERTIES - Get all of the aliased properties,
            %including both the text-based properties and the
            %OnOffSwitchState properties.

            import appdesigner.internal.componentadapter.uicomponents.adapter.UIAxesAdapter;

            % We must directly reference the static methods because the
            % adapter is not fully setup during loading.
            aliasedProperties = [UIAxesAdapter.getTextAliasedProperties(), ...
                UIAxesAdapter.getSwitchStateAliasedProperties()];
        end

        function textAliasedProperties = getTextAliasedProperties()
            %GETTEXTALIASEDPROPERTIES - Get information about the aliased
            %properties on the UIAxes whose values are strings (e.g. xlabel
            %and ylabel)

            % This structure is organized:
            % textAliasedProperties
            %   AliasPropertyName (e.g. XLabelString)
            %   CodeGenEntry (function that is shown in the generated code for this property (e.g. xlabel))
            %   PropertyMapping (Run-time UIAxes Property that is aliased (e.g. XLabel.String)
            %   AliasPropertyName
            %       etc..

            textAliasedProperties = [...
                struct(...
                    'Name','TitleString',...
                    'CodeGenEntry','title', ...
                    'PropertyMapping','Title.String',...
                    'Serializable', true,...
                    'isSimpleLabel', true,...
                    'UserFacingName', 'Title.String'),...
                    ...
                struct(...
                    'Name','XLabelString',...
                    'CodeGenEntry','xlabel', ...
                    'PropertyMapping','XLabel.String', ...
                    'Serializable', true,...
                    'isSimpleLabel', true,...
                    'UserFacingName', 'XLabel.String'),...
                    ...
                struct(...
                    'Name','YLabelString',...
                    'CodeGenEntry','ylabel', ...
                    'PropertyMapping','YLabel.String', ...
                    'Serializable', true,...
                    'isSimpleLabel', true,...
                    'UserFacingName', 'YLabel.String'),...
                    ...
                struct(...
                    'Name','ZLabelString',...
                    'CodeGenEntry','zlabel', ...
                    'PropertyMapping','ZLabel.String', ...
                    'Serializable', true,...
                    'isSimpleLabel', true,...
                    'UserFacingName', 'ZLabel.String'),...
                    ...
                struct(...
                    'Name','SubtitleString',...
                    'CodeGenEntry','subtitle', ...
                    'PropertyMapping','Subtitle.String', ...
                    'Serializable', true,...
                    'isSimpleLabel', true,...
                    'UserFacingName', 'Subtitle.String'),...
                    ...
                struct(...
                    'Name','AD_ColormapString',...
                    'CodeGenEntry','colormap', ...
                    'PropertyMapping','ColormapString', ...
                    'Serializable', false,...
                    'isSimpleLabel', false,...
                    'UserFacingName', 'Colormap')...
            ];
        end

        function switchStateAliasedProperties = getSwitchStateAliasedProperties()
            %GETSWITCHSTATEALIASEDPROPERTIES - Get information about the aliased
            %properties on the UIAxes whose values are OnOffSwitchStates
            %(e.g. Toolbar.Visible)

            % This structure is organized:
            % switchStateAliasedPropertes
            %   AliasPropertyName (e.g. ToolbarVisible)
            %       CodeGenEntry (property that is shown in the generated
            %           code (e.g. <>.Toolbar.Visible))
            %       PropertyMapping (Run-time UIAxes Property that is aliased (e.g. Toolbar.Visible)
            %   AliasPropertyName
            %       etc..
            switchStateAliasedProperties = [...
                struct( ...
                    'Name','ToolbarVisible',...
                    'CodeGenEntry', 'Toolbar.Visible', ...
                    'PropertyMapping', 'Toolbar.Visible', ...
                    'Serializable', true,...
                    'isSimpleLabel', false,...
                    'UserFacingName', 'Toolbar.Visible'),...
                struct( ...
                    'Name','AD_AliasedVisible',...
                    'CodeGenEntry', 'Visible', ...
                    'PropertyMapping', 'AD_AliasedVisible', ...
                    'Serializable', false,...
                    'isSimpleLabel', false,...
                    'UserFacingName', 'Visible'),...
            ];
        end

        function propertyValue = getPropertyValue(component, propertyNested)
            %GETPROPERTYVALUE - Get the property value from the component,
            %given a nested property string (e.g. Subtitle.String)

            % Split the property map at the period (e.g. 'Subtitle.String'
            % goes to {'Subtitle','String'}
            propertiesInCellArray = strsplit(propertyNested, '.');

            % The property value of the 'ColormapString' aliased property
            % requires an outside function call (not just a simple property
            % find).  Therefore, we must deal with it separately.
            if strcmp(propertyNested, 'ColormapString')
                propertyValue = inspector.internal.getColormapString(component.Colormap);
                return;
            end

            for i = 1:length(propertiesInCellArray)
                property = propertiesInCellArray{i};
                if i == 1
                    propertyValue = component.(property);
                else
                    propertyValue = propertyValue.(property);
                end
            end
        end
    end
end