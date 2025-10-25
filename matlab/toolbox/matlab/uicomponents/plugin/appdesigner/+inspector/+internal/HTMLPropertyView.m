classdef HTMLPropertyView < ...
        inspector.internal.AppDesignerPropertyView
    
    % This class provides the property definition and groupings for HTML
    % component
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        
        HTMLSource internal.matlab.editorconverters.datatype.NonDelimitedMultlineText
        
        % Data not visible until officially supported by component
        %
        Data (1,1) double
        
        Visible matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = HTMLPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:HTMLGroup',...
                'HTMLSource',...
                ... % Data removed until officially supported by component
                'Data' ...
                );
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
                
        function val = get.HTMLSource(obj)
            val = obj.OriginalObjects.HTMLSource;
        end
        
        function set.HTMLSource(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).HTMLSource, char(val.getValue))
                    obj.OriginalObjects.HTMLSource = char(val.getValue);
                end
            end
        end
    end
end
