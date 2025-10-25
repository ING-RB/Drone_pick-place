classdef DataTipPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.DataspaceMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the matlab.graphics.datatip.DataTip property
    % groupings as reflected in the property inspector. 

    % Copyright 2019-2021 The MathWorks, Inc.
    
    properties
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Content
        CreateFcn
        DataIndex
        DeleteFcn
        HandleVisibility
        HitTest
        Interruptible
        Location matlab.graphics.datatip.internal.DataTipLocationEnum
        LocationMode
        Parent
        PickableParts
        Selected
        SelectionHighlight
        SnapToDataVertex
        Tag
        Type
        UserData
        InterpolationFactor        
        Visible
        FontName
        FontAngle
        Interpreter
    end
    
    properties(Hidden)
        % This is done to hide UIContextMenu from the property view and not
        % allow user change it.
        UIContextMenu
        ContextMenu
        ValueChangedFcn
    end
    
    methods
        function this = DataTipPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g1.addProperties('DataIndex');
            allPolar = numel(findobj(obj,'-property','R')) == numel(obj);
            allCartesian = numel(findobj(obj,'-property','X','-and','-not','-property','R','-and','-not', '-property','Latitude')) == numel(obj);
            allGeo = numel(findobj(obj,'-property','Latitude')) == numel(obj);
            
            if allPolar
                props = {'R','Theta'};
                this.addDataTipDynamicProperties(obj,props);
                g1.addProperties('R','Theta');
            elseif allGeo
                props = {'Latitude','Longitude'};
                this.addDataTipDynamicProperties(obj,props);
                g1.addProperties('Latitude','Longitude');
            elseif allCartesian
                props = {'X','Y','Z'};
                this.addDataTipDynamicProperties(obj,props);
                g1.addProperties('X','Y','Z');
            end
            g1.addSubGroup('Location','LocationMode','SnapToDataVertex','InterpolationFactor');
            g1.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:DataTipStyling')),'','');
            g2.addProperties('FontSize','FontName','Interpreter');
            g2.addSubGroup('FontAngle','Content');
            g2.Expanded = true;
            
            this.createCommonInspectorGroup();
        end
    end
end