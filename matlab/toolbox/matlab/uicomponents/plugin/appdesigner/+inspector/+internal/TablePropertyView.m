classdef TablePropertyView <  ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.TableSelectionTypeMixin & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Table

    % Copyright 2016-2022 The MathWorks, Inc.

    properties(SetObservable = true)
        RowStriping matlab.lang.OnOffSwitchState
        ForegroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor
        ColumnName internal.matlab.editorconverters.datatype.UITableColumnName
        ColumnWidth matlab.internal.datatype.matlab.ui.datatype.TableColumnWidth
        ColumnEditable matlab.internal.datatype.matlab.ui.datatype.TableColumnEditable
        ColumnSortable matlab.internal.datatype.matlab.ui.datatype.TableColumnEditable

        ColumnRearrangeable matlab.lang.OnOffSwitchState
        RowName matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Visible matlab.lang.OnOffSwitchState
        % Enable is technically a 'matlab.ui.datatype.Enable', which
        % supports the deprecated value 'inactive'
        %
        % To avoid having that appear as a combo box, add an explicit data
        % type here so that it appears as a check box
        Enable matlab.lang.OnOffSwitchState
        Multiselect matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = TablePropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            group = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj,'MATLAB:ui:propertygroups:TableGroup');
            group.addEditorGroup('ColumnName', 'ColumnWidth', 'ColumnEditable', 'ColumnSortable');
            group.addProperties('ColumnRearrangeable');
            group.addProperties('RowName');

            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:FontGroup', ...
                'FontName', ...
                'FontSize',...
                'FontWeight', ...
                'FontAngle'...
                );

            inspector.internal.CommonPropertyView.createInteractivityGroup(obj);

            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:ColorAndStylingGroup', ...
                'ForegroundColor',...
                'BackgroundColor', ...
                'RowStriping' ...
                );

            % Common properties across all components
            inspector.internal.CommonPropertyView.createPositionGroup(obj);
            inspector.internal.CommonPropertyView.createCallbackExecutionControlGroup(obj);
            inspector.internal.CommonPropertyView.createParentChildGroup(obj);
            inspector.internal.CommonPropertyView.createIdentifiersGroup(obj);
        end

        % ColumnName
        function val = get.ColumnName(obj)
            val = obj.OriginalObjects.ColumnName;
        end

        function set.ColumnName(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).ColumnName, val.getName)
                    obj.OriginalObjects.ColumnName = val.getName;
                end
            end
        end
    end
end
