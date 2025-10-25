classdef SubplotTextPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the   matlab.graphics.illustration.subplot.Text property
    % groupings as reflected in the property inspector

    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties
        BackgroundColor
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Color
        CreateFcn
        DeleteFcn
        EdgeColor
        FontAngle
        FontName
        FontSizeMode
        FontUnits
        FontWeight
        HandleVisibility
        HitTest
        HorizontalAlignment
        Interpreter
        Interruptible
        LineStyle
        LineWidth
        Margin
        Parent
        PickableParts
        Selected
        SelectionHighlight
        String
        Tag
        Type
        ContextMenu
        UserData
        Visible
        
    end
    
    methods
        function this = SubplotTextPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Text')),'','');
            g1.addProperties('String','Color','Interpreter');
            g1.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g2.addProperties('FontName','FontWeight','FontSize');
            g2.addSubGroup('FontSizeMode','FontAngle','FontUnits');
            g2.Expanded = true;
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:TextBox')),'','');
            g3.addProperties('EdgeColor','BackgroundColor');
            g3.addSubGroup('LineStyle','LineWidth','Margin','HorizontalAlignment');
            g3.Expanded = true;
            
            %...............................................................
            
            this.createCommonInspectorGroup();
        end
    end
end