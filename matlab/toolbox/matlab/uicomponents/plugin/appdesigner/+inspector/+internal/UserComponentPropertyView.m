classdef UserComponentPropertyView < inspector.internal.AppDesignerPropertyView
    % This class provides the property definition and groupings for User Authored Component

    % Copyright 2020 The MathWorks, Inc.
    properties(SetObservable = true)
        Visible matlab.lang.OnOffSwitchState

        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = UserComponentPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            inheritedProps = properties('matlab.ui.componentcontainer.ComponentContainer');

            allprops = properties(componentObject);

            propsToAdd = [];

            for idx = 1:length(allprops)
                if ~any(strcmp(inheritedProps, allprops{idx}))
                    prop = findprop(componentObject, allprops{idx});
                    if obj.canShowProp(componentObject, prop)
                        propsToAdd{end + 1} = allprops{idx};
                    end
                end
            end

            obj.createComponentPropertiesGroup(componentObject, propsToAdd);

            import inspector.internal.CommonPropertyView;

            g2 = CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:ColorGroup', 'BackgroundColor');

            % Set the 2nd group to be expanded if the first group doesn't
            % have any properties.
            if isempty(propsToAdd)
                g2.Expanded = true;
            end

            obj.createInteractivityGroup();
			CommonPropertyView.createPositionGroup(obj);
			CommonPropertyView.createCallbackExecutionControlGroup(obj);
			CommonPropertyView.createParentChildGroup(obj);
            CommonPropertyView.createIdentifiersGroup(obj);
        end

        function canShowProp = canShowProp(~, componentObject, prop)
            % canShowProp(obj, componentObject, prop)
            % Determines if a property needs to be shown in proeprty inspector.
            % A property is shown only if
            % 1) It has specific type mentioned that has a supporting editor type or
            % 2) It has a default value that has a supporting editor type.
            import internal.matlab.datatoolsservices.FormatDataUtils
            callbackType = 'matlab.graphics.datatype.Callback';

            % Show the property if it has non empty default value or
            % a specific class type.
            canShowProp = (prop.HasDefault && ~isempty(prop.DefaultValue)) || ~strcmp(prop.Type.Name, 'any');

            % Don't show the property if it is of callback type.
            canShowProp = canShowProp && ~strcmp(prop.Type.Name, callbackType);

            % If a property is of type Enum, then show the property only if
            % it is assigned with a non empty default value. If an empty value/no value is
            % assigned to an Enum property, it will not be shown in inspector.
            classType = FormatDataUtils.getClassString(componentObject.(prop.Name), false, true);
            isCatOrEnum = ...
                internal.matlab.editorconverters.ComboBoxEditor.isCategoricalOrEnum(...
                classType, prop.Type, componentObject.(prop.Name));

            if isCatOrEnum
                canShowProp = canShowProp && prop.HasDefault && ~isempty(prop.DefaultValue);
            end

            if ~isempty(componentObject.(prop.Name))
                % Don't show the multi dimensional cell arrays. Only show n * 1 and 1 * n cell arrays.
                % App Designer doesn't have proper property editor to edit multi-dimensional cell arrays.
                if strcmp(classType, 'cell')
                    canShowProp = canShowProp && isvector(componentObject.(prop.Name));
                end

                % Don't show string arrays.
                % App Designer doesn't have server side code gen logic to accomodate string arrays.
                if strcmp(classType, 'string')
                    canShowProp = canShowProp && isscalar(componentObject.(prop.Name));
                end

                % Don't show n * 1 char arrays.
                % App Designer doesn't have server side code gen logic to accomodate n * 1 char arrays.
                if strcmp(classType, 'char')
                    canShowProp = canShowProp && isrow(componentObject.(prop.Name));
                end
            end
        end

        function createComponentPropertiesGroup(obj, componentObject, propsToAdd)
            if ~isempty(propsToAdd)
                % There are properties which are not inherited.  Create a group
                % for them,  using the component name as the group name, and add
                % all of them to the group.
                classname = class(componentObject);

                if contains(classname, ".")
                    classname = reverse(extractBefore(reverse(classname), "."));
                end

                g1 = obj.createGroup(classname, "", "");

                for idx = 1:length(propsToAdd)
                    pi = obj.addprop(char(propsToAdd(idx)));

                    obj.(pi.Name) = componentObject.(pi.Name);

                    g1.addProperties(char(propsToAdd(idx)));
                end

                % Set this first group to be expanded by default
                g1.Expanded = true;
            end
        end

        function group = createInteractivityGroup(obj)
			group = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:InteractivityGroup');

			group.addProperties('Visible');
			group.addProperties('ContextMenu');

			group.Expanded = false;
		end
    end
end
