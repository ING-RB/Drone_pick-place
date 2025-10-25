classdef TablePropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on uitable property
    % groupings as reflected in the property inspector

    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties
        Data,
        ColumnName internal.matlab.editorconverters.datatype.UITableColumnName
        ColumnWidth,
        ColumnEditable,
        ColumnFormat,
        RowName,
        ColumnRearrangeable,
        FontName,
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontUnits,
        Visible,
        Enable,
        ContextMenu,
        TooltipString,
        ForegroundColor,
        BackgroundColor,
        RowStriping,
        Position,
        InnerPosition,
        OuterPosition,
        Units,
        CellEditCallback,
        CellSelectionCallback,
        ButtonDownFcn,
        KeyPressFcn,
        KeyReleaseFcn,
        CreateFcn,
        DeleteFcn,
        Interruptible,
        BusyAction,
        BeingDeleted,
        HitTest,
        Parent,
        Children,
        HandleVisibility,
        Type,
        Tag,
        UserData
    end
    
    methods
        function this = TablePropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Table')),'','');
            g1.addProperties('Data','ColumnFormat','RowName','ColumnRearrangeable');
            g1.addEditorGroup(...
                'ColumnName', ...
                'ColumnWidth', ...
                'ColumnEditable' ...
                );
            g1.Expanded = 'true';
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g2.addProperties('FontName','FontSize');
            g2.addSubGroup('FontWeight','FontAngle','FontUnits');
            g2.Expanded = true;
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Interactivity')),'','');
            g3.addProperties('Visible','Enable','ContextMenu', 'TooltipString');
            
            %...............................................................
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g4.addProperties('ForegroundColor',...
                'BackgroundColor',...
                'RowStriping');
            
            %...............................................................
            
            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g5.addEditorGroup('OuterPosition');
            g5.addEditorGroup('InnerPosition');
            g5.addEditorGroup('Position');
            g5.addProperties('Units');
            
            %...............................................................
            
            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:Callbacks')),'','');
            g6.addProperties('CellEditCallback','CellSelectionCallback','ButtonDownFcn',...
                'KeyPressFcn', 'KeyReleaseFcn', 'CreateFcn', 'DeleteFcn');
            
            %...............................................................
            
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:CallbackExecutionControl')),'','');
            g7.addProperties('BeingDeleted','BusyAction','HitTest', 'Interruptible');
            
            %...............................................................
            
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g8.addProperties('Children','HandleVisibility','Parent');
            
            %...............................................................
            
            g9 = this.createGroup(getString(message('MATLAB:propertyinspector:Identifiers')),'','');
            g9.addProperties('Tag','Type','UserData');
        end
        
        function value = get.ColumnName(this)
            value = this.OriginalObjects.ColumnName;
        end
        
        function set.ColumnName(this, value)
            for idx = 1:length(this.OriginalObjects)
                if ~isequal(this.OriginalObjects(idx).ColumnName,value.getName)
                    this.OriginalObjects(idx).ColumnName = value.getName;
                end
            end
        end
        
        function value = get.FontWeight(this)
            value = this.OriginalObjects.FontWeight;
        end
        
        function set.FontWeight(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontWeight,value.getValue)
                        this.OriginalObjects(idx).FontWeight = value.getValue;
                    end
                end
            end
        end
        
        function value = get.FontAngle(this)
            value = this.OriginalObjects.FontAngle;
        end
        
        function set.FontAngle(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontAngle,value.getValue)
                        this.OriginalObjects(idx).FontAngle = value.getValue;
                    end
                end
            end
        end
    end
end
