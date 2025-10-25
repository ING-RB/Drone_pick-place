classdef DataTipTemplatePropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the matlab.graphics.datatip.DataTipTemplate property
    % groupings as reflected in the property inspector. 

    % Copyright 2018-2021s The MathWorks, Inc.
    
    properties
        DataTipRows
        FontAngle
        FontName
        Interpreter
    end
    
    methods
        function this = DataTipTemplatePropertyView(obj)
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
        
        function value = get.DataTipRows(this)
            value = this.OriginalObjects.DataTipRows;
        end
        
        function set.DataTipRows(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    this.OriginalObjects(idx).DataTipRows = value;
                end
            end
        end
    end
end