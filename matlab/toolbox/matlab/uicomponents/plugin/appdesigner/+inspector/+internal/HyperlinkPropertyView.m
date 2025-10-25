classdef HyperlinkPropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.HorizontalAlignmentMixin & ...
        inspector.internal.mixin.VerticalAlignmentMixin & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Hyperlink
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(SetObservable = true)
        URL internal.matlab.editorconverters.datatype.Hyperlink
        Text matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        WordWrap matlab.lang.OnOffSwitchState
        
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        VisitedColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = HyperlinkPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:HyperlinkGroup',...
                'URL', 'Text', 'HorizontalAlignment', 'VerticalAlignment', 'WordWrap');

            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
                
            % Add VisitedColor property to the FontAndColorGroup,
            % VisitedColor property is uniquely supported by the Hyperlink
            % component
            obj.GroupList(strcmp({obj.GroupList.Title}, 'MATLAB:ui:propertygroups:FontAndColorGroup')) = ...
                inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:FontAndColorGroup', ...
                    'VisitedColor');

            % Move VisitedColor from last in the list to first in the list,
            % in order to following the property order in the documentation
            propertyList = obj.GroupList(strcmp({obj.GroupList.Title}, 'MATLAB:ui:propertygroups:FontAndColorGroup')).PropertyList;

            propertyList(ismember(propertyList, 'VisitedColor')) = [];

            obj.GroupList(strcmp({obj.GroupList.Title}, 'MATLAB:ui:propertygroups:FontAndColorGroup')).PropertyList = [propertyList(1:end-1), 'VisitedColor', propertyList(end)];
        end
        
        function val = get.URL(obj)
            val = obj.OriginalObjects.URL;
        end
        
        function set.URL(obj, url)
            obj.OriginalObjects.URL = url.getURL();
        end            
    end
end
