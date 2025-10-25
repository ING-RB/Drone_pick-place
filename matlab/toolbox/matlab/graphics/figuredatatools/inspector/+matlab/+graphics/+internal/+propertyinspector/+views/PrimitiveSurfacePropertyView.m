classdef PrimitiveSurfacePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews  & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.primitive.Surface property
    % groupings as reflected in the property inspector

    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties
        FaceColor,
        FaceAlpha,
        FaceLighting,
        BackFaceLighting,
        EdgeColor,
        LineStyle,
        LineWidth,
        AlignVertexCenters,
        MeshStyle,
        EdgeAlpha,
        EdgeLighting,
        DataTipTemplate,
        Marker,
        MarkerSize,
        MarkerEdgeColor,
        MarkerFaceColor,
        VertexNormalsMode,
        VertexNormals,
        FaceNormalsMode,
        FaceNormals,
        AmbientStrength,
        DiffuseStrength,
        SpecularStrength,
        SpecularExponent,
        SpecularColorReflectance,
        CData,
        CDataMode,
        XData,
        YData,
        ZData,
        XDataMode,
        YDataMode,
        ZDataMode,
        AlphaData,
        CDataMapping,
        AlphaDataMapping,       
        Annotation,
        DisplayName,
        Selected,
        SelectionHighlight,
        ContextMenu,
        Clipping,
        Visible,
        CreateFcn,
        DeleteFcn,
        ButtonDownFcn,
        BeingDeleted,
        BusyAction,
        HitTest,
        PickableParts,
        Interruptible,
        Children,
        HandleVisibility,
        Parent,
        Tag,
        Type,
        UserData
    end

    methods(Static)
        function iconProps = getIconProperties(hSurf)
            % Add an enumeration where you can see all the shape types.
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect); 
            iconProps.edgeColor = hSurf.EdgeColor;
            iconProps.faceColor = hSurf.FaceColor;
            colorStyles = {'flat','interp','texturemap'};
            % finding out which colormap is used
            ax = ancestor(hSurf,'matlab.graphics.axis.AbstractAxes');            
            if strcmpi(ax.ColormapMode,'manual')
                c = ax.Colormap;
            else 
                f = ancestor(hSurf,'figure');
                c = f.Colormap;
            end         
            % if the colors are flat or interpolated, then use the correct
            % colormap to set the color. 
            if ismember(1,strcmpi(hSurf.FaceColor,colorStyles))
                iconProps.faceColor = c(round(length(c)/2),:);
            end

            if ismember(1,strcmpi(hSurf.EdgeColor,colorStyles))
                iconProps.edgeColor = c(round(length(c)/2)/2,:);
            end
        end
    end
    
    methods
        function this = PrimitiveSurfacePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Faces')),'','');
            g1.addProperties('FaceColor','FaceAlpha');
            g1.addSubGroup('FaceLighting','BackFaceLighting');
            g1.Expanded = 'true';
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Edges')),'','');
            g2.addProperties('MeshStyle','EdgeColor','EdgeAlpha');
            g2.addSubGroup('LineStyle','LineWidth','AlignVertexCenters','EdgeLighting');
            g2.Expanded = 'true';
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g3.addProperties('Marker','MarkerSize','MarkerEdgeColor','MarkerFaceColor');
            
            
            %...............................................................
            
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:CoordinateData')),'','');
            g7.addProperties('XData','XDataMode','YData','YDataMode','ZData',...
                'ZDataMode');
            
            %...............................................................
            
            g71 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandTransparencyData')),'','');
            g71.addProperties('CData',...
                'CDataMode',...
                'CDataMapping',...
                'AlphaData',...
                'AlphaDataMapping');                        
            %...............................................................
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Normals')),'','');
            g4.addProperties('VertexNormals','VertexNormalsMode',...
                'FaceNormals','FaceNormalsMode');            
            %...............................................................
            
            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Lighting')),'','');
            g5.addProperties('AmbientStrength','DiffuseStrength','SpecularStrength',...
                'SpecularExponent','SpecularColorReflectance');            
                       
            %...............................................................
            
            this.createLegendGroup();
            
            %...............................................................           
            this.createCommonInspectorGroup();
        end
    end
end