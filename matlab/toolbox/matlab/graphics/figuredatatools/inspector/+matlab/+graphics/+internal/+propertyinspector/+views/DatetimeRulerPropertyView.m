classdef DatetimeRulerPropertyView < matlab.graphics.internal.propertyinspector.views.RulerPropertyViews
    % This class has the metadata information on the matlab.graphics.axis.decorator.DatetimeRuler property
    % groupings as reflected in the property inspector
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties
        TickLabelFormat
        TickLabelFormatMode
        SecondaryLabelFormat
        SecondaryLabelFormatMode
        ReferenceDate
    end
    
    methods
        function this = DatetimeRulerPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.RulerPropertyViews(obj);
            this.createCommonRulerGroup();
        end
    end
end
