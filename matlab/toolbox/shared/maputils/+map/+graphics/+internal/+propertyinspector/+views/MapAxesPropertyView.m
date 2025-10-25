classdef MapAxesPropertyView  ...
        < matlab.graphics.internal.propertyinspector.views.GeographicTickLabelFormatMixin ...
        & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the
    % map.graphics.axis.MapAxes property groupings as reflected in the
    % property inspector

    % Copyright 2022-2023 The MathWorks, Inc.

    % The following properties are visible in a MapAxes, and
    % returned by get, but are intentionally omitted here:
    %
    %   Clipping
    %   Interactions
    %   Layout

    properties
        ProjectedCRS
        CartographicLatitudeLimits internal.matlab.editorconverters.datatype.VectorData
        CartographicLongitudeLimits internal.matlab.editorconverters.datatype.VectorData
        FontColor
        OutlineColor
        GraticuleColor
        GraticuleAlpha
        GraticuleLineStyle
        GraticuleLineWidth
        GraticuleLineWidthMode
        CurrentPoint
        Scalebar
        MapLayout
        CLim
        CLimMode
        ALim
        ALimMode
        Colormap
        Alphamap
        ColorScale
        AlphaScale
        FontName
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        LineWidth
        Color
        Title
        TitleHorizontalAlignment
        Subtitle
        TickDir
        % TickLabelFormat <== Inherited from GeographicTickLabelFormatMixin
        Units
        Position
        InnerPosition
        OuterPosition
        PositionConstraint
        TightInset
        ColorOrder
        ColorOrderIndex
        LineStyleOrder
        LineStyleOrderIndex
        LineStyleCyclingMethod
        NextSeriesIndex
        FontUnits
        % FontSize <== Inherited from FontSizeMixin
        FontSizeMode
        TitleFontWeight internal.matlab.editorconverters.datatype.FontWeight
        SubtitleFontWeight internal.matlab.editorconverters.datatype.FontWeight
        TitleFontSizeMultiplier
        SortMethod
        NextPlot
        Toolbar
        Children
        Parent
        Visible
        HandleVisibility
        ButtonDownFcn
        ContextMenu
        BusyAction
        BeingDeleted
        Interruptible
        CreateFcn
        DeleteFcn
        Type
        Tag
        UserData
        Selected
        SelectionHighlight
        HitTest
        PickableParts
        Legend
    end

    methods
        function obj = MapAxesPropertyView(hObj)
            obj@matlab.graphics.internal.propertyinspector.views.GeographicTickLabelFormatMixin(hObj);

            %...............................................................

            g1 = obj.createGroup(getString(message('MATLAB:propertyinspector:Map')),'','');
            g1.addProperties('ProjectedCRS','Scalebar');
            g1.Expanded = true;

            %...............................................................

            g2 = obj.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g2.addProperties('FontColor','FontName','FontSize','FontWeight');
            g2.addSubGroup('FontSizeMode','FontAngle',...
                'TitleFontSizeMultiplier','TitleFontWeight','SubtitleFontWeight','FontUnits');
            g2.Expanded = true;

            %...............................................................

            g3 = obj.createGroup(getString(message('MATLAB:propertyinspector:Ticks')),'','');
            g3.addProperties('TickDir','TickLabelFormat');
            g3.Expanded = true;

            %...............................................................

            g4 = obj.createGroup(getString(message('maputils:propertyinspector:Graticule')),'','');
            g4.addProperties('GraticuleColor','GraticuleLineStyle','GraticuleLineWidth');
            g4.addSubGroup('GraticuleLineWidthMode','GraticuleAlpha');
            g4.Expanded = true;

            %...............................................................

            g5 = obj.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g5.addProperties('Title','Subtitle','TitleHorizontalAlignment','Legend');

            %...............................................................

            g6 = obj.createGroup(getString(message('MATLAB:propertyinspector:MultiplePlots')),'','');

            g6.addProperties('ColorOrder');
            g6.addEditorGroup('LineStyleOrder');
            g6.addProperties(...
                'LineStyleCyclingMethod',...
                'NextSeriesIndex', ...
                'NextPlot',...
                'SortMethod',...
                'ColorOrderIndex',...
                'LineStyleOrderIndex');

            %...............................................................

            g7 = obj.createGroup(getString(message('MATLAB:propertyinspector:ColorandTransparencyMaps')),'','');
            g7.addProperties('Colormap',...
                'ColorScale');
            g7.addEditorGroup('CLim');
            g7.addProperties('CLimMode',...
                'Alphamap',...
                'AlphaScale');
            g7.addEditorGroup('ALim');
            g7.addProperties('ALimMode');

            %...............................................................

            g8 = obj.createGroup(getString(message('maputils:propertyinspector:MapStyling')),'','');
            g8.addProperties('Color','OutlineColor','LineWidth','MapLayout');
            g8.addEditorGroup('CartographicLatitudeLimits');
            g8.addEditorGroup('CartographicLongitudeLimits');

            %...............................................................

            g9 = obj.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g9.addEditorGroup('OuterPosition');
            g9.addEditorGroup('InnerPosition');
            g9.addEditorGroup('Position');
            g9.addProperties('TightInset',...
                'PositionConstraint','Units');

            %...............................................................

            g10 = obj.createGroup(getString(message('MATLAB:propertyinspector:Interactivity')),'','');
            g10.addProperties('Toolbar','Visible','CurrentPoint',...
                'ContextMenu','Selected','SelectionHighlight');

            %...............................................................

            g11 = obj.createGroup(getString(message('MATLAB:propertyinspector:Callbacks')),'','');
            g11.addProperties('ButtonDownFcn','CreateFcn','DeleteFcn');

            %...............................................................

            g12 = obj.createGroup(getString(message('MATLAB:propertyinspector:CallbackExecutionControl')),'','');
            g12.addProperties('Interruptible','BusyAction','PickableParts','HitTest','BeingDeleted');

            %...............................................................

            g13 = obj.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g13.addProperties('Parent','Children','HandleVisibility');

            %...............................................................

            g14 = obj.createGroup(getString(message('MATLAB:propertyinspector:Identifiers')),'','');
            g14.addProperties('Type','Tag','UserData');
        end

        function value = get.CartographicLatitudeLimits(obj)
            value = obj.OriginalObjects.CartographicLatitudeLimits;
        end

        function set.CartographicLatitudeLimits(obj, value)
            if ~obj.InternalPropertySet
                for idx = 1:length(obj.OriginalObjects)
                    if ~isequal(obj.OriginalObjects(idx).CartographicLatitudeLimits,value.getVector)
                        obj.OriginalObjects(idx).CartographicLatitudeLimits = value.getVector;
                    end
                end
            end
        end

        function value = get.CartographicLongitudeLimits(obj)
            value = obj.OriginalObjects.CartographicLongitudeLimits;
        end

        function set.CartographicLongitudeLimits(obj, value)
            if ~obj.InternalPropertySet
                for idx = 1:length(obj.OriginalObjects)
                    if ~isequal(obj.OriginalObjects(idx).CartographicLongitudeLimits,value.getVector)
                        obj.OriginalObjects(idx).CartographicLongitudeLimits = value.getVector;
                    end
                end
            end
        end

        function value = get.FontWeight(obj)
            value = obj.OriginalObjects.FontWeight;
        end

        function set.FontWeight(obj, value)
            if ~obj.InternalPropertySet
                for idx = 1:length(obj.OriginalObjects)
                    if ~isequal(obj.OriginalObjects(idx).FontWeight,value.getValue)
                        obj.OriginalObjects(idx).FontWeight = value.getValue;
                    end
                end
            end
        end

        function value = get.TitleFontWeight(obj)
            value = obj.OriginalObjects.TitleFontWeight;
        end

        function set.TitleFontWeight(obj, value)
            if ~obj.InternalPropertySet
                for idx = 1:length(obj.OriginalObjects)
                    if ~isequal(obj.OriginalObjects(idx).TitleFontWeight,value.getValue)
                        obj.OriginalObjects(idx).TitleFontWeight = value.getValue;
                    end
                end
            end
        end

        function value = get.SubtitleFontWeight(obj)
            value = obj.OriginalObjects.SubtitleFontWeight;
        end

        function set.SubtitleFontWeight(obj, value)
            if ~obj.InternalPropertySet
                for idx = 1:length(obj.OriginalObjects)
                    if ~isequal(obj.OriginalObjects(idx).SubtitleFontWeight,value.getValue)
                        obj.OriginalObjects(idx).SubtitleFontWeight = value.getValue;
                    end
                end
            end
        end

        function value = get.FontAngle(obj)
            value = obj.OriginalObjects.FontAngle;
        end

        function set.FontAngle(obj, value)
            if ~obj.InternalPropertySet
                for idx = 1:length(obj.OriginalObjects)
                    if ~isequal(obj.OriginalObjects(idx).FontAngle,value.getValue)
                        obj.OriginalObjects(idx).FontAngle = value.getValue;
                    end
                end
            end
        end
    end
end
