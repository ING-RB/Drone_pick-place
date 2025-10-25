classdef PrimitivePatchPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.primitive.Patch property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
        AlignVertexCenters,
        AlphaDataMapping,
        AmbientStrength,
        Annotation,
        BackFaceLighting,
        BeingDeleted,
        BusyAction,
        ButtonDownFcn,
        CData,
        CDataMode,
        CDataMapping,
        Children,
        Clipping,
        CreateFcn,
        DeleteFcn,
        DiffuseStrength,
        DisplayName,
        EdgeAlpha,
        EdgeColor,
        EdgeLighting,
        FaceAlpha,
        FaceColor,
        FaceLighting,
        FaceNormals,
        FaceNormalsMode,
        FaceVertexAlphaData,
        FaceVertexCData,
        FaceVertexCDataMode,
        Faces,
        HandleVisibility,
        HitTest,
        Interruptible,
        LineStyle,
        LineJoin,
        LineWidth,
        Marker,
        MarkerEdgeColor,
        MarkerFaceColor,
        MarkerSize,
        Parent,
        PickableParts,
        Selected,
        SelectionHighlight,
        SeriesIndex,
        SpecularColorReflectance,
        SpecularExponent,
        SpecularStrength,
        Tag,
        Type,
        ContextMenu,
        UserData,
        VertexNormals,
        VertexNormalsMode,
        Vertices,
        Visible,
        XData,
        YData,
        ZData
        DataTipTemplate
    end

    methods(Static)
        function iconProps = getIconProperties(hPatch)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hPatch.EdgeColor;
            iconProps.faceColor = hPatch.FaceColor;
            colorStyles = {'flat','interp','texturemap'};
            % checking to see if the colors are one of the words listed
            % above and if so, using the colormap to decide to color of the
            % icon
            ax = ancestor(hPatch,'matlab.graphics.axis.AbstractAxes');
            if strcmpi(ax.ColormapMode,'manual')
                c = ax.Colormap;
            else
                f = ancestor(hPatch,'figure');
                c = f.Colormap;
            end
            if ismember(1,strcmpi(hPatch.FaceColor,colorStyles))
                iconProps.faceColor = c(length(c)/2,:);
            end
            if ismember(1,strcmpi(hPatch.EdgeColor,colorStyles))
                iconProps.edgeColor = c(length(c)/2,:);
            end
        end
    end


    methods
        function this = PrimitivePatchPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Color')),'','');
            g1.addProperties('FaceColor','EdgeColor','CData','SeriesIndex');
            g1.addSubGroup('FaceVertexCData','FaceVertexCDataMode','CDataMode','CDataMapping');
            g1.Expanded = 'true';

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Transparency')),'','');
            g2.addProperties('FaceAlpha','EdgeAlpha','FaceVertexAlphaData','AlphaDataMapping');
            g2.Expanded = 'true';

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:LineStyling')),'','');
            g3.addProperties('LineStyle','LineWidth','LineJoin','AlignVertexCenters');
            g3.Expanded = true;

            %...............................................................

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g4.addProperties('Marker','MarkerSize','MarkerEdgeColor',...
                'MarkerFaceColor');

            %...............................................................

            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g5.addProperties('Faces','Vertices','XData','YData','ZData');

            %...............................................................

            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:Normals')),'','');
            g6.addProperties('VertexNormals','VertexNormalsMode','FaceNormals','FaceNormalsMode');

            %...............................................................


            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:Lighting')),'','');
            g6.addProperties('FaceLighting','BackFaceLighting','EdgeLighting',...
                'AmbientStrength','DiffuseStrength','SpecularStrength',...
                'SpecularExponent','SpecularColorReflectance');

            %...............................................................

            this.createLegendGroup();

            %...............................................................

            this.createCommonInspectorGroup();
        end
    end
end
