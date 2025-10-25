classdef NumericRulerPropertyView < matlab.graphics.internal.propertyinspector.views.RulerPropertyViews
    % This class has the metadata information on the matlab.graphics.axis.decorator.NumericRuler property
    % groupings as reflected in the property inspector
    
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties
        Exponent
        ExponentMode
        TickLabelFormat
    end
    
    methods
        function this = NumericRulerPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.RulerPropertyViews(obj);
            this.createCommonRulerGroup();
        end
    end
end
