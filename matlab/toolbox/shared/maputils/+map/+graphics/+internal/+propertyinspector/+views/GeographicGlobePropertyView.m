classdef GeographicGlobePropertyView < internal.matlab.inspector.InspectorProxyMixin 
    % This class has the metadata information on the
    % globe.graphics.GeographicGlobe property groupings as reflected in the
    % property inspector

    % Copyright 2022 The MathWorks, Inc.

    properties
        Basemap internal.matlab.editorconverters.datatype.StringEnumeration
        Children
        ColorOrder
        HandleVisibility
        NextPlot
        NextSeriesIndex
        Parent
        Position
        Tag
        Terrain internal.matlab.editorconverters.datatype.StringEnumeration
        Type
        Units
        UserData
        Visible
    end

    methods
        function obj = GeographicGlobePropertyView(hObj)
            obj@internal.matlab.inspector.InspectorProxyMixin(hObj);

            %...............................................................

            g1 = obj.createGroup(getString(message('MATLAB:propertyinspector:Map')),'','');
            g1.addProperties('Basemap','Terrain');
            g1.Expanded = true;

            %...............................................................

            g2 = obj.createGroup(getString(message('MATLAB:propertyinspector:MultiplePlots')),'','');
            g2.addProperties('ColorOrder','NextSeriesIndex','NextPlot');
            g2.Expanded = true;

            %...............................................................

            g3 = obj.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g3.addEditorGroup('Position');
            g3.addProperties('Units');

            %...............................................................

            g4 = obj.createGroup(getString(message('MATLAB:propertyinspector:Interactivity')),'','');
            g4.addProperties('Visible');

            %...............................................................

            g5 = obj.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g5.addProperties('Parent','Children','HandleVisibility');

            %...............................................................

            g6 = obj.createGroup(getString(message('MATLAB:propertyinspector:Identifiers')),'','');
            g6.addProperties('Type','Tag','UserData');
        end


        % Special handling required for enumerations not handled by a
        % graphics datatype.
        function set.Basemap(obj, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                if ~isequal(obj.OriginalObjects.Basemap, inspectorValue.Value)
                    % Extra check to make sure we're not overriding a
                    % TileSetMetadata object's value
                    obj.OriginalObjects.Basemap = inspectorValue.Value;
                end
            else
                obj.OriginalObjects.Basemap = char(inspectorValue);
            end
        end


        function value = get.Basemap(obj)
            value = internal.matlab.editorconverters.datatype.StringEnumeration(...
                obj.OriginalObjects.Basemap, ...
                matlab.graphics.chart.internal.maps.basemapNames);
        end


        function set.Terrain(obj, inspectorValue)
            if isa(inspectorValue, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                obj.OriginalObjects.Terrain = inspectorValue.Value;
            else
                obj.OriginalObjects.Terrain = char(inspectorValue);
            end
        end


        function value = get.Terrain(obj)
            value = internal.matlab.editorconverters.datatype.StringEnumeration(...
                obj.OriginalObjects.Terrain, ...
                terrain.internal.TerrainSource.terrainchoices);
        end
    end
end
