classdef EditFieldPropertyView < inspector.internal.AppDesignerPropertyView  & ...
        inspector.internal.mixin.HorizontalAlignmentMixin & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Edit
    % field

    % Copyright 2015-2022 The MathWorks, Inc.

    properties(SetObservable = true)
        Value char {matlab.internal.validation.mustBeVector(Value)}

        Placeholder char {matlab.internal.validation.mustBeVector(Placeholder)}

        CharacterLimits matlab.internal.datatype.matlab.graphics.datatype.LimitsWithInfs
        InputType inspector.internal.datatype.TextInputType

        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor

        Visible matlab.lang.OnOffSwitchState
        Editable matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = EditFieldPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            group = obj.createGroup( ...
                'MATLAB:ui:propertygroups:TextGroup', ...
                'MATLAB:ui:propertygroups:TextGroup', ...
                '');

            group.addProperties('Value');
            group.addEditorGroup('CharacterLimits');
            group.addProperties('InputType');
            group.addProperties('Placeholder');
            group.addProperties('HorizontalAlignment');
            group.Expanded = true;

            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end
