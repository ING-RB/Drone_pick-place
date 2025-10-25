classdef View < matlab.graphics.chartcontainer.ChartContainer 
    %VIEW class for viewer2 and viewer3   

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties 
    properties (Dependent)
        %POSE stores Position and Orientation information of shape
        % entries. The values are updated when the dependent property POSE
        % is queried.
        Pose

        %WITNESSPTS stores the witness point location of shape entries. The
        % values are updated when the dependent property WITNESSPTS is
        % queried.
        %
        %   WITNESSPTS   is a cell array of N shapes, and each cell contain
        %                a 3-by-2 matrix. The first collumn correspond to
        %                witness point on shape 1, and the second collumn
        %                correspond to witness point on shape 2
        WitnessPts
    end

    %% Private Properties
    properties (Access = private)
        %VERTICES stores the vertex coordinates for each shape at origin
        % and aligned at x-axis. 
        %
        %   Vertex coordinates is stored in a cell array N-by-1 each cell
        %   contain a 3-by-2 matrix. 
        %
        %   For 2D Shapes, each Vertex coodifnates cell contains:
        %       Two-column matrix - Each row contains the (x,y) coordinates
        %       for a vertex
        %
        %   For 3D Shapes, each Vertex coodifnates cell contains:
        %       Three-column matrix - Each row contains the (x,y,x)
        %       coordinates for a vertex
        V

        %FACES stores the connection matrix of vextex coodinates. 
        % 
        %   For 2D Shapes, FACES is a row vector.
        %   For 3D Shapes, FACES is a matrix, where each row correspond to
        %       a polygon.
        F 

        %PINTERNAL
        PInternal

        %WINTERNAL
        WInternal
    end

    %% Public Properties
    properties(Access = public,Transient,NonCopyable)
        ShapePatches        (:,1) matlab.graphics.primitive.Patch
        WitnessPtsLines     (:,1) matlab.graphics.primitive.Line
        ShapeAxes           (1,1) matlab.graphics.axis.Axes
    end
    %% Public Properties associated to Patch Property
    properties
        FaceColors  (:,3) double {mustBeInRange(FaceColors, 0, 1)}
        FaceAlphas  (:,1) double {mustBeInRange(FaceAlphas, 0, 1)}
        EdgeAlphas  (:,1) double {mustBeInRange(EdgeAlphas, 0, 1)}
    end
    %% Public Properties associated to Axes Property
    properties
        Title       (:,:) char = ''
        XLabel      (:,:) char = ''
        YLabel      (:,:) char = ''
        ZLabel      (:,:) char = ''
    end
    properties
        UserData    (:,:) 
    end
    %% Dependent Public Properties associated to Axes Property
    properties (Dependent)
        %XLIMITS sets the x-axis limits for the current axes.
        %   XLIMITS is a two-element vector of the form [xmin xmax]
        XLimits         (1,2) double
        
        %XLIMITSMODE specifies automatic or manual limit selection.
        %   'auto'      - axes is adjusted to the new data is added.
        %   'manual'    - x-axis is freeze 
        XLimitsMode     {mustBeMember(XLimitsMode, {'auto', 'manual'})}
        
        %YLIMITS sets the y-axis limits for the current axes.
        %   YLIMITS is a two-element vector of the form [ymin ymax]        
        YLimits         (1,2) double
        
        %YLIMITSMODE specifies automatic or manual limit selection.
        %   'auto'      - axes is adjusted to the new data is added.
        %   'manual'    - y-axis is freeze 
        YLimitsMode     {mustBeMember(YLimitsMode,{'auto','manual'})}

        %ZLIMITS sets the y-axis limits for the current axes.
        %   ZLIMITS is a two-element vector of the form [zmin zmax]
        ZLimits (1, 2) double
        
        %ZLIMITSMODE specifies automatic or manual limit selection.
        %   'auto'      - axes is adjusted to the new data is added.
        %   'manual'    - z-axis is freeze 
        ZLimitsMode {mustBeMember(ZLimitsMode, {'auto', 'manual'})}

        %todo: Nice to add XLimitMethod, YLimitMethod, and ZLimitMethod
    end
    %%
    properties (Access = protected)
        ChartState = []
    end

    %% Public Methods
    methods
        function obj = View(shape, varargin)
            %VIEW Plot shapes. 
            %   VIEW(SHAPE) constructor of sublclass ChartContainer,
            %   where SHAPE is a single or collection of shapes.
            %
            %   VIEW(___,NAME,VALUE) specifies Axes, Path, or Line
            %   properties using one or more name-value arguments.

            % todo: Check inputs

            if ~iscell(shape)
                shape = {shape};
            end
                
            % Extract Pose
            P = controllib.internal.gjk.View.extractPose(shape);

            % Convert Pose into name-value pairs
            args = {'Pose', P};

            % Combine args with user-provided name-value pairs
            args = [args varargin];

            % Call superclass constructor method
            obj@matlab.graphics.chartcontainer.ChartContainer(args{:});

            % Store shape 'Vertices' and 'Faces' for Patch Plots
            [V, F] = deal(cell(numel(shape), 1));

            for ks = 1:numel(shape)
                [V{ks}, F{ks}] = shape{ks}.generateMesh();

                if size(V{ks},1) == 2
                    V{ks}(3,:) = 0;
                end
            end
            [obj.V, obj.F] = deal(V, F);
        end
    end

    %% Protected Methods
    methods(Access = protected)

        function setup(obj)
            % SETUP setup - Executes once when the chart is created. It
            % minimally configures the layout and the axes. The 'line' and
            % 'patch' handles are defined during updating stage. 
            
            % Get the axes
            obj.ShapeAxes = getAxes(obj);
            % Set axis aspect ratios, and display axes outline.
            axis(obj.ShapeAxes, 'equal');
            box (obj.ShapeAxes,  'on'  );
            % Load state of the axes.
            loadstate(obj);
        end

        function update(obj)
            %UPDATE Update instance of chart container after setting properties
            %in "setup". Graphics object is updated after:
            %   - New property assigned
            %   - During the next drawnow execution
            %   - After user performing property values change

            %% Create extra 'patch' if necessary.
            % Find the number of existent 'patch' plots and entry shapes.
            p = obj.ShapePatches;
            mShapesEntries = numel(obj.V);
            mShapesPatches = numel(p);
            % Add patchs if mShapesPatches < mShapesEntries
            hold(obj.ShapeAxes, "on")
            for ip = (mShapesPatches+1):mShapesEntries
                p(ip) = patch( ...
                    'Parent',       obj.ShapeAxes, ...
                    'Vertices',     obj.V{ip}', ...
                    'Faces',        obj.F{ip}, ...
                    'FaceColor',    lines(1), ...
                    'EdgeColor',    lines(1), ...
                    'FaceAlpha',    0.35, ...
                    'LineWidth',    1, ...
                    'DisplayName',  ['Object ' num2str(ip)]);
            end
            hold(obj.ShapeAxes, "off")

            %% Create extra 'Lines' if necessary.
            % Find the number of Witness Points and Existent 'line' plots
            mWPtsEntrs = numel(obj.WitnessPts);
            mWPtsLines = numel(obj.WitnessPtsLines);
            % Add lines if mWPtsLines < mWPtsEntrs
            hold(obj.ShapeAxes, "on")
            for il = (mWPtsLines+1):mWPtsEntrs
                obj.WitnessPtsLines(il) = line(...
                    'Parent',       obj.ShapeAxes, ...
                    'XData',        zeros(2, 1), ...
                    'YData',        zeros(2, 1), ...
                    'Color',        [.3 .3 .3], ...
                    'MarkerSize',   10,  ...
                    'LineWidth',    1,   ...
                    'LineStyle',    ':', ...
                    'Marker',       '.');
            end
            hold(obj.ShapeAxes, "off")

            %% Extract Patch Properties
            % Extract Path and Line Properties if provided by user.
            % Otherwise, use the following defaults values:
            %   - FaceColor and Edgecolor: 'lines()' colormap array
            %   - FaceAlpha = 0.45
            %   - EdgeAlpha = 0.35
            if isempty(obj.FaceColors)
                obj.FaceColors = lines( mShapesEntries );
            end
            if isempty(obj.FaceAlphas)
                obj.FaceAlphas =  ones( mShapesEntries, 1)*0.35;
            end
            if isempty(obj.EdgeAlphas)
                obj.EdgeAlphas =  ones( mShapesEntries, 1)*0.45;
            end
            % Number of user provided values for FaceColor, FaceAlpha and
            % EdgeAlpha.
            nfc = size(obj.FaceColors, 1);
            nfa = size(obj.FaceAlphas, 1);
            nfe = size(obj.EdgeAlphas, 1);

            %% Update Patch(es) (Vertex coordinates and properties)
            vert = obj.getUpdatedVertex;
            for iv = 1:numel(vert)
                p(iv).Vertices  = vert{iv}';
                p(iv).Faces     = obj.F{iv};
                p(iv).FaceColor = obj.FaceColors( min(iv, nfc), :);
                p(iv).EdgeColor = obj.FaceColors( min(iv, nfe), :);
                p(iv).FaceAlpha = obj.FaceAlphas( min(iv, nfa), 1);
                p(iv).EdgeAlpha = obj.EdgeAlphas( min(iv, nfe), 1);
            end
            obj.ShapePatches = p(1:numel(vert));

            %% Update Line handle(s)
            for iw = 1:numel(obj.WitnessPts)
                obj.WitnessPtsLines(iw).XData = obj.WitnessPts{iw}(1, :);
                obj.WitnessPtsLines(iw).YData = obj.WitnessPts{iw}(2, :);
                if size(obj.WInternal{iw},1) > 2
                    obj.WitnessPtsLines(iw).ZData = obj.WitnessPts{iw}(3, :);
                end
            end

            %% Update Chart title
            title(obj.ShapeAxes, obj.Title);
            xlabel(obj.ShapeAxes, obj.XLabel);
            ylabel(obj.ShapeAxes, obj.YLabel);
            % zlabel(obj.Ax, obj.ZLabel);
        end
   
    end

    methods(Access = protected)
        function propgrp = getPropertyGroups(obj)
            if ~isscalar(obj)
                % List for array of objects
                propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                % List for scalar object
                propList = {'Pose','Patches'};
                propgrp = matlab.mixin.util.PropertyGroup(propList);
            end
        end
    end
    %% Public Methods
    methods
        function data = get.ChartState(obj)
            isLoadedStateAvailable = ~isempty(obj.ChartState);

            if isLoadedStateAvailable
                data = obj.ChartState;
            else
                data = struct;
                ax = getAxes(obj);

                % Get axis limits only if mode is manual.
                if strcmp(ax.XLimMode,'manual')
                    data.XLimits = obj.XLimits;
                end
                if strcmp(ax.YLimMode,'manual')
                    data.YLimits = obj.YLimits;
                end

                data.VRef = obj.V;
                data.PInternal = obj.PInternal;

                if isa(obj,'controllib.internal.gjk.Viewer3')
                    if strcmp(ax.ZLimMode,'manual')
                    data.ZLimits = obj.ZLimits;
                    end
                    data.FRef = obj.F;
                end

                % No ViewMode to check. Store the view anyway.
                data.View = ax.View;
            end
        end

        function loadstate(obj)
            data=obj.ChartState;
            ax = getAxes(obj);

            % Look for states that changed
            if isfield(data, 'XLimits')
                obj.XLimits = data.XLimits;
            end
            if isfield(data, 'YLimits')
                obj.YLimits = data.YLimits;
            end
            if isfield(data, 'ZLimits')
                obj.ZLimits = data.ZLimits;
            end
            if isfield(data, 'View')
                ax.View = data.View;
            end

            % Reset ChartState to empty
            obj.ChartState=[];
        end
    end

    methods
        function V = getUpdatedVertex(obj)
            %GETUPDATEDVERTEX Perform rotation and translation of Vertices
            %vector: UpdatedVertice = Rotz*V+Trans

            % Number of Shapes
            ns = size(obj.PInternal, 3);

            % Preallocate Vertices
            V = cell(ns,1);

            % Apply transformation
            for is = 1:ns
                V{is} = obj.PInternal(1:3, 1:3, is)*obj.V{is} + ...
                    obj.PInternal(1:3, 4, is);
            end
        end
    end

    methods (Static)
        function P = extractPose(shape)
            %EXTRACTPOSE Return pose information for shape entries as a
            % 4-by-4-by-n matrix of n homogeneous transformations.
            
            if shape{1}.Is2D
                % This is a 3-step 
                % 
                % 1: Extract Pose into a N-by-3 matrix. Each row contains
                % (X,Y,THETA) information.
                %
                % 2: Allocate a 4-by-4-by-n P matrix.
                %
                % 3: Update P matrix (Rotation and Translation Matrix)

                nShapes = numel(shape);

                % Pose N-by-3 matrix, where <x,y,theta>
                pNby3 = cell2mat( ...
                    cellfun(@(kShp) vertcat([kShp.X kShp.Y kShp.Theta]), ...
                    shape, 'UniformOutput', false)');

                % Allocate Pose Matrix
                P = repmat(eye(4,'like',pNby3),[1,1,nShapes]);

                % Update Posistion
                P(1:2,end,:) = pNby3(:, 1:2).';
                
                % Update Orientation
                cost     = cos(pNby3(:, 3));
                sint     = sin(pNby3(:, 3));

                P(1,1,:) =  cost.';
                P(1,2,:) = -sint.';
                P(2,1,:) =  sint.';
                P(2,2,:) =  cost.';
            else
                gcell = cellfun(@(kShp) reshape(kShp.Pose, 4, 4, []), ...
                    shape, 'UniformOutput', false);
                P = cat(3, gcell{:});
            end

        end
    end

    methods
        function updatePose(obj, shape)
            if ~iscell(shape)
                obj.Pose = {shape};
            end
            obj.PInternal = obj.extractPose(shape);
        end
        
        function set.Pose(obj,p)
            obj.PInternal = p;
        end
        function p = get.Pose(obj)
            p = obj.PInternal;
        end
        function set.WitnessPts(obj, w)
            if iscell(w)
                obj.WInternal = w;
            else
                obj.WInternal = {w};
            end
        end
        function w = get.WitnessPts(obj)
            w = obj.WInternal;
        end
    end

    %% Public Methods for enabled convenience functions
    methods
        % xlim method
        function varargout = xlim(obj,varargin)
            ax = getAxes(obj);
            [varargout{1:nargout}] = xlim(ax,varargin{:});
        end
        % ylim method
        function varargout = ylim(obj,varargin)
            ax = getAxes(obj);
            [varargout{1:nargout}] = ylim(ax,varargin{:});
        end
        % zlim method
        function varargout = zlim(obj,varargin)
            ax = getAxes(obj);
            [varargout{1:nargout}] = zlim(ax,varargin{:});
        end

        % xlabel method
        function varargout = xlabel(obj,varargin)
            ax = getAxes(obj);
            [varargout{1:nargout}] = xlabel(ax,varargin{:});
        end
        % ylabel method
        function varargout = ylabel(obj,varargin)
            ax = getAxes(obj);
            [varargout{1:nargout}] = ylabel(ax,varargin{:});
        end
        % zlabel method
        function varargout = zlabel(obj,varargin)
            ax = getAxes(obj);
            [varargout{1:nargout}] = zlabel(ax,varargin{:});
        end

        % view method
        function varargout = view(obj,varargin)
            ax = getAxes(obj);
            [varargout{1:nargout}] = view(ax,varargin{:});
        end
        % title method
        function title(obj,txt)
            obj.Title = txt;
        end
    end

    %% Set and Get Methods for Dependent Properties
    methods
        %%  Set and Get methods for XLimits and XLimitsMode
        function set.XLimits(obj,xlm)
            ax = getAxes(obj);
            ax.XLim = xlm;
        end
        function xlm = get.XLimits(obj)
            ax = getAxes(obj);
            xlm = ax.XLim;
        end
        function set.XLimitsMode(obj,xlmmode)
            ax = getAxes(obj);
            ax.XLimMode = xlmmode;
        end
        function xlm = get.XLimitsMode(obj)
            ax = getAxes(obj);
            xlm = ax.XLimMode;
        end

        %% Set and Get methods for YLimits and YLimitsMode
        function set.YLimits(obj,ylm)
            ax = getAxes(obj);
            ax.YLim = ylm;
        end
        function ylm = get.YLimits(obj)
            ax = getAxes(obj);
            ylm = ax.YLim;
        end
        function set.YLimitsMode(obj,ylmmode)
            ax = getAxes(obj);
            ax.YLimMode = ylmmode;
        end
        function ylm = get.YLimitsMode(obj)
            ax = getAxes(obj);
            ylm = ax.YLimMode;
        end

        %% Set and Get methods for ZLimits and ZLimitsMode
        function set.ZLimits(obj, zlm)
            ax = getAxes(obj);
            ax.ZLim = zlm;
        end
        function zlm = get.ZLimits(obj)
            ax = getAxes(obj);
            zlm = ax.ZLim;
        end
        function set.ZLimitsMode(obj, zlmmode)
            ax = getAxes(obj);
            ax.ZLimMode = zlmmode;
        end
        function zlm = get.ZLimitsMode(obj)
            ax = getAxes(obj);
            zlm = ax.ZLimMode;
        end
    end
end

