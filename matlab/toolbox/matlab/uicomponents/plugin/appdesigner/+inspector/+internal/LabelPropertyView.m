classdef LabelPropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.HorizontalAlignmentMixin & ...
        inspector.internal.mixin.VerticalAlignmentMixin & ...
        inspector.internal.mixin.InterpreterMixin & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Label

    % Copyright 2015-2022 The MathWorks, Inc.

    properties(SetObservable = true)
        Text matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        WordWrap matlab.lang.OnOffSwitchState

        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor

        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = LabelPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:TextGroup',...
                'Text', 'Interpreter', 'HorizontalAlignment', 'VerticalAlignment', 'WordWrap');

            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end

    end
end
