classdef PrimitiveAreaPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Area property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
        EdgeColor
        FaceColor
        FaceColorMode
        FaceAlpha
        AlignVertexCenters
        EdgeAlpha
        LineStyle
        LineWidth
        Clipping
        BaseLine
        ShowBaseLine
        BaseValue
        Annotation
        DisplayName
        XData
        XDataMode
        YData
        XDataSource
        YDataSource
        Selected
        SelectionHighlight
        ContextMenu
        Visible
        ButtonDownFcn
        CreateFcn
        DeleteFcn
        BeingDeleted
        BusyAction
        HitTest
        PickableParts
        Interruptible
        Children
        HandleVisibility
        Parent
        Tag
        Type
        UserData
        DataTipTemplate
        SeriesIndex
    end

    methods(Static)
        function iconProps = getIconProperties(hArea)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hArea.EdgeColor;
            iconProps.faceColor = hArea.FaceColor;
            % when flat is used to set colors, MATLAB uses values from
            % the colormap
            ax = ancestor(hArea,'matlab.graphics.axis.AbstractAxes');
            % checking which colormap is being used
            if strcmpi(ax.ColormapMode,'manual')
                c = ax.Colormap;
            else
                f = ancestor(hArea,'figure');
                c = f.Colormap;
            end
            % setting the color by the colormap if the color is set to flat
            if strcmpi(iconProps.faceColor,'flat')
                iconProps.faceColor = c(1,:);
            end
            if strcmpi(iconProps.edgeColor,'flat')
                iconProps.edgeColor = c(1,:);
            end
        end
    end

    methods
        function this = PrimitiveAreaPropertyView(obj)
             this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('FaceColor','EdgeColor','FaceAlpha');
            g1.addSubGroup('EdgeAlpha','LineStyle',...
                'LineWidth','SeriesIndex','AlignVertexCenters','FaceColorMode');
            g1.Expanded = 'true';

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Baseline')),'','');
            g3.addProperties('BaseValue');
            g3.addSubGroup('ShowBaseLine','BaseLine');
            g3.Expanded = true;

            %...............................................................

            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g7.addProperties('XData','XDataMode','YData','XDataSource','YDataSource');

            %...............................................................

             this.createLegendGroup();

            this.createCommonInspectorGroup();
        end
    end
end
