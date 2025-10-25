classdef UserComponentAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter ...
        & matlab.ui.internal.componentframework.services.optional.ControllerInterface
    % This is the adapter for any User Component

    % Copyright 2020-2024 The MathWorks, Inc.        

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {}

        % the "Value" property of the component
        ValueProperty = [];

        ComponentType;

        % Enable client driven creation for UAC's internal components
        % Individual components need to set this to true explicitly to 
        % opt in client-driven-creation optimization for performance
        EnableClientDriven = false;
    end

    properties (Access=private)
        % Cache the run time defaults so that the component need not be
        % instantiated every time while getting run time defaults.
        RunTimeDefaultValues = [];

        InplaceEditors = [];
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = UserComponentAdapter(componentType)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter();

            obj.ComponentType = componentType;

            obj.shouldCacheCodegenProperties = false;
            obj.shouldCacheCallbackPropertyNames = false;
        end

        % ---------------------------------------------------------------------
        % Code Gen Method to return an array of property names, in the correct
        % order, as required by Code Gen
        % ---------------------------------------------------------------------
        function propertyNames = getCodeGenPropertyNames(obj, componentHandle)

            allProperties = properties(obj.ComponentType);

            % Properties that are always ignored and are never set when
            % generating code
            %
            % Remove these from both the properties and order specific
            % properties
            readOnlyProperties = obj.listNonPublicProperties(componentHandle);

            ignoredProperties = [obj.CommonPropertiesThatDoNotGenerateCode, readOnlyProperties, {...
                ... These properties are specific to
                'ButtonDownFcn',...
                'Clipping',...
                'ContextMenu',...
                'Units',...
                }];


            propertiesAtEnd = {'Position'};

            % Create the master list
            propertyNames = [ ...
                setdiff(allProperties, ...
                [ignoredProperties, propertiesAtEnd], 'stable');...
                propertiesAtEnd' ...
                ];
        end

        function controllerClass = getComponentDesignTimeController(obj)
            controllerClass = 'matlab.ui.internal.DesignTimeWebUIContainerController';
        end

        function defaultValues = getComponentRunTimeDefaults(obj, theme, parentType)
            arguments
                obj
                theme = 'unthemed'
                parentType = ''
            end
            % DEFAULTVALUES = GETCOMPONENTRUNTIMEDEFAULTS(OBJ) overrides the super method to
            % cache the run-time defaults without needing to instantiate the component every time
            % while getting default values.See g2665001 for more details.
            if isempty(obj.RunTimeDefaultValues)
                obj.RunTimeDefaultValues = getComponentRunTimeDefaults@appdesigner.internal.componentadapterapi.mixins.ComponentDefaults(obj, theme);
            end

            defaultValues =  obj.RunTimeDefaultValues;
        end

        function propertyViewClass = getComponentPropertyView(obj)
            propertyViewClass = 'inspector.internal.UserComponentPropertyView';
        end

        function flattenedInplaceEditorData = getUserComponentInplaceEditorData(obj, userComponent)
            % FLATTENEDINPLACEEDITORDATA = GETUSERCOMPONENTINPLACEEDITORDATA(OBJ, USERCOMPOENNT) 
            % Returns the flat list of Inplace editor data defined the
            % corresponding component adapter
            flattenedInplaceEditorData = {};
            children = obj.getUserComponentDirectChildren(userComponent);
            for ix = numel(children):-1:1
                flattenedInplaceEditorData = [flattenedInplaceEditorData obj.flattenUserComponentInplaceEditorData(children(ix))];
            end
        end

        function defineInternalComponentInplaceEditors(obj, userComponent)
            % DEFINEINTERNALCOMPONENTINPLACEEDITORS(OBJ) 
            % Toolbox Component adapters extending UserComponentAdapter
            % need to define this method to provide inplace editing data

            % No op for base class
        end
    end

    methods(Access = protected)
        function addInplaceEditor(obj, component, inplaceEditableProperty, linkedPublicProperties, editCallbackFcn)
            arguments
                obj
                component
                inplaceEditableProperty char
                linkedPublicProperties
                editCallbackFcn function_handle = @(obj, userComponent, publicProperties, newValue) obj.defaultEditCallbackFcn(userComponent, publicProperties, newValue);
            end

            % Step 1: Loop through the existing elements of obj.InplaceEditors & Verify if it already has an entry with the given component
            % If the given component is not found, add a new entry
            componentIndex = -1;
            for i = 1:length(obj.InplaceEditors)
                if (isequal(obj.InplaceEditors(i).component, component))
                    componentIndex = i;
                end
            end

            if componentIndex == -1
                componentIndex = length(obj.InplaceEditors) + 1;
                obj.InplaceEditors(componentIndex).component = component;
                obj.InplaceEditors(componentIndex).EditorData = struct();
            end

            % Step 2: Add the inplaceEditableProperty information to the struct
            obj.InplaceEditors(componentIndex).EditorData.(inplaceEditableProperty).PublicProperties = linkedPublicProperties;
            obj.InplaceEditors(componentIndex).EditorData.(inplaceEditableProperty).EditCallbackFcn = editCallbackFcn;
        end

        function defaultValues = customizeComponentDesignTimeDefaults(obj, defaultValues, component)
            
            if obj.EnableClientDriven
                % Mark this UAC to be client driven one if defaults have been
                % generated through this method
                defaultValues.IsClientDriven = true;

                defaultValues.InternalComponentsDefaults = {};

                obj.defineInternalComponentInplaceEditors(component);

                % Kick of controller creation of internal components
                drawnow update;

                directChildren = obj.getUserComponentDirectChildren(component);

                for ix = numel(directChildren):-1:1
                    internalComponent = directChildren(ix);

                    componentInfo = obj.getInternalComponentDefaults(internalComponent);
                    defaultValues.InternalComponentsDefaults{end+1} = componentInfo;
                end
            end
        end

        function componentInfo = getInternalComponentDefaults(obj, component)
            componentController = matlab.ui.internal.componentframework.build.DefaultsBuilder.getController(component);
            pvPairs = matlab.ui.internal.componentframework.build.DefaultsBuilder.getPVPairsForView(component, componentController);

            if isa(component, "matlab.ui.control.internal.model.mixin.IconableComponent")
                pvPairs = [pvPairs, {'Icon', component.Icon, 'IconType', component.IconType}];
            end

            componentInfo.Type = class(component);
            componentDefaultValues = appdesservices.internal.peermodel.convertPvPairsToStruct(pvPairs);
            componentInfo.PropertyValues = componentDefaultValues;
            inplaceEditorData = obj.getInternalComponentInplaceEditorData(component, true);
            if ~isempty(inplaceEditorData)
                componentInfo.InplaceEditorData = obj.getInternalComponentInplaceEditorData(component, true);
            end

            % Todo: support nested UAC components
            childrenComponents = obj.getInternalComponentChildren(component);

            componentInfo.Children = {};
            for ix = 1:numel(childrenComponents)
                childComponentInfo = obj.getInternalComponentDefaults(childrenComponents(ix));
                componentInfo.Children{end+1} = childComponentInfo;
            end
        end
    end

    methods(Access = private)
        function children = getUserComponentDirectChildren (~, userComponent) 
            % GETUSERCOMPONENTDIRECTCHILDREN(OBJ) 
            % Returns the Components that are directly parented to User component
            children = findall(userComponent.NodeChildren, 'flat', ...
                '-not', '-isa', 'matlab.graphics.primitive.canvas.HTMLCanvas');
        end

        function children = getInternalComponentChildren (~, internalComponent)
            % GETINTERNALCOMPONENTCHILDREN(OBJ) 
            % Returns the children of an internal component of a UAC.
            children = [];
            if ~isa(internalComponent, "matlab.ui.control.UIaxes") && isprop(internalComponent, "Children")
                children = allchild(internalComponent);
                if numel(children) > 0
                    % Remove Axes and AnnotationPane from children list
                    children = findall(children, 'flat', '-not', 'Type', 'annotationpane', ...
                        '-and', '-not', 'Type', 'axes');
                    componentController = matlab.ui.internal.componentframework.build.DefaultsBuilder.getController(internalComponent);

                    if componentController.isChildOrderReversed()
                        children = flip(children);
                    end
                end
            end
        end

        function defaultEditCallbackFcn (obj, userComponent, publicProperties, newValue)
            for ix = 1:numel(publicProperties)
                userComponent.(publicProperties{ix}) = newValue;
            end
        end

        function inplaceEditorData = getInternalComponentInplaceEditorData(obj, component, isSerializing)
            inplaceEditorData = [];
            for i = 1:length(obj.InplaceEditors)
                if (isequal(obj.InplaceEditors(i).component, component))
                    inplaceEditorData = obj.InplaceEditors(i).EditorData;
                    if isSerializing
                        editorDataFields = fields(inplaceEditorData);
                        for i = 1:length(editorDataFields)
                            inplaceEditorData.(editorDataFields{i}) = rmfield(inplaceEditorData.(editorDataFields{i}), 'EditCallbackFcn');
                        end
                    end
                end
            end
        end

        function flatList = flattenUserComponentInplaceEditorData (obj, component)
            tempList = {};
            tempList{end+1} = obj.getInternalComponentInplaceEditorData(component, false);
            children = obj.getInternalComponentChildren(component);

            for ix = 1:numel(children)
                tempList = [tempList obj.flattenUserComponentInplaceEditorData(children(ix))];
            end

            flatList = tempList;
        end
    end

    methods(Static)
        function adapter = getJavaScriptAdapter()
            adapter = '';
        end

        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            % Ex: some.package.Component(app.UIFigure);
            classPath = class(componentHandle);
            codeSnippet = sprintf('%s(%s)', classPath, parentName);
        end

        function readOnlyProperties = listNonPublicProperties(componentHandle)
            readOnlyProperties = appdesigner.internal.componentadapterapi.VisualComponentAdapter.listNonPublicProperties(componentHandle);

            mc = metaclass(componentHandle);

            % Add user defined depedent properties without a set method as
            % read-only (see g2497938).
            %
            % Ignoring dependent properties that have both SetMethod and
            % GetMethod as empty. Inherited dependent properties from
            % ComponentContainer are implemented in C++ and so both their
            % SetMethod and GetMethod values are empty even thought they do
            % exist. We don't want to mark these as read-only which is why
            % there is the additional check for ~isempty(x.GetMethod).
            dependenWithoutSetterPrpertyIxs = find(arrayfun(@(x) x.Dependent == true && isempty(x.SetMethod) && ~isempty(x.GetMethod), mc.PropertyList));
            dependentWithoutSetterProperties = arrayfun(@(x) mc.PropertyList(x).Name, dependenWithoutSetterPrpertyIxs, 'UniformOutput', false)';

            readOnlyProperties = [readOnlyProperties dependentWithoutSetterProperties];
        end
    end

end