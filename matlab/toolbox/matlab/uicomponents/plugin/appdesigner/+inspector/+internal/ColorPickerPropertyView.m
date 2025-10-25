classdef ColorPickerPropertyView < ...
    inspector.internal.AppDesignerPropertyView & ...
    inspector.internal.mixin.FontMixin & ...
    inspector.internal.mixin.IconMixin & ...
    inspector.internal.mixin.IconAlignmentMixin
    % This class provides the property definition and groupings for
    % ColorPicker

    % Copyright 2023 The MathWorks, Inc.

    properties(SetObservable = true)
        Value matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor

        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = ColorPickerPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:ColorPickerGroup', 'Value', 'Icon');

            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, ...
                'MATLAB:ui:propertygroups:ColorGroup', ...
                'BackgroundColor');
            
            %Common properties across all components
            groups = inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);

            % Remove font and color group
            obj.GroupList(strcmp({obj.GroupList.Title}, 'MATLAB:ui:propertygroups:FontAndColorGroup')) = [];
            delete(groups.FontAndColorGroup);
            
        end
    end
end