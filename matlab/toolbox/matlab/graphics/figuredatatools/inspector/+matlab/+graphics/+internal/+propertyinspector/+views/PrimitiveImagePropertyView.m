classdef PrimitiveImagePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews
    % This class has the metadata information on the matlab.graphics.primitive.Image property
    % groupings as reflected in the property inspector

    % Copyright 2017-2022 The MathWorks, Inc.
    
    properties
        AlphaData
        AlphaDataMapping
        BeingDeleted
        BusyAction
        ButtonDownFcn
        CData
        CDataMapping
        Children
        Clipping
        CreateFcn
        DeleteFcn
        HandleVisibility
        HitTest
        Interpolation
        MaxRenderedResolution internal.matlab.editorconverters.datatype.NonQuotedTextType
        Interruptible
        Parent
        PickableParts
        Selected
        SelectionHighlight
        Tag
        Type
        ContextMenu
        UserData
        Visible
        XData
        YData
        DataTipTemplate
    end
    
    methods
        function this = PrimitiveImagePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandTransparency')),'','');
            g1.addProperties('CData','CDataMapping','AlphaData','AlphaDataMapping','Interpolation','MaxRenderedResolution');
            g1.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g2.addProperties('XData','YData');
            g2.Expanded = true;

            %...............................................................
           
            this.createCommonInspectorGroup();
            
        end
    end
end