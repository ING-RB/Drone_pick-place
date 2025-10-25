classdef ImagePropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.ImageHorizontalAlignmentMixin & ...
        inspector.internal.mixin.ImageVerticalAlignmentMixin & ...
        inspector.internal.mixin.ScaleMethodMixin
    % This class provides the property definition and groupings for
    % Image Component
    
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties(SetObservable = true)
        ImageSource internal.matlab.editorconverters.datatype.FullPath
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        URL internal.matlab.editorconverters.datatype.Hyperlink
        AltText char {matlab.internal.validation.mustBeVector(AltText)}
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = ImagePropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, ...
                'MATLAB:ui:propertygroups:ImageGroup', ...
                'ImageSource','HorizontalAlignment', 'VerticalAlignment',...
                'ScaleMethod');
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, ...
                'MATLAB:ui:propertygroups:ColorGroup', ...
                'BackgroundColor');

            % Add URL to the Interactivity group
            obj.GroupList(strcmp({obj.GroupList.Title}, 'MATLAB:ui:propertygroups:InteractivityGroup')) = ...
                inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, ...
                'MATLAB:ui:propertygroups:InteractivityGroup', ...
                    'URL');

            obj.GroupList(strcmp({obj.GroupList.Title}, 'MATLAB:ui:propertygroups:InteractivityGroup')) = ...
                inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, ...
                'MATLAB:ui:propertygroups:InteractivityGroup', ...
                    'AltText');
            
            % Common properties across all components
            groups = inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
            
            % Remove font and color group.  This group is uniquely managed by
            % Image because there are no font options available to the user.
            obj.GroupList(strcmp({obj.GroupList.Title}, 'MATLAB:ui:propertygroups:FontAndColorGroup')) = [];
            delete(groups.FontAndColorGroup);
        end
        
        function val = get.ImageSource(obj)
            val = internal.matlab.editorconverters.datatype.FullPath(obj.OriginalObjects.ImageSource);
        end
        
        function set.ImageSource(obj, filePath)
            obj.OriginalObjects.ImageSource = filePath.getPath();
        end
    end
end
