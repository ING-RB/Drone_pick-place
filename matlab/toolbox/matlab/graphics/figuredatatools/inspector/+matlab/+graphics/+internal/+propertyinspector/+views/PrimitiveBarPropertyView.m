classdef PrimitiveBarPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Bar property
    % groupings as reflected in the property inspector

    % Copyright 2017-2024 The MathWorks, Inc.

    properties
        Annotation,
        BarLayout,
        BarWidth,
        BaseLine,
        BaseValue,
        BeingDeleted,
        BusyAction,
        ButtonDownFcn,
        CData,
        CDataMode,
        Children,
        Clipping,
        CreateFcn,
        DeleteFcn,
        DisplayName,
        EdgeAlpha,
        EdgeColor,
        FaceAlpha,
        FaceColor,
        FaceColorMode,
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontName,
        FontSize,
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        GroupWidth,
        GroupWidthMode,
        HandleVisibility,
        HitTest,
        Horizontal,
        Interpreter,
        Interruptible,
        LabelColor,
        LabelColorMode,
        LabelLocation,
        LabelLocationMode,
        Labels,
        LineStyle,
        LineWidth,
        Parent,
        PickableParts,
        Selected,
        SelectionHighlight,
        ShowBaseLine,
        Tag,
        Type,
        ContextMenu,
        UserData,
        Visible,
        XData,
        XDataMode,
        XDataSource,
        YData,
        YDataSource,
        DataTipTemplate,
        SeriesIndex
    end

    methods(Static)
        function iconProps = getIconProperties(hBar)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hBar.EdgeColor;
            iconProps.faceColor = hBar.FaceColor;
            % when flat is used to set colors, MATLAB uses values from
            % CData
            if strcmpi(iconProps.faceColor,'flat')
                iconProps.faceColor = hBar.CData(1,:);
            end
            if strcmpi(iconProps.edgeColor,'flat')
                iconProps.edgeColor = hBar.CData(1,:);
            end
        end
    end


    methods
        function this = PrimitiveBarPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('FaceColor','EdgeColor','FaceAlpha');
            g1.addSubGroup('EdgeAlpha','LineStyle','LineWidth','SeriesIndex','FaceColorMode');
            g1.Expanded = 'true';


            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:BarLabels')),'','');
            g2.addProperties('Labels', 'LabelLocation');
            g2.addSubGroup('LabelLocationMode', 'LabelColor', 'LabelColorMode', 'FontName', 'FontSize', 'FontWeight', 'FontAngle', 'Interpreter');

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:BarLayout')),'','');
            g3.addProperties('BarLayout','BarWidth','Horizontal');
            g3.addSubGroup('GroupWidth','GroupWidthMode');
            g3.Expanded = 'true';

            %...............................................................

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Baseline')),'','');
            g4.addProperties('BaseValue');
            g4.addSubGroup('ShowBaseLine','BaseLine');
            g4.Expanded = 'true';

            %...............................................................

            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g5.addProperties('CData','XData','XDataMode',...
                'YData','XDataSource','YDataSource');
            g5.addSubGroup('CDataMode');

            %...............................................................

            this.createLegendGroup();

            %...............................................................

            this.createCommonInspectorGroup();
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
    end
end