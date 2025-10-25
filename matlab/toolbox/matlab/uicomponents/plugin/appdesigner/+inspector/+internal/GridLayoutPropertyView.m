classdef GridLayoutPropertyView < ...
        inspector.internal.AppDesignerNoPositionPropertyView & ...
        inspector.internal.mixin.ContextMenuMixin
    
    % This class provides the property definition and groupings for GridLayout
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        ColumnWidth
        RowHeight
        Scrollable matlab.lang.OnOffSwitchState
        
        ColumnSpacing double
        RowSpacing double
        Padding
        
        Visible matlab.lang.OnOffSwitchState       
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = GridLayoutPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerNoPositionPropertyView(componentObject);
            
            group = obj.createGroup( ...
                'MATLAB:ui:propertygroups:GridLayoutGroup', ...
                'MATLAB:ui:propertygroups:GridLayoutGroup', ...
                '' ...
                );
            
            group.addProperties('ColumnWidth');
            group.addProperties('RowHeight');
            group.addSubGroup(...
                'ColumnSpacing', ...
                'RowSpacing', ...
                'Padding'...
                );
            
            group.Expanded = true;
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj, false);
        end
    end
end
