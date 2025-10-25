classdef PrimitiveLinePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
    & matlab.graphics.internal.propertyinspector.views.IconDataMixin ...
    & matlab.graphics.internal.propertyinspector.views.DataspaceMixin

    % This class has the metadata information on the matlab.graphics.primitive.Line property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
        AffectAutoLimits
        Color
        ColorMode
        LineStyle
        LineStyleMode
        LineWidth
        AlignVertexCenters
        LineJoin
        Clipping
        Marker
        MarkerMode
        MarkerSize
        MarkerEdgeColor
        MarkerFaceColor
        MarkerIndices
        Annotation
        DisplayName
        Selected
        SelectionHighlight
        ContextMenu
        Visible
        CreateFcn
        DeleteFcn
        ButtonDownFcn
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
        function iconProps = getIconProperties(hPLine)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.line);
            iconProps.edgeColor = hPLine.Color;
            iconProps.faceColor = 'none';
        end
    end

    methods
        function this = PrimitiveLinePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('Color','LineStyle','LineWidth','SeriesIndex');
            g2.addSubGroup('LineJoin','AlignVertexCenters','ColorMode','LineStyleMode');
            g2.Expanded = true;

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g1.addProperties('Marker','MarkerIndices','MarkerSize');
            g1.addSubGroup('MarkerEdgeColor','MarkerFaceColor','MarkerMode');
            g1.Expanded = true;

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');

            allPolar = numel(findobj(obj,'-property','RData')) == numel(obj);
            allGeo = numel(findobj(obj,'-property','LatitudeData')) == numel(obj);
            allCartesian = numel(findobj(obj,'-property','XData','-and','-not','-property','RData','-and','-not', '-property','LatitudeData')) == numel(obj);

            if allPolar
                props = {'RData', 'ThetaData'};
            elseif allGeo
                props = {'LatitudeData', 'LongitudeData'};
            elseif allCartesian
                props = {'XData', 'YData', 'ZData'};
            end

            if allPolar || allGeo || allCartesian
                this.addDynamicProps(obj, props);
                g3.addProperties(props{:});
            end

            g3.addProperties('AffectAutoLimits');

            %...............................................................

            this.createLegendGroup();
            %...............................................................

            this.createCommonInspectorGroup();
        end
    end
end
