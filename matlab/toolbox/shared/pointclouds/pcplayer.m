classdef pcplayer < handle & matlab.mixin.Scalar

    % Copyright 2018-2023 The MathWorks, Inc.

    % ---------------------------------------------------------------------
    properties(GetAccess = public, SetAccess = protected, Transient)
        Axes
    end
    
    % ---------------------------------------------------------------------
    properties(Hidden, Access = protected)
        MarkerSize
        BackgroundColor
        VerticalAxis
        VerticalAxisDir
        XLimits
        YLimits
        ZLimits
        ptCloudThreshold
        AxesVisibility
        Projection
        ColorSource
        ViewPlane
    end
    
    % ---------------------------------------------------------------------
    properties(Hidden, Access = protected, Transient)
        IsInitialized = false
        Figure
        Primitive
    end
    
    % ---------------------------------------------------------------------
    methods
        % -----------------------------------------------------------------
        function this = pcplayer(varargin)
            
            params = pcplayer.parseParameters(varargin{:});
            
            initialize(this, params);
        end
        
        % -----------------------------------------------------------------
        function view(this, varargin)
            
            narginchk(2, 3);
            
            [X,Y,Z,C,map, ptCloud] = pcplayer.parseInputs(varargin{:});
            pointclouds.internal.pcui.validateColorSourceWithPC(this.ColorSource, ptCloud);            
            
            if ~ishandle(this.Axes)
                % player is in an invalid state. initialize again.
                cleanupFigure(this);
                initialize(this);
            end
            
            if ~isempty(map)
                colormap(this.Axes, map);
            end
            
            updateViewer(this, X, Y, Z, C, ptCloud);
        end
        
        % -----------------------------------------------------------------
        function tf = isOpen(this)
            if ishandle(this.Figure) && strcmpi(this.Figure.Visible,'on')
                tf = true;
            else
                tf = false;
            end
        end
        
        % -----------------------------------------------------------------
        function delete(this)
            cleanupFigure(this);
        end
        
        % -----------------------------------------------------------------
        function show(this)
            makeVisible(this);
        end
        
        % -----------------------------------------------------------------
        function hide(this)
            makeInvisible(this);
        end
        
        % -----------------------------------------------------------------
        function s = saveobj(this)
            s.MarkerSize      = this.MarkerSize;
            s.BackgroundColor = this.BackgroundColor;
            s.VerticalAxis    = this.VerticalAxis;
            s.VerticalAxisDir = this.VerticalAxisDir;
            s.XLimits         = this.XLimits;
            s.YLimits         = this.YLimits;
            s.ZLimits         = this.ZLimits;
            s.IsOpen          = isOpen(this);
            s.AxesVisibility  = this.AxesVisibility;
            s.Projection      = this.Projection;
            s.ColorSource     = this.ColorSource;
            s.ViewPlane       = this.ViewPlane;            
        end
    end
    
    % ---------------------------------------------------------------------
    methods(Hidden, Access = protected)
        
        function initialize(this, varargin)
            
            if nargin == 2
                setParams(this, varargin{1});
            end

            createFigure(this);          
            
            initializeFigure(this);
            
            this.Figure.Visible = 'on';
        end
        
        % -----------------------------------------------------------------
        function makeInvisible(this, varargin)
            % proceed if figure exists, else leave it be.
            if ishandle(this.Figure)
                this.Figure.Visible = 'off';
                drawnow;
            end
        end
        
        % -----------------------------------------------------------------
        function makeVisible(this)
            if ishandle(this.Figure)
                this.Figure.Visible = 'on';
                figure(this.Figure); % bring to front
            else
                % player is in an invalid state. initialize again.
                cleanupFigure(this);
                initialize(this);
            end
            drawnow;
        end
        
        % -----------------------------------------------------------------
        function createFigure(this)

            % Plot to the specified axis, or create a new figure with
            % hidden handle and custom name.
            if ~isempty(this.Axes) && ishghandle(this.Axes)
                newplot(this.Axes);
                
                % Get the current figure handle
                this.Figure = ancestor(this.Axes,'figure');
            else            
                % Create figure to draw into
                this.Figure = figure('Visible','off',...
                    'HandleVisibility','callback',...
                    'Name','Point Cloud Player');
                this.Axes = newplot(this.Figure);
            end
            
        end
        
        % -----------------------------------------------------------------
        function initializeFigure(this)
            
            checkRenderer(this);
            
            % create an nice empty axes
            initializeScatter3(this);
            
            % Lower and upper limit of auto downsampling.
            this.ptCloudThreshold = [1920*1080, 1e8];
            
            % Equal axis is required for cameratoolbar
            axis(this.Axes, 'equal');
            
            % set axes limits to manual
            this.Axes.XLimMode = 'manual';
            this.Axes.YLimMode = 'manual';
            this.Axes.ZLimMode = 'manual';
            
            % set view angle to auto to ensure a pleasant view point
            % after setting axis limits.
            this.Axes.CameraViewAngleMode = 'auto';
            
            % set limits
            xlim(this.Axes, this.XLimits);
            ylim(this.Axes, this.YLimits);
            zlim(this.Axes, this.ZLimits);
            
            % Initialize point cloud viewer controls.
            params.VerticalAxis       = this.VerticalAxis;
            params.VerticalAxisDir    = this.VerticalAxisDir;
            params.BackgroundColor    = this.BackgroundColor;
            params.AxesVisibility     = this.AxesVisibility;
            params.Projection         = this.Projection;
            params.PtCloudThreshold   = this.ptCloudThreshold;
            params.ColorSource        = this.ColorSource;
            params.ViewPlane          = this.ViewPlane;

            pointclouds.internal.pcui.initializePCSceneControl(...
                this.Figure, this.Axes, this.Primitive, params);
            
            drawnow; % to make sure camera position changes take effect
            
            % Decorate axes
            xlabel(this.Axes, 'X');
            ylabel(this.Axes, 'Y');
            zlabel(this.Axes, 'Z');
            
            grid(this.Axes, 'on');
            
            attachCallbacks(this);
            
            makeVisible(this);
            
            % save the current view. This allows cameratoolbar's reset
            % button to restore the original view.
            resetplotview(this.Axes,'SaveCurrentView');
            
            this.IsInitialized = true;
        end
        
        % -----------------------------------------------------------------
        function updateViewer(this, X, Y, Z, C, ptCloud)
            if this.isOpen
                checkRenderer(this);
                updateScatter3(this, X, Y, Z, C, ptCloud);
            end
        end
        
        % ------------------------------------------------------------------
        function attachCallbacks(this)
            this.Figure.CloseRequestFcn = @pcplayer.makeFigureInvisible;
        end
        
        % ------------------------------------------------------------------
        function cleanupFigure(this,varargin)
            delete(this.Axes);
            delete(this.Figure);
        end
        
        % ------------------------------------------------------------------
        function setParams(this, params)
            this.MarkerSize      = double(params.MarkerSize);
            this.BackgroundColor = params.BackgroundColor;
            this.VerticalAxis    = params.VerticalAxis;
            this.VerticalAxisDir = params.VerticalAxisDir;
            this.Projection      = params.Projection;
            this.AxesVisibility  = params.AxesVisibility;
            this.ColorSource     = params.ColorSource;
            this.ViewPlane       = params.ViewPlane;
            
            this.XLimits = double(params.XLimits);
            this.YLimits = double(params.YLimits);
            this.ZLimits = double(params.ZLimits);
            
            this.Axes = params.Parent;
        end
        
        % -----------------------------------------------------------------
        function checkRenderer(this)
            % JSD_OGL_REMOVAL
            % After OpenGL Removal, setting renderer property becomes no-op
            if ~feature('webui') && strcmpi(this.Figure.Renderer, 'painters')
                error(message('vision:pointcloud:badRenderer'));
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % scatter3 based implementation
    % ---------------------------------------------------------------------
    methods(Hidden, Access = protected)
        
        function initializeScatter3(this)
            
            % produce an empty initial axes
            this.Primitive = scatter3(this.Axes, nan, nan, nan, ...
                this.MarkerSize, nan, '.', 'Tag', 'pcviewer');
            
            % Prevent extent checks when limits are not automatically
            % adjusted.
            this.Primitive.XLimInclude = 'off';
            this.Primitive.YLimInclude = 'off';
            this.Primitive.ZLimInclude = 'off';
        end
        
        % -----------------------------------------------------------------
        function updateScatter3(this, X, Y, Z, C, ptCloud)
            
            this.Primitive.XData = X;
            this.Primitive.YData = Y;
            this.Primitive.ZData = Z;
            
            if isempty(C)
                colorData = [];
            else
                if isempty(ptCloud.Color) && isempty(ptCloud.Intensity)
                    colorData = C;
                else
                    % This means point cloud object holds the color information
                    colorData = [];
                end
            end
            
            this.Primitive.CData = colorData;
            
            pointclouds.internal.pcui.utils.setAppData(this.Primitive, 'PointCloud', ptCloud);
            pointclouds.internal.pcui.utils.setAppData(this.Primitive, 'ColorData', colorData);
            
            udata = pointclouds.internal.pcui.utils.getAppData(this.Axes, 'PCUserData');
            urcolor = udata.ColorContextMenu;
            
            % Set the color context menu
            if strcmpi(urcolor.Visible, 'off')
                pointclouds.internal.pcui.updateColorContextMenu(this.Figure);
            end
            
            % Set the color map preference to the app data. 
            isSetColorMap = ~isempty(udata.colorMapData);
            userInput = ~isempty(colorData);
            
            % If the color map preference is not set then set it. If there
            % is a user input, set the color map preeference
            if ~isSetColorMap || userInput
                pointclouds.internal.pcui.setColorMapData(this.Axes, this.ColorSource);
                udata = pointclouds.internal.pcui.utils.getAppData(this.Axes, 'PCUserData');
            end
            
            % Change the color data as per the chosen color
            pointclouds.internal.pcui.changeColor(this.Axes, udata.colorMapData);
            
            % maximize frame rate while handling mouse events
            drawnow('limitrate');
        end
    end
    
    % ---------------------------------------------------------------------
    methods(Static,Hidden)
        function this = loadobj(s)

            % Populate the following properties added in a later version of
            % pcplayer
            if ~isfield(s, 'AxesVisibility')
                s.AxesVisibility = 'on';
                s.Projection = 'orthographic';
                s.ColorSource = 'auto';
                s.ViewPlane = 'auto';
            end

            this = pcplayer(s.XLimits, s.YLimits, s.ZLimits, ...
                'MarkerSize', s.MarkerSize, 'VerticalAxis', s.VerticalAxis, ...
                'VerticalAxisDir', s.VerticalAxisDir, 'BackgroundColor', s.BackgroundColor,...
                'AxesVisibility', s.AxesVisibility, 'Projection', s.Projection,...
                'ColorSource', s.ColorSource, 'ViewPlane', s.ViewPlane);
            
            if ~s.IsOpen
                hide(this);
            end
        end
        % -----------------------------------------------------------------
        function makeFigureInvisible(varargin)
            % callback attached to figure close request function
            set(gcbo,'Visible','off');
            drawnow;
        end
    end
    
    % ---------------------------------------------------------------------
    methods(Hidden, Static, Access = protected)
        
        function [X, Y, Z, C, map, ptCloud] = parseInputs(varargin)
            
            if isa(varargin{1}, 'pointCloud')
                narginchk(1,1);
                [X, Y, Z, C, map, ptCloud] = pointclouds.internal.pcui.validateAndParseInputsXYZC(mfilename, varargin{1});
            else
                narginchk(1,2);
                [X, Y, Z, C, map, ptCloud] = pointclouds.internal.pcui.validateAndParseInputsXYZC(mfilename, varargin{:});
            end
            
            if ischar(C) || isstring(C)
                C = pointclouds.internal.pcui.colorspec2RGB(C);
            end            
        end
        
        % ------------------------------------------------------------------
        function params = parseParameters(varargin)
            
            % Turn on the axes visibility for pcplayer.
            axesVisibility = 'on';

            parser = pointclouds.internal.pcui.getSharedParamParser(mfilename,axesVisibility);
            
            parser.addParameter('Parent', [], @(p)validateAxesHandle(p));
            parser.addRequired('XLimits', @(x)pcplayer.checkLimits('XLimits',x));
            parser.addRequired('YLimits', @(x)pcplayer.checkLimits('YLimits',x));
            parser.addRequired('ZLimits', @(x)pcplayer.checkLimits('ZLimits',x));
            
            parser.parse(varargin{:});
            
            params = parser.Results;
            
        end
        
        %------------------------------------------------------------------
        function checkLimits(varname, range)
            validateattributes(range, {'numeric'}, ...
                {'vector', 'numel', 2, 'finite', 'real', 'nonsparse', 'increasing'}, ...
                mfilename, varname);
        end     
    end    
end
%--------------------------------------------------------------------------
function validateAxesHandle(ax)
if ~(isscalar(ax) && ishghandle(ax, 'axes'))
    error(message('vision:validation:invalidAxesHandle'));
end
end
