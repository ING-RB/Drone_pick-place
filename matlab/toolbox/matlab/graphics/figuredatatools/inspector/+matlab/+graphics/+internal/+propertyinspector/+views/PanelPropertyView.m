classdef PanelPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on uipanel property
    % groupings as reflected in the property inspector

    % Copyright 2017-2025 The MathWorks, Inc.
    
    properties
        BackgroundColor
        BeingDeleted
        BorderType internal.matlab.editorconverters.datatype.BorderType
        BorderWidth
        BusyAction
        ButtonDownFcn
        Children
        Clipping
        CreateFcn
        DeleteFcn
        FontAngle
        FontName
        FontUnits
        FontWeight
        ForegroundColor
        Enable
        HandleVisibility
        BorderColor
        InnerPosition
        Interruptible
        OuterPosition
        Parent
        Position
        SizeChangedFcn
        Tag
        Title
        TitlePosition
        Type
        ContextMenu
        Units
        UserData
        Visible        
    end
    
    methods
        function this = PanelPropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Text')),'','');
            g1.addProperties('Title','TitlePosition');
            g1.Expanded = 'true';
            
            %...............................................................
           
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g4.addProperties('FontName','FontSize');
            g4.addSubGroup('FontWeight','FontAngle','FontUnits');
            g4.Expanded = true;
            
            %.............................................................
            
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g3.addProperties('ForegroundColor',...
                'BackgroundColor');         
            g3.addSubGroup('BorderType','BorderWidth','BorderColor');
            g3.Expanded = true;
                                    
   
            %...............................................................
            
            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Interactivity')),'','');
            g5.addProperties('Visible','Enable','Clipping','ContextMenu');
            
            %...............................................................
              
              g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
              g5.addProperties('Position',...
                  'InnerPosition',....
                  'OuterPosition',...
                  'Units');                          
            %...............................................................
            
            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:Callbacks')),'','');
            g6.addProperties('CreateFcn','DeleteFcn','ButtonDownFcn',...
                'SizeChangedFcn');
            
            %...............................................................
            
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:CallbackExecutionControl')),'','');
            g7.addProperties('BeingDeleted','BusyAction','HitTest',...
                'PickableParts','Interruptible');
            
            %...............................................................
            
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g8.addProperties('Children','HandleVisibility','Parent');
            
            %...............................................................
            
            g9 = this.createGroup(getString(message('MATLAB:propertyinspector:Identifiers')),'','');
            g9.addProperties('Tag','Type','UserData');
        end
    end
end
