classdef ComponentDefaults < handle
    % ComponentDefaults  Mixin for managing component defaults:
    %   Design-time component defaults
    %   Runtime component defaults

    % Copyright 2017 - 2023 The MathWorks, Inc.
    %

    methods(Access = public, Sealed = true)
        % ---------------------------------------------------------------------
        % get the component Design Time default values
        % This method is sealed since template methods have been provided
        % for sub-class to override or customize behaviours
        % ---------------------------------------------------------------------
        function defaultValues = getComponentDesignTimeDefaults(obj)
            % return a struct of component properties and their
            % design-time default values.  To get the defaults the
            % design-time component is created without realizing the view
            % Need to remove the feature flags once the themes feature is OBD.

            [component, cleanups] = obj.createDesignTimeComponentWithCleanup();

            figureComponent = ancestor(component, 'matlab.ui.Figure');

            % Defaults for UIComponents are generated in Java MATLAB during build.
            % So we need to explicity set the theme for UIFigure.
            % This can be removed when the JSD MATLAB is used for build.
            if(feature('AutomaticFigureThemes') == 1) && isempty(figureComponent.Theme)
                s = settings;
                currentTheme = s.matlab.appearance.figure.GraphicsTheme.ActiveValue;

                if strcmp(currentTheme, 'light') || strcmp(currentTheme, 'dark')
                    figureComponent.Theme =  s.matlab.appearance.figure.GraphicsTheme.ActiveValue;
                    figureComponent.ThemeMode = 'auto';
                end
            end

            % create design time controller to get the defaults
            controllerClass = obj.getComponentDesignTimeController();
            controller = feval(controllerClass, ...
                component, [], appdesigner.internal.componentview.EmptyProxyView(), []);

            % Get PV pairs of the component
            propertyNameValues = controller.getPVPairsForView(component);

            % Add all the corresponding Mode properties to the PV pairs
            propertyNameValues = controller.addPropertyModeValues(propertyNameValues);

            % convert to a struct
            defaultValues = appdesservices.internal.peermodel.convertPvPairsToStruct(...
                propertyNameValues);

            % Remove DesignTimeProperties which is added by
            % DesignTimeController
            defaultValues = rmfield(defaultValues, 'DesignTimeProperties');

            % Get customized component design-time defaults
            defaultValues = obj.customizeComponentDesignTimeDefaults(defaultValues, component);
        end
    end

    methods
        % ---------------------------------------------------------------------
        % create the Design Time component for getting Design Time default values
        % ---------------------------------------------------------------------
        function [component, cleanups] = createDesignTimeComponentWithCleanup(obj)
            % create the parent of the design time component
            cleanupObj = appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.listenAndConfigureUIFigure();
            parent = obj.createDesignTimeParentComponent();

            % create the component and parent it
            component = obj.createDesignTimeComponent(parent);

            % Callback to delete components, including parents, created
            % during getting defaults
            function deleteDesignTimeComponent(designTimeComponent)
                % Loop up to find the figure parent of the component
                parentComponent = designTimeComponent;
                while ~isempty(parentComponent.Parent) && ...
                        ~isa(parentComponent.Parent, 'matlab.ui.Root') && ...
                        ~isa(parentComponent, 'matlab.ui.Figure')
                    parentComponent = parentComponent.Parent;
                end

                delete(parentComponent);
            end
            oc = onCleanup(@()deleteDesignTimeComponent(component));

            cleanups = [cleanupObj, oc];

        end

        function component = createDesignTimeComponent(obj, parent)
            % design time specific property values that are different from
            % default runtime's

            % Parent must be the first one in PV pairs for GBT comonents
            % Create the component, passing in PV Pairs
            component = feval(obj.ComponentType, 'Parent', parent);

            obj.applyCustomComponentDesignTimeDefaults(component);
        end

        % ---------------------------------------------------------------------
        % get the component run-time default values
        % ---------------------------------------------------------------------
        function defaultValues = getComponentRunTimeDefaults(obj, theme, parentType)
            arguments
                obj
                theme = 'unthemed'
                parentType = ''
            end
            % return a struct of component properties and their
            % run-time default values

            % get the run time defaults for a component parented to a
            % uifigure
            themeArg = {};
            if (strcmp(theme, 'light') || strcmp(theme, 'dark'))
                themeArg = {'Theme', theme};
            end

            cleanupObj = appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.listenAndOverrideDefaultCreateFcnOnUIFigure();
            figure = appdesigner.internal.componentadapter.uicomponents.adapter.createUIFigure(themeArg{:});

            % delete the figure
            cf = onCleanup(@()delete(figure));

            if (nargin > 2 && ~isempty(parentType))
                parent = feval(parentType, 'Parent', figure);
            else
                parent = figure;
            end

            % Create the component under its parent to get the appropriate defaults for the respective theme
            component = feval(obj.ComponentType, ...
                'Parent', parent);

            defaultValues = get(component);

            % AutoResizeChildren property is hidden, it is not returned by 'get'
            if(isprop(component, 'AutoResizeChildren'))
                defaultValues.AutoResizeChildren = component.AutoResizeChildren;
            end

            delete(component);
        end
    end

    methods (Access = protected)
        % Create the Design Time parent component to parent design-time component
        % for getting Design Time default values
        function parent = createDesignTimeParentComponent(obj)
            % In most cases, the component is parented to a UIFigure,
            % but for children of TabGroup, ButtonGroup, the parent is
            % different
            parent = appdesigner.internal.componentadapter.uicomponents.adapter.createUIFigure();
        end

        % Apply custom design-time defaults to the design-time component
        function applyCustomComponentDesignTimeDefaults(obj, component)
            % The sub-class (individual component adapter) implement this
            % function to apply custom design-time component defaults to
            % the component
            %
            % Set custom value to the component
            %
            % Example Code in sub-class adapter:
            %     % Apply custom design-time value to the property
            %     component.Position = [0 0 300 185];
        end

        % Customize the Design Time component default values
        function defaultValues = customizeComponentDesignTimeDefaults(obj, defaultValues, component)
            % The sub-class (individual component adapter) implement this
            % function to modify component defaults struct
            %
            % Return a modified default value struct
            %
            % Add value/modify value to the struct directly
            %
            % Example Code in sub-class adapter:
            %     % Modify value on struct because it's read-only on the
            %     %component
            %     defaultValues.InnerPosition = [62 43 210 130];
            %
        end
    end

    % ---------------------------------------------------------------------
    % a method called at AppDesigner startup to retrieve the component's
    % dynamic properties.  By default it returns an empty array but
    % can be overloaded by a component adapter
    %
    % For example, the DatePicker component gets it's DisplayFormat,
    % InputFormat and ViewLanguage properties from matlab preferences.
    % If the user changes the preferences, the next App Designer is started
    % it will pick up the latest values
    % ---------------------------------------------------------------------
    methods(Static)
        function dynamicProperties = getDynamicProperties(~)
            dynamicProperties = [];
        end
    end
end

