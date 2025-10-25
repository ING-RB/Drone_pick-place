classdef (ConstructOnLoad, UseClassDefaultsOnLoad, Sealed) ConstantPlane < ...
        matlab.graphics.primitive.Data & ...
        matlab.graphics.mixin.AxesParentable & ...
        matlab.graphics.internal.GraphicsUIProperties & ...
        matlab.graphics.mixin.Legendable & ...
        matlab.graphics.mixin.Selectable & ...
        matlab.graphics.mixin.ColorOrderUser
    %

    %   Copyright 2024 The MathWorks, Inc.

    properties (Dependent)
        NormalVector (1,3) {mustBeNumeric, mustBeReal} = [0 0 1]
        Offset (1,1) {mustBeNumeric, mustBeReal} = 0
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = "#7d7d7d"
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.3
    end

    properties (AffectsObject, AffectsLegend, NeverAmbiguous)
        FaceColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = "auto"
    end

    properties (Dependent, Hidden)
        PrimitiveChildEnabled matlab.lang.OnOffSwitchState = "off"
    end

    properties (Hidden, AffectsObject, AffectsDataLimits, AbortSet)
        NormalVector_I (1,3) {mustBeNumeric, mustBeReal} = [0 0 1]
        Offset_I (1,1) {mustBeNumeric, mustBeReal} = 0
    end

    properties (Hidden, AffectsLegend, AbortSet, AffectsObject)
        FaceColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = "#7d7d7d"
        FaceAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.3
    end

    properties (Hidden)
        NormalVectorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = "auto"
        OffsetMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = "auto"
        FaceAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = "auto"
    end

    properties (Hidden, Transient, NonCopyable, AffectsObject)
        PrimitiveChildEnabled_I matlab.lang.OnOffSwitchState = "off"
        PrimitiveChildEnabledMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = "auto"
    end

    properties (Hidden, Transient, NonCopyable)
        Face matlab.graphics.primitive.world.TriangleStrip
        PrimitiveChild matlab.graphics.primitive.world.ConstantPlanePrimitive
        SelectionHandle matlab.graphics.interactor.ListOfPointsHighlight
    end

    properties (Transient, NonCopyable, Access=protected)
        LimitsCache = nan(3,2)
    end

    methods
        function obj = ConstantPlane(varargin)
            obj.Face = matlab.graphics.primitive.world.TriangleStrip(Internal = true);
            obj.addNode(obj.Face);
            obj.PrimitiveChild = matlab.graphics.primitive.world.ConstantPlanePrimitive(Internal = true);
            obj.addNode(obj.PrimitiveChild);

            obj.Type = 'constantplane';

            obj.SeriesIndex_I = "none";

            addDependencyConsumed(obj, {'xyzdatalimits', 'view' 'colororder_linestyleorder'});
            matlab.graphics.chart.internal.ctorHelper(obj, varargin);
        end
    end

    methods (Hidden)
        function doUpdate(obj, updateState)
            % Do not render ConstantPlane Primitives if its
            % NormalVector or Offset are non-finite or if the
            % NormalVector is zero
            if ~all(isfinite(obj.NormalVector_I)) || ~isfinite(obj.Offset_I) || all(obj.NormalVector_I == 0)
                obj.Face.Visible_I = "off";
                obj.PrimitiveChild.Visible_I = "off";
                return
            end

            if obj.PrimitiveChildEnabledMode == "auto"
                obj.PrimitiveChildEnabled_I = usePrimitiveContainer(updateState);
            end

            visiblePrimitive = obj.Face;
            invisiblePrimitive = obj.PrimitiveChild;

            if obj.PrimitiveChildEnabled_I
                visiblePrimitive = obj.PrimitiveChild;
                invisiblePrimitive = obj.Face;
                obj.PrimitiveChild.NormalVector_I = obj.NormalVector_I;
                obj.PrimitiveChild.Offset_I = obj.Offset_I;
            else
                obj.addVertexData(updateState);
            end

            obj.addColorData(updateState, visiblePrimitive, invisiblePrimitive);

            obj.drawSelectionHandles;

        end

        function actualValue = setParentImpl(obj, proposedValue)
            if isa(proposedValue, 'matlab.graphics.primitive.Group') || ...
                    isa(proposedValue, 'matlab.graphics.primitive.Transform')
                childName = fliplr(strtok(fliplr(class(obj)), '.'));
                targetName = fliplr(strtok(fliplr(class(proposedValue)), '.'));
                error(message('MATLAB:hg:InvalidParent',childName, targetName))
            end
            actualValue = proposedValue;
        end

        function icon = getLegendGraphic(obj)

            icon = matlab.graphics.primitive.world.Group;

            face = matlab.graphics.primitive.world.TriangleStrip( ...
                Parent = icon, ...
                VertexData = single([0 0 1 1; 0 1 0 1; 0 0 0 0]), ...
                StripData = uint32([1 5]));
            color = obj.FaceColor_I;
            if ~isequal(color, "none")
                color = [color obj.FaceAlpha_I];
            end
            hgfilter('RGBAColorToGeometryPrimitive', face, color)

        end

        function extents = getXYZDataExtents(obj)
            % If the plane is perpendicular to an axis, expand the limits
            % to include the plane.
            zeroIndices = obj.NormalVector == 0;
            extents = nan(3,2);
            if sum(zeroIndices) == 2
                ind = ~zeroIndices;
                extents(ind,:) = obj.Offset / obj.NormalVector(ind);
            end
        end
    end

    methods (Hidden, Access=protected)
        function addVertexData(obj, updateState)
            % This function will find the points of the plane that intersect the
            % PlotBox cube and convert that to VertexData to visualize the
            % ConstantPlane
            % Recompute VertexData only if limits changed
            ds = updateState.DataSpace;
            limits = [ds.XLim_I; ds.YLim_I; ds.ZLim_I];
            if all(obj.LimitsCache == limits, "all")
                return
            end
            obj.LimitsCache = limits;
            nv = obj.NormalVector_I;
            os = obj.Offset_I;

            points = obj.findPlanePlotBoxIntersects(nv, os, ds.XLim_I, ds.YLim_I, ds.ZLim_I);

            % If less than three points hit the cube, do not visualize
            if height(points) < 3
                obj.Face.VertexData_I = single([]);
                obj.Face.StripData_I = uint32([]);
                return;
            end

            points = obj.reorderPointsForStripData(points);

            % Convert coordinates from Data to World for VertexData
            iter = matlab.graphics.axis.dataspace.IndexPointsIterator;
            set(iter, 'Vertices', points);

            obj.Face.VertexData_I = TransformPoints(ds, updateState.TransformUnderDataSpace, iter);
            obj.Face.StripData_I = uint32([1 width(obj.Face.VertexData_I) + 1]);
        end

        function addColorData(obj, updateState, visiblePrimitive, invisiblePrimitive)
            visiblePrimitive.Visible_I = "on";
            invisiblePrimitive.Visible_I = "off";

            didApply = obj.applyColor(updateState, "FaceColor");
            if didApply && isequal(obj.SeriesIndex_I, "none")
                set(obj, "FaceColor_I", "factory");
            end

            colorData = obj.FaceColor_I;
            if ~isequal(obj.FaceColor_I, "none")
                colorData = [colorData obj.FaceAlpha_I];
            end

            hgfilter('RGBAColorToGeometryPrimitive', visiblePrimitive, colorData);
        end

        function shortdisp = getPropertyGroups(~)
            shortdisp = matlab.mixin.util.PropertyGroup(...
                {'NormalVector','Offset','FaceColor','FaceAlpha'});
        end

        function lbl = getDescriptiveLabelForDisplay(obj)
            lbl = obj.Tag;
            if isempty(lbl)
                lbl = obj.DisplayName;
            end
        end

    end

    methods (Hidden, Access=private)

        function drawSelectionHandles(obj)
            % Draw the Selection Handles
            if strcmp(obj.Visible,'on') && strcmp(obj.Selected,'on') && strcmp(obj.SelectionHighlight,'on')
                if isempty(obj.SelectionHandle)
                    obj.SelectionHandle = matlab.graphics.interactor.ListOfPointsHighlight;
                    obj.SelectionHandle.Internal = true;
                    obj.addNode(obj.SelectionHandle);
                    obj.SelectionHandle.Description = 'ConstantPlane SelectionHandle';
                end

                obj.SelectionHandle.Visible = true;
                obj.SelectionHandle.VertexData = obj.Face.VertexData_I;
            elseif ~isempty(obj.SelectionHandle)
                obj.SelectionHandle.VertexData = [];
                obj.SelectionHandle.Visible = 'off';
            end
        end

    end

    methods % Fanouts to PrimitiveContainer
        function set.NormalVector_I(obj, nv)
            obj.NormalVector_I = nv;
            % Update PrimitiveContainer and invalidate the cache
            obj.LimitsCache = nan(3,2); %#ok<MCSUP>
        end

        function set.Offset_I(obj, os)
            obj.Offset_I = os;
            % Update PrimitiveContainer and invalidate the cache
            obj.LimitsCache = nan(3,2); %#ok<MCSUP>
        end
    end

    methods % Trivial Getters/Setters
        function nv = get.NormalVector(obj)
            nv = obj.NormalVector_I;
        end

        function set.NormalVector(obj, nv)
            obj.NormalVectorMode = "manual";
            obj.NormalVector_I = nv;
        end

        function offset = get.Offset(obj)
            offset = obj.Offset_I;
        end

        function set.Offset(obj, offset)
            obj.OffsetMode = "manual";
            obj.Offset_I = offset;
        end

        function color = get.FaceColor(obj)
            % Ensure that the FaceColor is appropriately updated if "auto"
            if obj.FaceColorMode == "auto"
                forceFullUpdate(obj, "all", "FaceColor");
            end

            color = obj.FaceColor_I;
        end

        function set.FaceColor(obj, color)
            obj.FaceColorMode = "manual";
            obj.FaceColor_I = color;
        end

        function alpha = get.FaceAlpha(obj)
            alpha = obj.FaceAlpha_I;
        end

        function set.FaceAlpha(obj, alpha)
            obj.FaceAlphaMode = "manual";
            obj.FaceAlpha_I = alpha;
        end

        function onOff = get.PrimitiveChildEnabled(obj)
            % Ensure that the PrimitiveChildEnabled is appropriately updated if "auto"
            if obj.PrimitiveChildEnabledMode == "auto"
                forceFullUpdate(obj, "all", "PrimitiveChildEnabled");
            end
            onOff = obj.PrimitiveChildEnabled_I;
        end

        function set.PrimitiveChildEnabled(obj, onOff)
            obj.PrimitiveChildEnabledMode = "manual";
            obj.PrimitiveChildEnabled_I = onOff;
        end
    end

    methods (Static, Hidden, Access=protected) % Helper Functions that don't require ConstantPlane
        function points = findPlanePlotBoxIntersects(normalVector, offset, xLim, yLim, zLim)
            % Calculate points of planes intersecting the edges of the PlotBox
            % parallel to either the X, Y, or Z Axis
            points = ...
                [linePlaneIntersect("x", yLim(1), zLim(1), normalVector, offset)
                 linePlaneIntersect("x", yLim(2), zLim(1), normalVector, offset)
                 linePlaneIntersect("x", yLim(1), zLim(2), normalVector, offset)
                 linePlaneIntersect("x", yLim(2), zLim(2), normalVector, offset)
                 linePlaneIntersect("y", zLim(1), xLim(1), normalVector, offset)
                 linePlaneIntersect("y", zLim(2), xLim(1), normalVector, offset)
                 linePlaneIntersect("y", zLim(1), xLim(2), normalVector, offset)
                 linePlaneIntersect("y", zLim(2), xLim(2), normalVector, offset)
                 linePlaneIntersect("z", xLim(1), yLim(1), normalVector, offset)
                 linePlaneIntersect("z", xLim(2), yLim(1), normalVector, offset)
                 linePlaneIntersect("z", xLim(1), yLim(2), normalVector, offset)
                 linePlaneIntersect("z", xLim(2), yLim(2), normalVector, offset)];

            % Remove points that are outside the limits
            invalidValue = points < [xLim(1) yLim(1) zLim(1)] | ...
                           points > [xLim(2) yLim(2) zLim(2)];
            points(any(invalidValue,2),:) = [];
            points = unique(points,"rows");
        end

        function points = reorderPointsForStripData(points)
            % Reorder the points so that the triangle strip creates
            % a filled polygon with no overlapping triangles

            % Sort points so that they are in order by rotation
            % with respect to the middlePoint of all the points
            %     3   2
            %      \ /
            %   4---M---1
            %      / \
            %     5   6

            % Since the points are co-planar, we can shift them to the origin
            % and project them onto the XY plane and find their rotation.

            % Create the basis using two reference vectors from the midpoint
            % and the Normal Vector
            midPoint = sum(points / height(points), 1);
            refVector1 = points(1,:) - midPoint;
            refVector2 = points(2,:) - midPoint;
            basis = [refVector1' refVector2'];

            % Shift all the points to the origin and perform a change of basis
            rebasedPoints = (points - midPoint) * basis;

            % Find their angle of rotation and sort the original points
            % with respect to that order
            rotations = atan2(rebasedPoints(:,2), rebasedPoints(:,1));
            [~, idx] = sort(rotations);
            points = points(idx,:);

            % Reorder Points to create a filled polygon with strip data
            %   1---2   1---2     2     1---2
            %   |  /    |\  |    / \    | \ |
            %   | /     | \ |   1---3   6---3
            %   |/      |  \|   | / |   | \ |
            %   3       4---3   5---4   5---4
            switch height(points)
                case 4
                    points = points([2 1 3 4], :);
                case 5
                    points = points([2 1 3 5 4], :);
                case 6
                    points = points([2 1 3 6 4 5], :);
            end
        end
    end

    methods (Static, Access=protected)
        function map = getThemeMap
            map = struct(FaceColor = "--mw-graphics-colorNeutral-region-primary");
        end
    end
end

function vert = linePlaneIntersect(missingCoord, coord1, coord2, normalVector, offset)
    % Find the coordinate that intersects the line that is constant wrt
    % to two coordinates
    % Given a*x + b*y + c*z = offset
    % "x" solves -> x = (offset - (b*y + c*z)) / a;
    % "y" solves -> y = (offset - (c*z + a*x)) / b;
    % "z" solves -> z = (offset - (a*x + b*y)) / c;

    % Find corresponding indices for solving the above equations
    ind = find(["x" "y" "z"] == missingCoord);
    idx = mod((-1:1) + ind, 3) + 1;

    vert = [(offset - (coord1 * normalVector(idx(2)) + coord2 * normalVector(idx(3)))) / normalVector(idx(1))
            coord1
            coord2]';
    vert(idx) = vert;

    if any(~isfinite(vert))
        vert = double.empty(0,3);
    end
end

function usePrimitive = usePrimitiveContainer(updateState)
    usePrimitive = isa(updateState.Canvas, "matlab.graphics.primitive.canvas.HTMLCanvas") && ...
        ~updateState.Canvas.ServerSideRendering;
end