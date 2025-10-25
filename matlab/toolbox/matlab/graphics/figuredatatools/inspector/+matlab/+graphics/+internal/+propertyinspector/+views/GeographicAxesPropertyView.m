classdef GeographicAxesPropertyView ...
        <  matlab.graphics.internal.propertyinspector.views.GeographicTickLabelFormatMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the
    % matlab.graphics.axis.GeographicAxes property groupings as reflected
    % in the property inspector.
    
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties
        ALim
        ALimMode
        AlphaScale
        Alphamap
        AxisColor
        Basemap internal.matlab.editorconverters.datatype.StringEnumeration
        BeingDeleted
        Box
        BusyAction
        ButtonDownFcn
        CLim
        CLimMode
        Children
        Color
        ColorOrder
        ColorOrderIndex
        ColorScale
        Colormap
        CreateFcn
        CurrentPoint
        DeleteFcn
        FontName
        FontSizeMode
        FontUnits
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        Grid
        GridAlpha
        GridAlphaMode
        GridColor
        GridColorMode
        GridLineStyle
        HandleVisibility
        HitTest
        InnerPosition
        Interruptible
        LabelFontSizeMultiplier
        LatitudeAxis
        LatitudeLabel
        Legend
        LineStyleCyclingMethod
        LineStyleOrder
        LineStyleOrderIndex
        LineWidth
        LongitudeAxis
        LongitudeLabel
        MapCenter internal.matlab.editorconverters.datatype.VectorData
        MapCenterMode
        NextPlot
        NextSeriesIndex
        OuterPosition
        Parent
        PickableParts
        Position
        PositionConstraint
        Scalebar
        Selected
        SelectionHighlight
        SortMethod
        Subtitle
        SubtitleFontWeight internal.matlab.editorconverters.datatype.FontWeight
        Tag
        TickDir
        TickDirMode
        % TickLabelFormat <== Inherited from GeographicTickLabelFormatMixin 
        TickLength
        TightInset
        Title
        TitleFontSizeMultiplier
        TitleFontWeight internal.matlab.editorconverters.datatype.FontWeight
        TitleHorizontalAlignment
        Toolbar
        Type
        ContextMenu
        Units
        UserData
        Visible
        ZoomLevel
        ZoomLevelMode
    end
    
    properties (SetAccess = ?internal.matlab.inspector.InspectorProxyMixin)
        LatitudeLimits
        LongitudeLimits
    end
    
    % The following properties are visible in a GeographicAxes, and
    % returned by get, but are intentionally undocumented and omitted here:
    %
    %   Clipping
    %   Interactions
    %   MinorGridAlpha
    %   MinorGridAlphaMode
    %   MinorGridColor
    %   MinorGridColorMode
    
    methods
        function this = GeographicAxesPropertyView(obj)
            this = this@matlab.graphics.internal.propertyinspector.views.GeographicTickLabelFormatMixin(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Map')),'','');
            g1.addProperties('Basemap',...
                'LatitudeLimits',...
                'LongitudeLimits');
            
            g1.addEditorGroup('MapCenter');
            g1.addSubGroup('MapCenterMode', 'ZoomLevel', 'ZoomLevelMode', 'Scalebar');
            g1.Expanded = true;
            
            %...............................................................
            
            g12 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g12.addProperties('FontName','FontSize','FontWeight');
            g12.addSubGroup('FontSizeMode','FontAngle','LabelFontSizeMultiplier',...
                'TitleFontSizeMultiplier','TitleFontWeight','SubtitleFontWeight','FontUnits');
            g12.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Ticks')),'','');
            g2.addProperties('TickDir','TickDirMode','TickLength','TickLabelFormat');
            g2.Expanded = true;
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Rulers')),'','');
            g3.addProperties('LatitudeAxis', 'LongitudeAxis','AxisColor');
            g3.Expanded = true;
            
            %...............................................................
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Grids')),'','');
            
            g4.addProperties('Grid',...
                'GridLineStyle',...
                'GridColor',...
                'GridColorMode',...
                'GridAlpha',...
                'GridAlphaMode');
            
            %...............................................................
            
            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g5.addProperties('Title','TitleHorizontalAlignment','Subtitle','LatitudeLabel','LongitudeLabel','Legend');
            
            %...............................................................
            
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:MultiplePlots')),'','');
            
            g8.addProperties('ColorOrder');
            g8.addEditorGroup('LineStyleOrder');
            g8.addProperties(...
                'LineStyleCyclingMethod',...
                'NextSeriesIndex', ...
                'NextPlot',...
                'SortMethod',...
                'ColorOrderIndex',...
                'LineStyleOrderIndex');
            
            %...............................................................
            
            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandTransparencyMaps')),'','');
            g6.addProperties('Colormap',...
                'ColorScale');
            g6.addEditorGroup('CLim');
            g6.addProperties('CLimMode',...
                'Alphamap',...
                'AlphaScale');
            g6.addEditorGroup('ALim');
            g6.addProperties('ALimMode');
            
            %...............................................................
            
            g61 = this.createGroup(getString(message('MATLAB:propertyinspector:BoxStyling')),'','');
            g61.addProperties('Color',...
                'LineWidth',...
                'Box');
            
            %...............................................................
            
            g9 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g9.addEditorGroup('OuterPosition');
            g9.addEditorGroup('InnerPosition');
            g9.addEditorGroup('Position');
            g9.addProperties('TightInset',...
                'PositionConstraint','Units');
            
            %...............................................................
            
            g10 = this.createGroup(getString(message('MATLAB:propertyinspector:Interactivity')),'','');
            g10.addProperties('Toolbar','Visible','CurrentPoint',...
                'ContextMenu','Selected','SelectionHighlight');
            
            %...............................................................
            
            g11 = this.createGroup(getString(message('MATLAB:propertyinspector:Callbacks')),'','');
            g11.addProperties('ButtonDownFcn','CreateFcn','DeleteFcn');
            
            %...............................................................
            
            g12 = this.createGroup(getString(message('MATLAB:propertyinspector:CallbackExecutionControl')),'','');
            g12.addProperties('Interruptible','BusyAction','PickableParts','BeingDeleted','HitTest');
            
            %...............................................................
            
            g13 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g13.addProperties('Parent','Children','HandleVisibility');
            
            %...............................................................
            
            g14 = this.createGroup(getString(message('MATLAB:propertyinspector:Identifiers')),'','');
            g14.addProperties('Type','Tag','UserData');
            
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
        
        function value = get.FontWeight(this)
            value = this.OriginalObjects.FontWeight;
        end
        
        function set.FontWeight(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontWeight,value.getValue)
                        this.OriginalObjects(idx).FontWeight = value.getValue;
                    end
                end
            end
        end
        
         function value = get.TitleFontWeight(this)
            value = this.OriginalObjects.TitleFontWeight;
        end
        
        function set.TitleFontWeight(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).TitleFontWeight,value.getValue)
                        this.OriginalObjects(idx).TitleFontWeight = value.getValue;
                    end
                end
            end
        end
        
         function value = get.SubtitleFontWeight(this)
            value = this.OriginalObjects.SubtitleFontWeight;
        end
        
        function set.SubtitleFontWeight(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).SubtitleFontWeight,value.getValue)
                        this.OriginalObjects(idx).SubtitleFontWeight = value.getValue;
                    end
                end
            end
        end
        
        function value = get.FontAngle(this)
            value = this.OriginalObjects.FontAngle;
        end
        
        function set.FontAngle(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontAngle,value.getValue)
                        this.OriginalObjects(idx).FontAngle = value.getValue;
                    end
                end
            end
        end
        
        function value = get.MapCenter(this)
            value = this.OriginalObjects.MapCenter;
        end

        function set.MapCenter(this, value)
            for idx = 1:length(this.OriginalObjects)
                if ~isequal(this.OriginalObjects(idx).MapCenter,value.getVector)
                    this.OriginalObjects(idx).MapCenter = value.getVector;
                end
            end
        end
    end
end
