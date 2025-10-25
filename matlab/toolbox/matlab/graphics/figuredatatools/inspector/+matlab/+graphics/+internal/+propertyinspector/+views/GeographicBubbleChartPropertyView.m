classdef GeographicBubbleChartPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the  matlab.graphics.chart.GeographicBubbleChart property
    % groupings as reflected in the property inspector

    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties
        PositionConstraint
        Basemap internal.matlab.editorconverters.datatype.StringEnumeration
        BubbleColorList internal.matlab.editorconverters.datatype.ExtendedColor
        BubbleWidthRange internal.matlab.editorconverters.datatype.VectorData
        ColorData
        ColorLegendTitle
        ColorVariable
        FontName
        GridVisible
        HandleVisibility
        InnerPosition
        LatitudeData
        LatitudeVariable
        LegendVisible
        LongitudeData
        LongitudeVariable
        MapCenter internal.matlab.editorconverters.datatype.VectorData
        MapLayout
        OuterPosition
        Parent
        Position
        SizeData
        SizeLegendTitle
        SizeLimits internal.matlab.editorconverters.datatype.VectorData
        SizeVariable
        ScalebarVisible
        SourceTable
        Title
        Units
        Visible
        ZoomLevel
    end
    
    properties (SetAccess = ?internal.matlab.inspector.InspectorProxyMixin)
        LatitudeLimits
        LongitudeLimits
    end    
    
    methods
        function this = GeographicBubbleChartPropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:BubbleLocation')),'','');
            g1.addProperties('LatitudeVariable','LatitudeData',...
                'LongitudeVariable','LongitudeData');
            
            g1.Expanded = true;
            
            
            %...............................................................
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:BubbleSize')),'','');
            g3.addEditorGroup('BubbleWidthRange');
            g3.addEditorGroup('SizeLimits');            
            g3.addProperties('SizeVariable','SizeData');
            g3.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:BubbleColor')),'','');
            g2.addProperties('BubbleColorList','ColorVariable','ColorData');
            
            g2.Expanded = true;
            
            %...............................................................
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g4.addProperties('Title',...
                'ColorLegendTitle',...
                'SizeLegendTitle',...
                'LegendVisible');            
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g3.addProperties('FontName',...
                'FontSize');
                        
            %...............................................................            
            
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:Map')),'','');
            g7.addProperties('GridVisible',...
                'Basemap',...
                'MapLayout',...
                'ZoomLevel',...
                'LatitudeLimits',...
                'LongitudeLimits','ScalebarVisible',...
                'SourceTable');
            g7.addEditorGroup('MapCenter');
            %...............................................................
            
            g10 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g10.addEditorGroup('OuterPosition');
            g10.addEditorGroup('InnerPosition');
            g10.addEditorGroup('Position');
            g10.addProperties('PositionConstraint','Units',...
                'Visible');
            
            %...............................................................
            
            g9 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g9.addProperties('Parent','HandleVisibility');            

        end
        
        % This requires the standard conversion between text and the object's inspector data type
        function set.Basemap(this, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                if ~isequal(this.OriginalObjects.Basemap, inspectorValue.Value)
                    % Extra check to make sure we're not overriding a
                    % TileSetMetadata object's value
                    this.OriginalObjects.Basemap = inspectorValue.Value;
                end
            else
                this.OriginalObjects.Basemap = char(inspectorValue);
            end
        end

        function value = get.Basemap(this)
            value = internal.matlab.editorconverters.datatype.StringEnumeration(...
                this.OriginalObjects.Basemap, ...
                matlab.graphics.chart.internal.maps.basemapNames);
        end

        
         function value = get.BubbleWidthRange(this)
            value = this.OriginalObjects.BubbleWidthRange;
         end

         function value = get.MapCenter(this)
            value = this.OriginalObjects.MapCenter;
         end 
         
         function value = get.SizeLimits(this)
            value = this.OriginalObjects.SizeLimits;
         end          
        
        function set.BubbleWidthRange(this, value)           
            for idx = 1:length(this.OriginalObjects)
                if ~isequal(this.OriginalObjects(idx).BubbleWidthRange,value.getVector)
                    this.OriginalObjects(idx).BubbleWidthRange = value.getVector;
                end
            end       
        end
        
        function set.MapCenter(this, value)           
            for idx = 1:length(this.OriginalObjects)
                if ~isequal(this.OriginalObjects(idx).MapCenter,value.getVector)
                    this.OriginalObjects(idx).MapCenter = value.getVector;
                end
            end       
        end
        
        function set.SizeLimits(this, value)           
            for idx = 1:length(this.OriginalObjects)
                if ~isequal(this.OriginalObjects(idx).SizeLimits,value.getVector)
                    this.OriginalObjects(idx).SizeLimits = value.getVector;
                end
            end       
        end

        function value = get.BubbleColorList(this)
            value = this.OriginalObjects.BubbleColorList;
        end
        
        function set.BubbleColorList(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).BubbleColorList,value.getColor)
                        this.OriginalObjects(idx).BubbleColorList = value.getColor;
                    end
                end
            end
        end
    end
end
