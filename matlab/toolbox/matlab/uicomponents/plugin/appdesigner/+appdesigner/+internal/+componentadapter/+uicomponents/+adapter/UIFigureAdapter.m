classdef UIFigureAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for uifigure

    % Copyright 2016-2024 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {}

        % the "Value" property of the component
        ValueProperty = [];

        ComponentType = 'matlab.ui.Figure';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = UIFigureAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end

        % ---------------------------------------------------------------------
        % get the component run-time default values
        % ---------------------------------------------------------------------
        function defaultValues = getComponentRunTimeDefaults(obj, theme, parentType) %#ok<MANU>
            arguments
                obj
                theme = 'unthemed'
                parentType = ''
            end
            % return a pvPair array of figure properties and their
            % run-time default values

            themeArg = {};

            if (strcmp(theme, 'light') || strcmp(theme, 'dark'))
                themeArg = {'Theme', theme};
            end

            model = appdesigner.internal.componentadapter.uicomponents.adapter.createUIFigure(themeArg{:});
            c = onCleanup(@()delete(model));
            defaultValues = get(model);

            % Theme property is hidden, it is not returned by 'get'
            defaultValues.Theme = model.Theme;
        end

        % ---------------------------------------------------------------------
        % create the Design Time component for getting Design Time default values
        % ---------------------------------------------------------------------
        function component = createDesignTimeComponent(obj, ~)
            component = appdesigner.internal.componentadapter.uicomponents.adapter.createUIFigure();

            obj.applyCustomComponentDesignTimeDefaults(component);
        end


        function codeSnippet = getCodeGenPropertySet(obj, component, objectName, propertyName, codeName, parentCodeName)
            % GETCODEGENPROPERTYSET - Generates a line of code that would
            % set the property designated in the input propertyName.
            % This method handles any special code generation requirements
            % for specific Figure properties. For all other properties, it
            % calls the superclass that handles the code generation in the
            % default manner.
            % E.g. The AD_ColormapString property should have the code
            % colormap(figurehandle, 'copper');

            switch (propertyName)
                case 'AD_ColormapString'
                    propertyValue = inspector.internal.getColormapString(component.Colormap);
                    codeSnippet = sprintf('colormap(%s.%s, ''%s'');',...
                        objectName,...
                        codeName, ...
                        propertyValue);

                case 'AD_AliasedThemeChangedFcn'
                    propertyValue = component.AD_AliasedThemeChangedFcn;
                    codeSnippet = sprintf('%s.%s.ThemeChangedFcn = createCallbackFcn(app, @%s, true);', ...
                        objectName, codeName, propertyValue);


                otherwise
                    % Call superclass with the same parameters
                    codeSnippet = getCodeGenPropertySet@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(...
                        obj, component, objectName, propertyName, codeName, parentCodeName);
            end
        end

        function propertyNames = getCodeGenPropertyNames(obj, componentHandle) %#ok<INUSD>

            % Use an explicit subset of properties from the figure that App
            % Designer supports
            propertyNames = {...
                % AutoResizeChildren should be listed before SizeChangedFcn to avoid the
                % warning message when both have non-default values
                % (AutoResizeChildren off and SizeChangedFcn non-empty).
                'IntegerHandle'...
                'NumberTitle'...
                'AutoResizeChildren' ...
                'Color' ...
                'AD_ColormapString' ...
                'Position' ...
                'Name' ...
                'Icon'...
                'Resize' ...
                'Theme' ...
                'CloseRequestFcn' ...
                'SizeChangedFcn' ...
                'WindowButtonDownFcn'...
                'WindowButtonUpFcn'...
                'WindowButtonMotionFcn'...
                'WindowScrollWheelFcn'...
                'ButtonDownFcn'...
                'AD_AliasedThemeChangedFcn' ...
                'WindowKeyPressFcn'...
                'WindowKeyReleaseFcn'...
                'KeyPressFcn'...
                'KeyReleaseFcn'...
                'BusyAction' ...
                'Interruptible' ...
                'Scrollable'...
                'HandleVisibility'...
                'Tag'...
                'WindowStyle'...
                'WindowState'...
                'Pointer',...
                'Alphamap'
                };
        end

        function isDefaultValue = isDefault(obj, componentHandle, propertyName, defaultComponent)
            % ISDEFAULT - Returns a true or false status based on whether
            % the value of the component corresponding to the propertyName
            % inputted is the default value.  If the value returned is
            % true, then the code for that property will not be displayed
            % in the code at all


            switch (propertyName)
                case 'CloseRequestFcn'
                    value = componentHandle.(propertyName);
                    isDefaultValue = isempty(value) || strcmp(value, 'closereq');

                case 'AD_ColormapString'
                    isDefaultValue = isequal(componentHandle.Colormap, defaultComponent.Colormap);

                case 'AD_AliasedThemeChangedFcn'
                    isDefaultValue = isequal(componentHandle.AD_AliasedThemeChangedFcn, defaultComponent.ThemeChangedFcn);

                case 'Theme'
                    isDefaultValue = isequal(componentHandle.ThemeMode, 'auto');

                otherwise
                    % Call superclass with the same parameters
                    isDefaultValue = isDefault@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(obj,componentHandle,propertyName, defaultComponent);
            end
        end

        function controllerClass = getComponentDesignTimeController(obj) %#ok<MANU>
            controllerClass = 'matlab.ui.internal.DesignTimeUIFigureController';
        end
    end

    methods (Access = protected)
        % Create the Design Time parent component to parent design-time component
        % for getting Design Time default values
        function parent = createDesignTimeParentComponent(~)
            % no-op for uifigure
            parent = [];
        end

        function applyCustomComponentDesignTimeDefaults(obj, component) %#ok<INUSL>
            % Apply custom design-time component defaults to the component

            % Set design-time defaults to the component
            component.Position = [100 100 640 480];
            component.Name =  '';
        end

    end

    methods(Static)
        function docString = getDocString()
            docString = 'matlab.ui.FigureAPPD';
        end

        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/UIFigureModel';
        end

        % ---------------------------------------------------------------------
        % Code Gen Methods
        % ---------------------------------------------------------------------
        function codeSnippet = getCodeGenCreation(~, ~, ~)
            codeSnippet = 'uifigure(''Visible'', ''off'')';
        end

        function hasAliased = hasAliasedProperties()
            hasAliased = true;
        end

        function aliasedProperties = getAllAliasedProperties()
            aliasedProperties = [...
                struct(...
                'Name','AD_ColormapString',...
                'CodeGenEntry','colormap', ...
                'PropertyMapping','ColormapString', ...
                'Serializable', false,...
                'isSimpleLabel', false,...
                'UserFacingName', 'Colormap'), ...
                struct('Name', 'AD_AliasedThemeChangedFcn', ...
                'CodeGenEntry', 'ThemeChangedFcn', ...
                'PropertyMapping', 'ThemeChangedFcn', ...
                'Serializable', false, 'isSimpleLabel', false, ...
                'UserFacingName', 'ThemeChangedFcn')
                ];
            
        end
    end
end
