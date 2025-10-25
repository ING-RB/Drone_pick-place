classdef CheckBoxTreePropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for CheckBoxTree

    % Copyright 2020 The MathWorks, Inc.

    properties(SetObservable = true)
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor

        Visible matlab.lang.OnOffSwitchState
        Editable matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState

        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = CheckBoxTreePropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end
