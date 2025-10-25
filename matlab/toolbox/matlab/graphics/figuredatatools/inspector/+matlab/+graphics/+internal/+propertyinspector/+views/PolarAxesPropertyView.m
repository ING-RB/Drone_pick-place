classdef PolarAxesPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the polar axes's property
    % groupings as reflected in the property inspector

    % Copyright 2017-2024 The MathWorks, Inc.
    
    properties
        ALim
        ALimMode
        AlphaScale
        Alphamap
        BeingDeleted
        Box
        BusyAction
        ButtonDownFcn
        CLim
        CLimMode
        Children
        Clipping
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
        GridAlpha
        GridAlphaMode
        GridColor
        GridColorMode
        GridLineStyle
        HandleVisibility
        HitTest
        InnerPosition
        Interruptible
        Layer
        Legend
        LineStyleCyclingMethod
        LineStyleOrder
        LineStyleOrderIndex
        LineWidth
        MinorGridAlpha
        MinorGridAlphaMode
        MinorGridColor
        MinorGridColorMode
        MinorGridLineStyle
        NextPlot
        NextSeriesIndex
        OuterPosition
        Parent
        PickableParts
        Position
        PositionConstraint
        RAxis
        RAxisLocation
        RAxisLocationMode
        RColor
        RColorMode
        RDir
        RGrid
        RLim
        RLimMode
        RMinorGrid
        RMinorTick
        RTick
        RTickLabel internal.matlab.editorconverters.datatype.TicksLabelType
        RTickLabelMode
        RTickLabelRotation
        RTickLabelRotationMode
        RTickMode
        Selected
        SelectionHighlight
        SortMethod
        Subtitle
        SubtitleFontWeight internal.matlab.editorconverters.datatype.FontWeight
        Tag
        ThetaAxis
        ThetaAxisUnits
        ThetaColor
        ThetaColorMode
        ThetaDir
        ThetaGrid
        ThetaLim
        ThetaLimMode
        ThetaMinorGrid
        ThetaMinorTick
        ThetaTick
        ThetaTickLabel internal.matlab.editorconverters.datatype.TicksLabelType
        ThetaTickLabelMode
        ThetaTickMode
        TickDir
        TickDirMode
        TickLabelInterpreter
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
    end

    properties (Constant, Hidden)
        ValidThetaZeroLocs = ["left","right","top","bottom"]
    end
    
    properties (Dependent)
        ThetaZeroLocation internal.matlab.editorconverters.datatype.EditableStringEnumeration
    end

    methods
        function this = PolarAxesPropertyView(obj)
            this = this@internal.matlab.inspector.InspectorProxyMixin(obj);
                                    
            %...............................................................            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            % Moving FontWeight up as per IDR feedback
            g1.addProperties('FontName','FontSize','FontWeight');
            g1.addSubGroup('FontSizeMode','FontAngle', 'TitleFontSizeMultiplier',...
                'TitleFontWeight','SubtitleFontWeight','FontUnits');
            g1.Expanded = true;            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Ticks')),'','');
            g2.addEditorGroup('RTick','RTickLabel');
            g2.addEditorGroup('ThetaTick','ThetaTickLabel');
            g2.Expanded = true;
            
            
            g2.addSubGroup('RTickMode',...
                'RTickLabelMode',...
                'ThetaTickMode',...
                'RTickLabelRotation',...
                'RTickLabelRotationMode',...
                'ThetaTickLabelMode',...
                'RMinorTick',...
                'ThetaMinorTick',...
                'ThetaZeroLocation',...
                'TickDir',...
                'TickDirMode',...
                'TickLabelInterpreter',...
                'TickLength');
                            
            
            %...............................................................
            
           g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Rulers')),'','');
           g4.addEditorGroup('RLim');
           g4.addEditorGroup('ThetaLim');
           g4.addProperties('RLimMode',...
            'ThetaLimMode',...
            'RAxis',...
            'ThetaAxis',...
            'RAxisLocation',...
            'RAxisLocationMode',...
            'RColor',...
            'ThetaColor',...
            'RColorMode',...
            'ThetaColorMode',...
            'RDir',...
            'ThetaDir',...
            'ThetaAxisUnits');
           
            %...............................................................
            
            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Grids')),'','');
                                  
            g5.addProperties('RGrid',...
                'ThetaGrid',...
                'Layer',...
                'GridLineStyle',...
                'GridColor',...
                'GridColorMode',...
                'GridAlpha',...
                'GridAlphaMode',...
                'RMinorGrid',...
                'ThetaMinorGrid',...
                'MinorGridLineStyle',...
                'MinorGridColor',...
                'MinorGridColorMode',...
                'MinorGridAlpha',...
                'MinorGridAlphaMode');
            
            
            
            %...............................................................
            
            % Moving this group down as all its properties are read-only
            g31 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g31.addProperties('Title','TitleHorizontalAlignment','Subtitle','Legend');
            
            
            %...............................................................
            
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:MultiplePlots')),'','');
            g8.addProperties('ColorOrder');
            g8.addEditorGroup('LineStyleOrder');
            g8.addProperties('LineStyleCyclingMethod','NextSeriesIndex','NextPlot',...
                'SortMethod','ColorOrderIndex','LineStyleOrderIndex');
           
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
                'Box',...
                'Clipping');
            %...............................................................
            
                        
            g9 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');            
            g9.addEditorGroup('OuterPosition');
            g9.addEditorGroup('InnerPosition');
            g9.addEditorGroup('Position');
            
            g9.addProperties('TightInset',...
            'PositionConstraint',...
            'Units');
           
            %...............................................................
            
            g10 = this.createGroup(getString(message('MATLAB:propertyinspector:Interactivity')),'','');
            g10.addProperties('Toolbar',...
                'Visible',...
                'CurrentPoint',...
                'ContextMenu',...
                'Selected',...
                'SelectionHighlight');

            
            %...............................................................
            
            g11 = this.createGroup(getString(message('MATLAB:propertyinspector:Callbacks')),'','');
            g11.addProperties('ButtonDownFcn','CreateFcn','DeleteFcn');
            
            %...............................................................
            
            g12 = this.createGroup(getString(message('MATLAB:propertyinspector:CallbackExecutionControl')),'','');
            g12.addProperties('Interruptible','BusyAction','PickableParts','HitTest','BeingDeleted');
            
            %...............................................................
            
            g13 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g13.addProperties('Parent','Children','HandleVisibility');
                        
            
            %...............................................................
            
            g14 = this.createGroup(getString(message('MATLAB:propertyinspector:Identifiers')),'','');
            g14.addProperties('Type','Tag','UserData');
            
            
            
        end
        
        function value = get.RTickLabel(this)
            value = this.OriginalObjects.RTickLabel;
        end
        
        function value = get.ThetaTickLabel(this)
            value = this.OriginalObjects.ThetaTickLabel;
        end
        

        
        function set.RTickLabel(this, value)           
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).RTickLabel,value.getText)
                        this.OriginalObjects(idx).RTickLabel = value.getText;
                    end
                end
            end

        end
        
        function set.ThetaTickLabel(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).ThetaTickLabel,value.getText)
                        this.OriginalObjects(idx).ThetaTickLabel = value.getText;
                    end
                end
            end

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

        function set.ThetaZeroLocation(obj, inspectorValue)
            if obj.InternalPropertySet
                return
            end

            if isa(inspectorValue, "internal.matlab.editorconverters.datatype.EditableStringEnumeration")
                val = inspectorValue.Value;
                if ~ismember(val, obj.ValidThetaZeroLocs)
                    % If not a member of the valid enums, assume its a number.
                    val = str2double(inspectorValue.Value);
                    if ~isfinite(val)
                        % str2double will produce NaN for values that can't 
                        % be converted to double, e.g. "northeast". In those
                        % cases, preserve the actual value so it errors.
                        val = inspectorValue.Value;
                    end
                end
            else
                val = 'right'; % fallback to default
            end
            obj.OriginalObjects.ThetaZeroLocation = val;
        end

        function val = get.ThetaZeroLocation(obj)
            currValue = obj.OriginalObjects.ThetaZeroLocation;
            val = internal.matlab.editorconverters.datatype.EditableStringEnumeration(...
                string(currValue), obj.ValidThetaZeroLocs);
        end
    end
end
