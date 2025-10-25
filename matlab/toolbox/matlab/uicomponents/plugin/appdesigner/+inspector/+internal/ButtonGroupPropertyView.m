classdef ButtonGroupPropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.TitlePositionMixin & ...
        inspector.internal.mixin.BorderTypeMixin & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Button
    % group
    
    % Copyright 2015-2022 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Title char {matlab.internal.validation.mustBeVector(Title)}
        Scrollable matlab.lang.OnOffSwitchState
        
        ForegroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        BorderWidth (1,1) double {mustBeNonnegative}
        BorderColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor

        AutoResizeChildren matlab.lang.OnOffSwitchState
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = ButtonGroupPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:TitleGroup',...
                'Title', ...
                'TitlePosition' ...
                );

            % Create groups common to panel-like components
            inspector.internal.CommonPropertyView.createPanelPropertyGroups(obj);
                     
        end
    end
end
