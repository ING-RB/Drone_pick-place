classdef DatePickerPropertyView < inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for
    % DatePicker

    % Copyright 2018-2022 The MathWorks, Inc.

    properties(SetObservable = true)
        Value internal.matlab.editorconverters.datatype.Date
        DisplayFormat internal.matlab.editorconverters.datatype.DateDisplayFormat
        Limits internal.matlab.editorconverters.datatype.DateLimits
        DisabledDaysOfWeek internal.matlab.editorconverters.datatype.DateDisabledDaysOfWeek
        DisabledDates internal.matlab.editorconverters.datatype.DateDisabledDates

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
        function obj = DatePickerPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            % Create DatePicker specific property group
            group = obj.createGroup( ...
                'MATLAB:ui:propertygroups:DatePickerGroup', ...
                'MATLAB:ui:propertygroups:DatePickerGroup', ...
                '');

            group.addProperties('Value');
            group.addProperties('Placeholder');
            group.addEditorGroup('Limits');
            group.addProperties('DisplayFormat');
            group.addEditorGroup('DisabledDates');
            group.addEditorGroup('DisabledDaysOfWeek');
            group.Expanded = true;

            % Create common property group
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end

        function val = get.Value(obj)
            val = obj.OriginalObjects.Value;
        end

        function set.Value(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).Value, val.getValue)
                    obj.OriginalObjects.Value = val.getValue;
                end
            end
        end

        function val = get.DisplayFormat(obj)
            val = obj.OriginalObjects.DisplayFormat;
        end

        function set.DisplayFormat(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).DisplayFormat, val.getDisplayFormat)
                    obj.OriginalObjects.DisplayFormat = val.getDisplayFormat;
                end
            end
        end

        function val = get.Limits(obj)
            val = obj.OriginalObjects.Limits;
        end

        function set.Limits(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).Limits, val.getLimits)
                    obj.OriginalObjects.Limits = val.getLimits;
                end
            end
        end

        function val = get.DisabledDaysOfWeek(obj)
            val = obj.OriginalObjects.DisabledDaysOfWeek;
        end

        function set.DisabledDaysOfWeek(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).DisabledDaysOfWeek, val.getDisabledDaysOfWeek)
                    obj.OriginalObjects.DisabledDaysOfWeek = val.getDisabledDaysOfWeek;
                end
            end
        end

        function val = get.DisabledDates(obj)
            val = obj.OriginalObjects.DisabledDates;
        end

        function set.DisabledDates(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).DisabledDates, val.getDisabledDates)
                    obj.OriginalObjects.DisabledDates = val.getDisabledDates;
                end
            end
        end
    end
end
