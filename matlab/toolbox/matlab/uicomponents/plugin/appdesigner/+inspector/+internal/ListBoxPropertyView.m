classdef ListBoxPropertyView < inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Listbox
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        % Value allows multiple inputs (based on multi select)
        Value internal.matlab.editorconverters.datatype.MultipleItemsValue
        
        Items internal.matlab.editorconverters.datatype.MoreThanZeroItems
        ItemsData internal.matlab.editorconverters.datatype.ItemsValue
        Multiselect matlab.lang.OnOffSwitchState
        
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = ListBoxPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            titleCatalogId = 'MATLAB:ui:propertygroups:ListBoxGroup';
            inspector.internal.CommonPropertyView.createOptionsGroup(obj, titleCatalogId);
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
        
        function val = get.Value(obj)
            val = obj.OriginalObjects.Value;
        end
        
        function set.Value(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).Value, val.getItems)
                    obj.OriginalObjects.Value = val.getItems;
                end
            end
        end
        
        function val = get.Items(obj)
            val = obj.OriginalObjects.Items;
        end
        
        function set.Items(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).Items, val.getItems)
                    obj.OriginalObjects.Items = val.getItems;
                end
            end
        end

        function val = get.ItemsData(obj)
            val = obj.OriginalObjects.ItemsData;
        end
        
        function set.ItemsData(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).ItemsData, val.getItems)
                    obj.OriginalObjects.ItemsData = val.getItems;
                end
            end
        end
    end
end
