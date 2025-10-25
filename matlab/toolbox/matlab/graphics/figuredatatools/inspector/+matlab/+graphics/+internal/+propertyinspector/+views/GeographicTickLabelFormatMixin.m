classdef GeographicTickLabelFormatMixin <  internal.matlab.inspector.InspectorProxyMixin
% Implement dropdown for TickLabelFormat enumerated string values in the
% GeographicAxesPropertyView and GeographicRulerPropertyView classes.

% Copyright 2019 The MathWorks, Inc.
    
    properties
        TickLabelFormat internal.matlab.editorconverters.datatype.StringEnumeration
    end
    
    
    properties (Access = protected, Constant)
        TickLabelFormatOptions = {'dd', 'dm', 'dms', '-dd', '-dm', '-dms'};
    end
    
    
    methods
        function this = GeographicTickLabelFormatMixin(obj)
            this = this@internal.matlab.inspector.InspectorProxyMixin(obj);
            if ~isempty(obj)
                this.TickLabelFormat = internal.matlab.editorconverters.datatype.StringEnumeration(obj.TickLabelFormat, this.TickLabelFormatOptions);
            end
        end
        
        
        function set.TickLabelFormat(this, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                this.OriginalObjects.TickLabelFormat = inspectorValue.Value;
            else
                this.OriginalObjects.TickLabelFormat = char(inspectorValue);
            end
        end
        
        
        function value = get.TickLabelFormat(this)
            value = internal.matlab.editorconverters.datatype.StringEnumeration(this.OriginalObjects.TickLabelFormat, this.TickLabelFormatOptions);
        end
    end
end
