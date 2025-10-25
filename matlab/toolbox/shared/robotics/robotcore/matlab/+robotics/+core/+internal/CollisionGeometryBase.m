classdef (Abstract) CollisionGeometryBase < robotics.core.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%CollisionGeometryBase Base class for collision geometries

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    properties (Dependent)
        %Pose Pose of the geometry relative to the world frame
        %
        %   Default: eye(4)
        Pose

    end

    properties (Access = {?robotics.core.internal.InternalAccess,...
                          ?robotics.manip.internal.CollisionGeometry})

        %PoseInternal
        PoseInternal

        %VisualMeshVertices
        VisualMeshVertices

        %VisualMeshFaces
        VisualMeshFaces

        %EstimatedMaxReach
        EstimatedMaxReach
    end

    properties (Hidden, SetAccess = {?robotics.core.internal.InternalAccess})
        %Position
        Position

        %Quaternion
        Quaternion
    end

    properties (Hidden, Transient, SetAccess = {?robotics.core.internal.InternalAccess})

        %GeometryInternal Built-in representation of the collision geometry
        GeometryInternal

    end

    methods

        function obj = CollisionGeometryBase(nvargs)
        %CollisionGeometryBase
            arguments
                nvargs.Pose=eye(4);
            end
            obj.Pose = nvargs.Pose;
        end

        function [axOut, patchObjOut] = show(obj, varargin)
        %SHOW Plot collision geometry
        %   SHOW(GEOM) plots GEOM in MATLAB figure at its current pose.
        %   The tessellation will be generated automatically for
        %   primitives.
        %
        %   AX = SHOW(GEOM) returns the axes handle under which
        %   the collision geometry GEOM is plotted.
        %
        %   [AX, PATCHOBJ] = show(GEOM, ___) returns as a second output
        %   argument the graphic object (patch) that represents
        %   the collision geometry in AX.
        %
        %   SHOW(___, Name, Value) provides additional options specified
        %   by one or more Name, Value pair arguments. Name must appear
        %   inside single quotes (''). You can specify several name-value
        %   pair arguments in any order as Name1, Value1, ..., NameN, ValueN:
        %
        %      'Parent'         - Handle of the axes in which the
        %                         collision geometry is to be rendered

        % parse show inputs
            if(~coder.target('MATLAB'))
                coder.internal.errorIf(~coder.target('MATLAB'),...
                                       'shared_robotics:robotcore:utils:CodegenNotSupported', 'show');
            end
            parser = inputParser;
            parser.StructExpand = false;
            parser.addParameter('Parent', [], ...
                                @(x)robotics.internal.validation.validateAxesUIAxesHandle(x));

            parser.parse(varargin{:});

            ph = parser.Results.Parent;

            if isempty(ph)
                ax = newplot;
            else
                ax = newplot(ph);
            end

            if strcmp(ax.NextPlot, 'replace') % when hold is off, reset scene
                resetScene(obj, ax);
            end

            q = quaternion(obj.Quaternion);

            Vt = obj.Position + q.rotatepoint(obj.VisualMeshVertices);

            if isempty(obj.VisualMeshFaces)
                patchObj = patch(ax, 'Vertices', Vt, ...
                                 'FaceColor', [1, 0.5, 0]);
            else
                patchObj = patch(ax,'Faces', obj.VisualMeshFaces,...
                                 'Vertices', Vt, ...
                                 'FaceColor', [1, 0.5, 0]);
            end
            patchObj.EdgeAlpha=0;

            % only return outputs if user requests it
            if nargout > 0
                axOut = ax;
            end

            if nargout > 1
                patchObjOut = patchObj;
            end
        end

    end

    methods
        function set.Pose(obj, tform)
        %set.Pose
            obj.updatePose(tform);
        end

        function pose = get.Pose(obj)
        %get.Pose
            pose = obj.PoseInternal;
        end
    end

    methods
        function delete(obj)
        %delete Destructor of the CollisionGeometryBase type
        %   On the non-codegen path, the memory is handled via smart
        %   pointers, however, in codegen the generated code needs to call
        %   out the destructor explicitly.
            if(~coder.target('MATLAB'))
                robotics.core.internal.coder.CollisionGeometryBuildable.destructGeometry(...
                    obj.GeometryInternal);
            end
        end
    end

    methods (Access = {?robotics.core.internal.InternalAccess})
        function resetScene(obj, ax)
        %resetScene Reset scene if hold is off

            axis(ax, 'vis3d');
            hFigure = ancestor(ax,'figure');
            pan(hFigure,'on');
            rotate3d(hFigure,'on');

            ax.Visible = 'off';
            daspect(ax, [1 1 1]);

            % center the geometry
            a = obj.EstimatedMaxReach;
            if obj.EstimatedMaxReach == 0.0
                a = 1e-10;
            end
            set(ax, 'xlim', obj.Position(1) + [-a, a], 'ylim', obj.Position(2) + [-a, a], 'zlim', obj.Position(3) + [-a, a]);

            xlabel(ax, 'X');
            ylabel(ax, 'Y');
            zlabel(ax, 'Z');

            % set up view
            view(ax, [135 8]);
            set(ax, 'Projection', 'perspective');
            ax.CameraViewAngle = 8.0;
            grid(ax, 'on');

            % set up lighting
            if isempty(findobj(ax,'Type','Light'))
                light('Position',[a, 0, a],'Style','local','parent',ax);
            end
            ax.Visible = 'on';

        end

        function updatePose(obj, pose)
        %updatePose

        % Allow numeric (4x4) and se3 scalar input. Cast to double,
        % since previous code only allowed double inputs, even though
        % underlying validation is for single and double.
            poseTform = double(robotics.internal.validation.validateTransformSE3Scalar( ...
                pose, 'CollisionGeometryBase', 'Pose', {'finite', 'nonnan'}));

            pos = tform2trvec(poseTform);
            quat = robotics.core.internal.rotm2quat(tform2rotm(poseTform));
            obj.Position = pos;
            obj.Quaternion = quat;

            obj.PoseInternal = poseTform;

        end
    end
end
