classdef DataTipTemplateReadOnlyPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the matlab.graphics.datatip.DataTipTemplate property
    % groupings as reflected in the property inspector. This view shows up
    % when the datatiptemplate is read-only
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties  (SetAccess = ?internal.matlab.inspector.InspectorProxyMixin)
        DataTipRows
        FontAngle
        FontName
        Interpreter
    end
    
    methods
        function this = DataTipTemplateReadOnlyPropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:DataTipContent')),'','');
            g1.addProperties('DataTipRows');
            g1.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:DataTipStyling')),'','');
            g2.addProperties('FontSize','FontName','FontAngle','Interpreter');
            g2.Expanded = true;
        end
    end
end
