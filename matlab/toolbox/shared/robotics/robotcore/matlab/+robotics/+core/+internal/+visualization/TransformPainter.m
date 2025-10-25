classdef TransformPainter < robotics.core.internal.visualization.Painter3D
%This class is for internal use only. It may be removed in the future.

%TransformPainter paints transforms in 3D space

%   Copyright 2018-2024 The MathWorks, Inc.

    properties (Constant)
        %DefaultColor - Default color of mesh
        DefaultColor = [1 0 0]

        %DefaultScale - Default scale of mesh
        DefaultScale = 1

        %DefaultZDownward - Default inertial frame Z axis point upwards
        DefaultInertialZDownward = false

        %DefaultMeshLineStyle - Default mesh line style
        DefaultMeshLineStyle = 'none'

        %GraphicsObjectTags - Tags for graphic objects
        GraphicsObjectTags = struct(...
            'InertialToPlot', 'InertiaToPlotTransform', ...
            'BodyToInertial', 'BodyToInertialTransform', ...
            'PatchToBody', 'PatchToBodyTransform', ...
            'Patch', 'MeshPatch', ...
            'xAxis', 'xAxis', ...
            'yAxis', 'yAxis', ...
            'zAxis', 'zAxis', ...
            'FrameLabel', 'FrameLabel', ...
            'FrameAxisLabelX', 'FrameAxisLabelX', ...
            'FrameAxisLabelY', 'FrameAxisLabelY', ...
            'FrameAxisLabelZ', 'FrameAxisLabelZ' ...
                                   );
    end

    properties (Access = {?robotics.core.internal.visualization.TransformPainter, ?matlab.unittest.TestCase})
        %Vertices - vertices of the mesh
        Vertices

        %Faces - Faces of the mesh
        Faces

        %HGroup - Handle to a hggroup
        %   everything painted with the same TransformPainter belongs to the same
        %   group
        HGroup
    end

    properties
        %Color - color of the rendered mesh
        Color = robotics.core.internal.visualization.TransformPainter.DefaultColor

        %Scale - scale of the rendered mesh
        Size = robotics.core.internal.visualization.TransformPainter.DefaultScale

        %ZDownward - indicates whether inertial frame's Z axis points downwards
        InertialZDownward = robotics.core.internal.visualization.TransformPainter.DefaultInertialZDownward

        %HandleXAxis - Handle to the x axis of the frame attached to the mesh
        HandleXAxis

        %HandleYAxis - Handle to the y axis of the frame attached to the mesh
        HandleYAxis

        %HandleZAxis - Handle to the z axis of the frame attached to the mesh
        HandleZAxis
    end

    methods
        function obj = TransformPainter(parentHandle, model, setupPerspective)
        %TransformPainter constructs a TransformPainter

            obj@robotics.core.internal.visualization.Painter3D(parentHandle, setupPerspective);
            obj.HGroup = hggroup(parentHandle);
            [obj.Vertices, obj.Faces] = robotics.core.internal.visualization.TransformPainter.parseSTL(model);
        end

        function enableAxisLabels(obj, axisLabels)
        %enableAxisLabels Set axis labels to X/Y/Z
            ax = obj.HGroup.Parent;

            % Only change axis labels if axisLabels is 'on'
            if strcmp(axisLabels, 'on')
                xlabel(ax, 'X');
                ylabel(ax, 'Y');
                zlabel(ax, 'Z');
            end
        end

        function hMeshTransform = paintAt(obj, position, orientation, is2D)
        %paintAt paint a mesh at given position and orientation
        %   If IS2D is true, then don't paint the Z frame axis.

        % Three transforms are involved:
        % 1. from mesh XYZ to body frame
        % 2. from body frame to inertial frame
        % 3. from inertial frame to plot XYZ

            import robotics.core.internal.visualization.TransformPainter

            if nargin < 4
                %Add default value for is2D
                is2D = false;
            end

            % Transform from inertial frame to plot XYZ
            hMeshTransform = hgtransform('Parent', obj.HGroup);
            hMeshTransform.Tag = TransformPainter.GraphicsObjectTags.InertialToPlot;

            % Transform from body frame to inertial frame
            hBodyToInertial = hgtransform('Parent', hMeshTransform);
            set(hBodyToInertial, "Matrix", makehgtform("scale", obj.Size));
            hBodyToInertial.Tag = TransformPainter.GraphicsObjectTags.BodyToInertial;

            % Transform from mesh XYZ to body frame
            hMeshToBody = hgtransform('Parent', hBodyToInertial);
            hMeshToBody.Tag = TransformPainter.GraphicsObjectTags.PatchToBody;

            % Transform according to InertialZ direction
            if obj.InertialZDownward
                tform = eul2tform([0,0,pi]);
                set(hMeshToBody, 'Matrix', tform);
                set(hMeshTransform, 'Matrix', tform);
            end

            % Create patch within the mesh transform
            p = patch(hMeshToBody, ...
                      'Vertices', obj.Vertices, ...
                      'Faces', obj.Faces, ...
                      'FaceColor', obj.Color, ...
                      'LineStyle', obj.DefaultMeshLineStyle);
            p.Tag = TransformPainter.GraphicsObjectTags.Patch;

            % Create axes within the inertial transform
            themeUtil = robotics.utils.internal.ThemeColorUtil;
            obj.HandleXAxis = plot3(hBodyToInertial, [0 1], [0 0], [0 0]);
            themeUtil.setThemeProperty(obj.HandleXAxis, 'Color', themeUtil.Red);
            obj.HandleXAxis.Tag = TransformPainter.GraphicsObjectTags.xAxis;
            obj.HandleYAxis = plot3(hBodyToInertial, [0 0], [0 1], [0 0]);
            themeUtil.setThemeProperty(obj.HandleYAxis, 'Color', themeUtil.Green);
            obj.HandleYAxis.Tag = TransformPainter.GraphicsObjectTags.yAxis;
            obj.HandleZAxis = plot3(hBodyToInertial, [0 0], [0 0], [0 1]);
            themeUtil.setThemeProperty(obj.HandleZAxis, 'Color', themeUtil.Blue);
            obj.HandleZAxis.Tag = TransformPainter.GraphicsObjectTags.zAxis;
            if is2D
                % Make Z axis invisible
                obj.HandleZAxis.Visible = false;
            end

            % Move the whole transform to designated position and
            % orientation
            obj.move(hMeshTransform, position, orientation);
        end

        function addMesh(obj, meshType, meshFile)
            %addMesh Add more invisible meshes that can be turned on using
            %updateConfig

            import robotics.core.internal.visualization.TransformPainter
           
            hMeshToBody = findobj(obj.HGroup, 'tag', TransformPainter.GraphicsObjectTags.PatchToBody);
            [vertices, faces] = TransformPainter.parseSTL(meshFile);
             p = patch(hMeshToBody, ...
                      'Vertices', vertices, ...
                      'Faces', faces, ...
                      'FaceColor', obj.Color, ...
                      'LineStyle', obj.DefaultMeshLineStyle);
            p.Tag = TransformPainter.GraphicsObjectTags.Patch + "_" + meshType;
            p.Visible = 'off';
        end

        function updateConfig(obj, type, meshSize, color, alpha)
            %updateConfig Update mesh configuration such as type, size,
            %color and alpha value
            
            import robotics.core.internal.visualization.TransformPainter
           
            hBodyToInertial = findobj(obj.HGroup, 'tag', TransformPainter.GraphicsObjectTags.BodyToInertial);
            if meshSize ~= obj.Size
                hBodyToInertial.Matrix = hBodyToInertial.Matrix*makehgtform('scale', double(meshSize)/obj.Size);
                obj.Size = double(meshSize);
            end

            patchMesh = findobj(hBodyToInertial, 'type', 'patch', 'visible', 'on');
            patchMesh.Visible = 'off';
            
            patchMesh = findobj(hBodyToInertial, 'tag', TransformPainter.GraphicsObjectTags.Patch + "_" + type);
            patchMesh.FaceColor = color;
            patchMesh.FaceAlpha = alpha;
            patchMesh.Visible = 'on';


        end

        function labelAndColorFrame(obj, hMeshTransform, frameAxisLabels, frameLabel, frameColor, is2D)
        %labelAndColorFrame Change color or labels of the coordinate frame
        %   hMeshTransform - Transform for the origin of the frame
        %   frameAxisLabels - 'on'/'off' to indicate if X/Y/Z labels
        %      should be shown on frame axes
        %   frameLabel - Label for the whole frame (character vector)
        %   is2D - true if it's a 2D transform, false otherwise

            import robotics.core.internal.visualization.*

            hBodyToInertial = findobj(hMeshTransform, 'Type', 'hgtransform', ...
                                      'Tag', TransformPainter.GraphicsObjectTags.BodyToInertial);

            if ~strcmp(frameColor, 'rgb')
                % If frame color is not the default,
                % color the axes based on user request
                obj.HandleXAxis.Color = frameColor;
                obj.HandleYAxis.Color = frameColor;
                obj.HandleZAxis.Color = frameColor;
            end

            % Add frame label if specified
            if strlength(frameLabel) > 0
                h = text(0, 0, 0, ...
                         ['\{' char(frameLabel) '\}'], 'Parent', hBodyToInertial);
                h.VerticalAlignment = 'top';
                h.HorizontalAlignment = 'center';
                h.FontUnits = 'normalized';
                h.Tag = TransformPainter.GraphicsObjectTags.FrameLabel;
                fmt = sprintf('%%c_{%s}', char(frameLabel));
            else
                fmt = '%c';
            end


            if strcmp(frameAxisLabels, 'on')
                % add the labels to each axis
                h = text(1, 0, 0, sprintf(fmt, 'X'), 'Parent', hBodyToInertial);
                h.Tag = TransformPainter.GraphicsObjectTags.FrameAxisLabelX;

                h = text(0, 1, 0, sprintf(fmt, 'Y'), 'Parent', hBodyToInertial);
                h.Tag = TransformPainter.GraphicsObjectTags.FrameAxisLabelY;


                h = text(0, 0, 1, sprintf(fmt, 'Z'), 'Parent', hBodyToInertial);
                h.Tag = TransformPainter.GraphicsObjectTags.FrameAxisLabelZ;
                if is2D
                    h.Visible = false;
                end
            end

        end

        function move(obj, hMeshTransform, position, orientation)
        %move a painted mesh to target position and orientation

            import robotics.core.internal.visualization.*
            % move the inertial transform
            hBodyToInertial = findobj(hMeshTransform, 'Type', 'hgtransform', ...
                                      'Tag', TransformPainter.GraphicsObjectTags.BodyToInertial);
            tform = quat2tform(orientation);
            tform(1:3,4) = position;
            if any(isnan(tform(:)))
                set(hBodyToInertial, 'Visible', 'off');
            else
                set(hBodyToInertial, 'Matrix', tform*makehgtform("scale", obj.Size));
            end
        end
    end

    methods (Static, Access = private)
        function [vertices,faces] = parseSTL(filepath)
        %parseSTL parse stl file into vertices and faces, normalize all
        %vertices to be within [-0.5, 0.5];
            import robotics.core.internal.visualization.*

            try
                stlTriangulation = stlread(filepath);
                vertices = stlTriangulation.Points;
                faces = stlTriangulation.ConnectivityList;
            catch
                % stl parse failed, don't show any mesh
                vertices = [];
                faces = [];
            end

            if ~isempty(vertices)
                vertices = vertices-mean(vertices,1);
                vertices = vertices/max(abs(vertices(:)))/2;
            end
        end

    end
end
