classdef DebugView < matlab.graphics.chartcontainer.ChartContainer
    %DebugView ChartContainer object to visualize shapes on Cartesian and
    %Configuration Space. 
    
    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties
        geom1
        geom2
    end

    %% Public Properties
    properties (Access = public)
        %CoordPtsSimplex Cartesian coordinates for simplex.
        CoordPtsSimplex

        %ClosestPtSimplex Closest coordinate point to origin from simplex.
        %Also, might be refered to search direction vector.
        ClosestPtSimplex = [0 0 0]

        %WitnessPts
        WitnessPts = [0 0 0]

        %gjkOptions
        gjkOptions
    end

    %% Public Properties
    properties(Access = public,Transient,NonCopyable)
        GeoAxes         (1,1) matlab.graphics.axis.Axes
        CsoAxes         (1,1) matlab.graphics.axis.Axes

        GeoPatch        (2,1) matlab.graphics.primitive.Patch
        CsoPatch        (1,1) matlab.graphics.primitive.Patch

        WitnessPtsLine  (1,1) matlab.graphics.primitive.Line

        VLine           (1,1) matlab.graphics.primitive.Line
        SpxPoint        (1,1) matlab.graphics.primitive.Line
        SpxLine         (1,1) matlab.graphics.primitive.Line
        SpxTriangle     (1,1) matlab.graphics.primitive.Patch
        SpxTetrahedron  (1,1) matlab.graphics.primitive.Patch
    end

    %% Public Private
    properties(Access = private)
        createGIF   = false
    end

    %% Public Methods
    methods
        function obj = DebugView(opt, varargin)
            if nargin == 0
                opt = controllib.internal.gjk.gjkSolverOptions;
            end

            % Convert options into name-value pairs
            args = {'gjkOptions', opt};

            % Combine args with user-provided name-value pairs
            args = [args varargin];

            % Call superclass constructor method
            obj@matlab.graphics.chartcontainer.ChartContainer(args{:});
        end
    end

    %% Protected Methods
    methods(Access = protected)
        function setup(~)
            fig = gcf;
            fig.Color = 'w';
        end

        function update(obj)
            % Get the layout and store it as TiledChartLayout, tcl
            tcl = getLayout(obj);

            % Reconfigure layout if needed
            if obj.gjkOptions.ShowShapesCatersian && obj.gjkOptions.ShowConfigurationSpace
                if tcl.GridSize(2) ~= 2
                    % Delete layout contents to change the grid size of 1x2
                    delete(tcl.Children);
                end
                if isempty(tcl.Children)
                    tcl.GridSize = [1 2];

                    obj.GeoAxes = nexttile(tcl,1);
                    obj.CsoAxes = nexttile(tcl,2);
                    obj.initCsoAxes(obj.geom1.Is2D);
                    obj.initGeoAxes(obj.geom1.Is2D);
                end
            end
            if obj.gjkOptions.ShowShapesCatersian && ~obj.gjkOptions.ShowConfigurationSpace
                if tcl.GridSize(2) ~= 1
                    % Delete layout contents to change the grid size of 1x1
                    delete(tcl.Children);

                    tcl.GridSize = [1 1];

                    obj.GeoAxes = nexttile(tcl,1);

                    obj.initGeoAxes(obj.geom1.Is2D);
                end
            end
            if ~obj.gjkOptions.ShowShapesCatersian && obj.gjkOptions.ShowConfigurationSpace
                if tcl.GridSize(2) ~= 1
                    % Delete layout contents to change the grid size of 1x1
                    delete(tcl.Children);
                end
                if isempty(tcl.Children)
                    tcl.GridSize = [1 1];
                    obj.CsoAxes = nexttile(tcl,1);

                    obj.initCsoAxes(obj.geom1.Is2D);
                end
            end

            %% Update Configuration Space Axes
            if obj.gjkOptions.ShowConfigurationSpace
                obj.VLine.XData(2) = obj.ClosestPtSimplex(1);
                obj.VLine.YData(2) = obj.ClosestPtSimplex(2);
                obj.VLine.ZData(2) = obj.ClosestPtSimplex(3);
                
                xlim(obj.CsoAxes, 'padded');
                ylim(obj.CsoAxes, 'padded');

                set(obj.CsoPatch,       'Visible', 'on');
                set(obj.VLine,          'Visible', 'on');
                set(obj.SpxPoint,       'Visible', 'off');
                set(obj.SpxLine,        'Visible', 'off');
                set(obj.SpxTriangle,    'Visible', 'off');
                set(obj.SpxTetrahedron, 'Visible', 'off');

                switch  size(obj.CoordPtsSimplex,1)
                    case 1
                        set(obj.SpxPoint, 'Visible', 'on');
                        set(obj.SpxPoint, 'XData', obj.CoordPtsSimplex(:,1));
                        set(obj.SpxPoint, 'YData', obj.CoordPtsSimplex(:,2));
                        set(obj.SpxPoint, 'ZData', obj.CoordPtsSimplex(:,3));
                    case 2
                        set(obj.SpxLine, 'Visible', 'on');
                        set(obj.SpxLine, 'XData', obj.CoordPtsSimplex(:,1));
                        set(obj.SpxLine, 'YData', obj.CoordPtsSimplex(:,2));
                        set(obj.SpxLine, 'ZData', obj.CoordPtsSimplex(:,3));
                    case 3
                        set(obj.SpxTriangle, 'Visible', 'on');
                        set(obj.SpxTriangle, 'Vertices', obj.CoordPtsSimplex);
                    case 4
                        set(obj.SpxTetrahedron, 'Visible', 'on');
                        set(obj.SpxTetrahedron, 'Vertices', obj.CoordPtsSimplex);
                end
            end

            %% Update Shapes
            if obj.gjkOptions.ShowShapesCatersian             
                set(obj.WitnessPtsLine, 'Visible', 'on');
                set(obj.WitnessPtsLine, 'XData', obj.WitnessPts(:,1));
                set(obj.WitnessPtsLine, 'YData', obj.WitnessPts(:,2));
                set(obj.WitnessPtsLine, 'ZData', obj.WitnessPts(:,3));
            end

            %% Save GJK steps
            drawnow
            frame = getframe(gcf);
            im = frame2im(frame);
            [imind,cm] = rgb2ind(im,256);
            if ~obj.createGIF
                imwrite(imind,cm,'FILENAME.gif','gif','LoopCount',Inf,'DelayTime',.5);
                obj.createGIF = true;
            else
                imwrite(imind,cm,'FILENAME.gif','gif','WriteMode','append','DelayTime',.5);
            end
        end
    end

    %% Private Methods
    methods (Access=public)
        function [CSO, cvCso, S1, S2, FGeom1, FGeom2] = getConfSpace(obj)

            [vertGeom1, FGeom1] = obj.geom1.generateMesh();
            [vertGeom2, FGeom2] = obj.geom2.generateMesh();

            if obj.geom1.Is2D
                vertGeom1(3,:) = 0;
                vertGeom2(3,:) = 0;

                cosTheta1 = cos(obj.geom1.Theta);
                sinTheta1 = sin(obj.geom1.Theta);
                cosTheta2 = cos(obj.geom2.Theta);
                sinTheta2 = sin(obj.geom2.Theta);

                Hr1 = eye(3);
                Hr2 = eye(3);
                Hr1(1:2,1:2) = [cosTheta1 -sinTheta1; sinTheta1 cosTheta1];
                Hr2(1:2,1:2) = [cosTheta2 -sinTheta2; sinTheta2 cosTheta2];

                Ht1 = [obj.geom1.X; obj.geom1.Y; 0];
                Ht2 = [obj.geom2.X; obj.geom2.Y; 0];
            else
                Hr1 = obj.geom1.Pose(1:3, 1:3);
                Hr2 = obj.geom2.Pose(1:3, 1:3);

                Ht1 = obj.geom1.Pose(1:3, 4);
                Ht2 = obj.geom2.Pose(1:3, 4);
            end

            % S1 and S2 stores the coordinate vertices for geom1 and geom2
            S1 = Hr1*vertGeom1 + Ht1;
            S2 = Hr2*vertGeom2 + Ht2;

            % CSO = S1-S2, dim: length(vertGeom1)*length(vertGeom2) x 3
            CSO=[reshape(S1(1, :)-S2(1, :)', [], 1) ...
                reshape(S1(2, :)-S2(2, :)', [], 1) ...
                reshape(S1(3, :)-S2(3, :)', [], 1)];

            % Find convex hull of CSO
            if obj.geom1.Is2D
                cvCso = convhull(double(CSO(:,1:2)))';
            else
                cvCso = convhull(double(CSO));
            end
        end

        function initCsoAxes(obj, Is2D)
            cmap = lines(10);

            [CSO, convHullCso] = obj.getConfSpace;

            % set(obj.CsoAxes, 'Visible', 'off');
            obj.CsoPatch = patch( ...
                'Parent',           obj.CsoAxes, ...
                'Vertices',         CSO, ...
                'Faces',            convHullCso, ...
                'FaceVertexCData',  parula(length(CSO)), ...
                'FaceAlpha',        0.3, ...
                'FaceColor',        'interp', ...
                'EdgeColor',        'none', ...
                'Visible',          'off', ...
                'DisplayName',      'CSO');

            obj.SpxPoint = line( ...
                'Parent',       obj.CsoAxes, ...
                'XData',        zeros(1,2), ...
                'YData',        zeros(1,2), ...
                'ZData',        zeros(1,2), ...
                'LineWidth',    2, ...
                'Marker',       'o', ...
                'Color',        cmap(1,:), ...
                'Visible',      'off', ...
                'DisplayName',  '0-Simplex');

            obj.SpxLine = line( ...
                'Parent',       obj.CsoAxes, ...
                'XData',        zeros(1,2), ...
                'YData',        zeros(1,2), ...
                'ZData',        zeros(1,2), ...
                'LineWidth',    2, ...
                'Marker',       'o', ...
                'Color',        cmap(2,:), ...
                'Visible',      'off', ...
                'DisplayName',  '1-Simplex');

            obj.SpxTriangle = patch( ...
                'Parent',           obj.CsoAxes, ...
                'Vertices',         zeros(3,3), ...
                'Faces',            1:3, ...
                'FaceVertexCData',  repmat(cmap(3,:),3,1), ...
                'FaceAlpha',        0.4, ...
                'FaceColor',        'interp', ...
                'Marker',           'o', ...
                'Visible',          'off', ...
                'DisplayName',      '2-Simplex');

            obj.SpxTetrahedron = patch( ...
                'Parent',           obj.CsoAxes, ...
                'Vertices',         zeros(4,3), ...
                'Faces',            nchoosek(1:4,3), ...
                'FaceVertexCData',  cmap(4:7,:), ...
                'FaceAlpha',        0.4, ...
                'FaceColor',        'flat', ...
                'Visible',          'off', ...
                'DisplayName',      '3-Simplex');

            obj.VLine = line( ...
                'Parent',       obj.CsoAxes, ...
                'XData',        zeros(1,2), ...
                'YData',        zeros(1,2), ...
                'ZData',        zeros(1,2), ...
                'LineWidth',    2, ...
                'Marker',       '.', ...
                'Color',        cmap(8,:), ...
                'Visible',      'off', ...
                'DisplayName',  'v');

            axis(obj.CsoAxes, 'equal');
            box( obj.CsoAxes, 'on');
            
            set( obj.CsoAxes, 'XTick', 0);
            set( obj.CsoAxes, 'YTick', 0);
            grid(obj.CsoAxes, 'on')
            xlim(obj.CsoAxes, 'padded');
            ylim(obj.CsoAxes, 'padded');

            if ~Is2D
                set(obj.CsoAxes, 'ZTick', 0);
                zlim(obj.CsoAxes, 'padded');
                view(obj.CsoAxes, 3);
            end
        end

        function initGeoAxes(obj, Is2D)
            cmap = lines(2); 
            [~, ~, S1, S2, FGeom1, FGeom2] = obj.getConfSpace();

            obj.GeoPatch(1) = patch( ...
                'Parent',       obj.GeoAxes, ...
                'Vertices',     S1', ...
                'Faces',        FGeom1, ...
                'FaceColor',    cmap(1,:), ...
                'EdgeColor',    cmap(1,:), ...
                'FaceAlpha',    0.35, ...
                'LineWidth',    1, ...
                'DisplayName',  'Object 1');

            obj.GeoPatch(2) = patch( ...
                'Parent',       obj.GeoAxes, ...
                'Vertices',     S2', ...
                'Faces',        FGeom2, ...
                'FaceColor',    cmap(2,:), ...
                'EdgeColor',    cmap(2,:), ...
                'FaceAlpha',    0.35, ...
                'LineWidth',    1, ...
                'DisplayName',  'Object 1');

            obj.WitnessPtsLine = line( ...
                'Parent',       obj.GeoAxes, ...
                'XData',        zeros(1,2), ...
                'YData',        zeros(1,2), ...
                'ZData',        zeros(1,2), ...
                'LineWidth',    2, ...
                'Marker',       '.', ...
                'Color',        'k', ...
                'Visible',      'off', ...
                'DisplayName',  'Minimum Distance Vector');

            axis(obj.GeoAxes, 'equal');
            box( obj.GeoAxes, 'on');
            xlim(obj.GeoAxes, 'padded');
            ylim(obj.GeoAxes, 'padded');

            if ~Is2D
                set(obj.GeoAxes, 'ZTick', 0);
                zlim(obj.GeoAxes, 'padded');
                view(obj.GeoAxes, 3);
            end
        end
    end
end

