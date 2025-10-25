classdef HeightReferencedLinePropertyView  ...
        < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews
    % This class has the metadata information on the map.graphics.primitive.Line
    % property groupings as reflected in the property inspector

    % Copyright 2022 The MathWorks, Inc.

    properties
        Children
        Color
        HandleVisibility
        HeightData
        HeightReference internal.matlab.editorconverters.datatype.StringEnumeration
        LatitudeData
        LineStyle internal.matlab.editorconverters.datatype.StringEnumeration
        LineWidth
        LongitudeData
        Marker internal.matlab.editorconverters.datatype.StringEnumeration
        MarkerIndices
        MarkerSize
        Parent
        SeriesIndex
        Tag
        Type
        UserData
        Visible
    end

    properties (Access = protected, Constant)
        HeightReferenceOptions = {'geoid','terrain','ellipsoid'}
        LineStyleOptions = {'-','none'}
        MarkerOptions = {'none','o'}
    end

    methods
        function obj = HeightReferencedLinePropertyView(hObj)
            obj@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(hObj);

            %...............................................................

            g1 = obj.createGroup(getString(message('maputils:propertyinspector:Line')),'','');
            g1.addProperties('Color','LineStyle','LineWidth','SeriesIndex');
            g1.Expanded = true;

            %...............................................................

            g2 = obj.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g2.addProperties('Marker','MarkerIndices','MarkerSize');
            g2.Expanded = true;

            %...............................................................

            g3 = obj.createGroup(getString(message('MATLAB:propertyinspector:CoordinateData')),'','');
            g3.addProperties('LatitudeData','LongitudeData','HeightData','HeightReference');
            g3.Expanded = true;

            %...............................................................

            obj.createCommonInspectorGroup();
        end


        % Special handling required for enumerations not handled by a
        % graphics datatype.
        function set.HeightReference(obj, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                obj.OriginalObjects.HeightReference = inspectorValue.Value;
            else
                obj.OriginalObjects.HeightReference = char(inspectorValue);
            end
        end


        function value = get.HeightReference(obj)
            value = internal.matlab.editorconverters.datatype.StringEnumeration(...
                obj.OriginalObjects.HeightReference, obj.HeightReferenceOptions);
        end


        function set.LineStyle(obj, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                obj.OriginalObjects.LineStyle = inspectorValue.Value;
            else
                obj.OriginalObjects.LineStyle = char(inspectorValue);
            end
        end


        function value = get.LineStyle(obj)
            value = internal.matlab.editorconverters.datatype.StringEnumeration(...
                obj.OriginalObjects.LineStyle, obj.LineStyleOptions);
        end


        function set.Marker(obj, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                obj.OriginalObjects.Marker = inspectorValue.Value;
            else
                obj.OriginalObjects.Marker = char(inspectorValue);
            end
        end


        function value = get.Marker(obj)
            value = internal.matlab.editorconverters.datatype.StringEnumeration(...
                obj.OriginalObjects.Marker, obj.MarkerOptions);
        end
    end
end
