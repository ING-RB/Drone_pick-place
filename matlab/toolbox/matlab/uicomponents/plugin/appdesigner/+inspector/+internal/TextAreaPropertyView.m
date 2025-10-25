classdef TextAreaPropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.HorizontalAlignmentMixin & ...
        inspector.internal.mixin.FontMixin

    % This class provides the property definition and groupings for
    % Textarea

    % Copyright 2015-2022 The MathWorks, Inc.

    properties(SetObservable = true)
        Value matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        WordWrap matlab.lang.OnOffSwitchState

        Placeholder char {matlab.internal.validation.mustBeVector(Placeholder)}

        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor

        Visible matlab.lang.OnOffSwitchState
        Editable matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = TextAreaPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:TextGroup',...
                'Value', 'Placeholder', 'HorizontalAlignment', 'WordWrap');

            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end
