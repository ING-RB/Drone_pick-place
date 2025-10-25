classdef InternalComponentPropertyView < inspector.internal.AppDesignerPropertyView
   % This class provides the property definition and groupings for Internally Authored Custom UI Component

   % Copyright 2022 The MathWorks, Inc.
   properties(SetObservable = true)
      Visible matlab.lang.OnOffSwitchState

      BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor

      Tag char {matlab.internal.validation.mustBeVector(Tag)}

      PassthroughProps = {}  % holds properties that should not be filtered out from PropertyView object
   end

   properties(Access = protected)
      % holds properties that should be part of the component properties
      % group if the Component Author does not override the populateView method
      ComponentSpecificProps = {}
   end

   methods
      function obj = InternalComponentPropertyView(componentObject)
         obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
         obj.parseProps(componentObject);
      end

      function ComponentSpecificProps = getComponentSpecificProps(obj)
         ComponentSpecificProps = obj.ComponentSpecificProps;
      end

      function parseProps(obj, componentObject)
         % This function parses all the properties on componentObject
         % and populates PassthroughProps and ComponentSpecificProps
         allprops = properties(componentObject);

         for idx = 1:length(allprops)
            if isprop(obj, allprops{idx})
               prop = findprop(obj, allprops{idx});
               obj.PassthroughProps{end + 1} = allprops{idx};
               if strcmp(prop.DefiningClass.Name, class(obj))
                  obj.ComponentSpecificProps{end + 1} = allprops{idx};
               end
            end
         end
      end

      function canShow = canShowProp(~, prop)
         callbackType = 'matlab.graphics.datatype.Callback';
         canShow = ~strcmp(prop.Type.Name, callbackType);
      end

      function populatePropertyViewGroups(obj, componentObject)
         % This function automatically populates the PropertyView with groups
         % when the Component Author does not override the populateView method
         obj.createComponentPropertiesGroup(componentObject, obj.ComponentSpecificProps);
         inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
      end

   end
end

