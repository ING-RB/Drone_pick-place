classdef AppDesignerPropertyView < ...
        inspector.internal.AppDesignerNoPositionPropertyView & ...
        inspector.internal.mixin.PositionMixin & ...
        inspector.internal.mixin.ContextMenuMixin
    %

    % Copyright 2020 The MathWorks, Inc.

    methods

        function obj = AppDesignerPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerNoPositionPropertyView(componentObject);
        end
   
        function createComponentPropertiesGroup(obj, componentObject, propsToAdd)
           % This function is used by InternalComponentPropertyView and UserComponentPropertyView
           % to create the first group of their respective PropertyView
           % object.
           if ~isempty(propsToAdd)
              % There are properties which are not inherited.  Create a group
              % for them,  using the component name as the group name, and add
              % all of them to the group.
              componentClassName = obj.getComponentClassName(componentObject);
              g1 = obj.createGroup(componentClassName, "", "");

              for idx = 1:length(propsToAdd)
                 if ~isprop(obj, char(propsToAdd(idx)))
                    pi = obj.addprop(char(propsToAdd(idx)));
                 else
                    pi = findprop(obj, char(propsToAdd(idx)));
                 end
                 obj.(pi.Name) = componentObject.(pi.Name);

                 g1.addProperties(char(propsToAdd(idx)));
              end

              % Set this first group to be expanded by default
              g1.Expanded = true;
           end
        end

        function componentClassName = getComponentClassName(~, componentObject)
           % This function parses the fully qualified class name of the
           % component object to create the title of the first group of the
           % PropertyView object.
           componentClassName = class(componentObject);
           if contains(componentClassName, ".")
              componentClassName = reverse(extractBefore(reverse(componentClassName), "."));
           end
        end

    end
end

function app = SingletonClass

    runningApp = [];

    if(ismethod(app, 'getRunningApp'))
        runningApp = getRunningApp(app);
    end

    % rest of your code unchanged...
end
