classdef IconChartPropertyView <  ...
        matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.DataspaceMixin
% This class has the metadata information on the map.graphics.chart.primitive.IconChart property
% groupings as reflected in the property inspector

% Copyright 2024 The MathWorks, Inc.
    
    properties
        IconAnchorPoint
        IconColorData
        IconAlphaData
        IconRotation
        IconRotationMode
        SizeData
        SizeDataMode
        SizeVariable
        IconRotationVariable
        Children
        Parent
        Visible
        HandleVisibility
        SourceTable
        AffectAutoLimits
        DisplayName
        Annotation
        Selected
        SelectionHighlight
        HitTest
        PickableParts
        DataTipTemplate
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
    end


    methods
        function iview = IconChartPropertyView(obj)
            iview@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g1 = iview.createGroup(getString(message('maputils:propertyinspector:Icon')),'','');
            g1.addProperties('IconAlphaData','IconColorData',...
                'IconAnchorPoint','IconRotation','IconRotationMode');
            g1.Expanded = true;

            %...............................................................
            g2 = iview.createGroup(getString(message('maputils:propertyinspector:SizeData')),'','');
            g2.addProperties('SizeData','SizeDataMode');
            g2.Expanded = true;

            g3 = iview.createGroup(getString(message('MATLAB:propertyinspector:CoordinateData')),'','');
            g4 = iview.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');

            allGeo = numel(obj) > 0 && numel(findobj(obj,'-property','LatitudeData')) == numel(obj);
            if allGeo
                dynamicProps = {'LatitudeData', 'LatitudeDataMode', ...
                    'LongitudeData', 'LongitudeDataMode', 'LatitudeVariable', 'LongitudeVariable'};
                iview.addDynamicProps(obj, dynamicProps);
                g3.addProperties('LatitudeData', 'LatitudeDataMode', ...
                    'LongitudeData', 'LongitudeDataMode', 'AffectAutoLimits');
                g4.addProperties('SourceTable', 'LatitudeVariable', 'LongitudeVariable', ...
                    'SizeVariable', 'IconRotationVariable');
            else
                g3.addProperties('XData', 'XDataMode', ...
                    'YData', 'YDataMode', 'AffectAutoLimits');
                g4.addProperties('SourceTable', 'XVariable', 'YVariable', ...
                    'SizeVariable', 'IconRotationVariable');
            end

            %...............................................................

            iview.createLegendGroup();

            %...............................................................

            iview.createCommonInspectorGroup();

        end
    end
end
