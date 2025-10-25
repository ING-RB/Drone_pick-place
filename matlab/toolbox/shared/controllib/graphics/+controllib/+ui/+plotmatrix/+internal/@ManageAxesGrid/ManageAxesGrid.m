classdef ManageAxesGrid < handle
    %
    
    % MANAGEAXESGRID Manage layout and properties of a grid of axes.
    
    % This class provides methods to Add, Remove, Hide, Show axes. It also
    % provides a mechanism to modify each axis' properties such as Limits,
    % Scale, Grid, Labels, Title by modifying the properties of the grid
    % itself.
    
    % Copyright 2014-2022 The MathWorks, Inc.
    
    properties (Access = private)
        BackgroundAxes
        AxesGrid            % ctrluis.axesgrid - the engine for core axes
        PeripheralAxes      % The engine for peripheral axes
        % Struct array with four columns
        % Fields:
        % AxesGrid
        % Location
        
        LabelSharing        % Sharing for label - depending on type of plot
        
        Ruler = struct('Right', gobjects(0), 'Top', gobjects(0)) % Create and store rulers for parenting to axes when needed
        
        HistogramAxes       % Set of axes to place histogram
        HistogramListeners
        DeleteListener
    end
    
    properties (Dependent = true)
        % Grid Lines. Set to 'on' to add major grid lines to all the axes
        % in the figure.
        Grid
        
        % Set the figure title
        Title
        
        Parent
        
        % Defines spacing between the axes in axes grid. Geometry is a
        % structure containing the following fields:
        %   HorizontalGap: horizontal spacing of axes in pixels
        %   LeftMargin: Additional margin along left border
        %   TopMargin: Additional margin along top border
        %   VerticalGap: vertical spacing of axes in pixels
        Geometry
        
        % X-Axes properties
        
        % Can be set to 'Default' or 'All'. Decides how XLim and XScale are
        % shared amongst the axes in a grid. When set to 'Default', all the
        % axes in a given column, have the same XLim and XScale. When set
        % to 'All', all the axes in the figure have the same XLim and
        % XScale.
        XAxesSharing
        
        % Specify the x limits of any axes in the figure
        % XLim is an n-by-m cell array of 1-by-2 vectors,
        %            n - number of columns of axes
        %            m - number of rows of axes
        XLim
        
        
        % Specify the scale of any X-axes in the axes grid
        % XScale is an n-by-m cell array of strings ('log' or 'linear'),
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        XScale
        
        % Specify the label for X-axes in the axes grid.
        % XLabel is an n-by-m cell array of strings
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        XLabel
        
        % Y-Axis properties
        
        % Can be set to 'Default' or 'All'. Decides how YLim and YScale are
        % shared amongst the axes in a grid. When set to 'Default', all the
        % axes in a given row, have the same YLim and YScale. When set
        % to 'All', all the axes in the figure have the same YLim and
        % YScale.
        YAxesSharing
        
        % Specify the y limits of any axes in the figure
        % YLim is an n-by-m cell array of 1-by-2 vectors,
        %            n - number of columns of axes
        %            m - number of rows of axes
        YLim
        
        % Specify the scale of any Y-axes in the axes grid
        % YScale is n-by-m cell array of strings ('log' or 'linear'),
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        YScale
        
        % Specify the label for Y-axes in the axes grid.
        % YLabel is an n-by-m cell array of strings
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        YLabel
        
        % Specify Size and position of the axes grid (in normalized units)
        % within the figure or uipanel that contains the axes, specified as
        % a four-element vector of the form [left bottom width height]. The
        % left and bottom elements define the distance from the lower-left
        % corner of the container to the lower-left corner of the axes. The
        % width and height elements are the axes dimensions.
        Position

    end

    properties (Dependent, GetAccess=private)
        % Index of axes that do not share limits, scale
        IndependentAxes
    end
    
    properties (Access = public)
        % Specify the visibility of any axes in the axes grid
        % AxesVisibility is n-by-m cell array of strings ('on' or 'off'),
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        AxesVisibility
        
        
        % Specify whether the diagonal axes should participate in limit
        % sharing. Example, set to true when histograms are along diagonal
        % axes.
        DiagonalAxesSharing = 'Both'
        
                
        % Specify what interpreter to use for the XLabel, YLabel and Title.
        % Valid values include - 'none','tex','latex'
        Interpreter = 'tex'
    end

    % CONSTRUCTOR AND FUNCTION SIGNATURES
    methods
        %% CONSTRUCTOR
        function this = ManageAxesGrid(varargin)
            % MANAGEAXESGRID Construct ManageAxesGrid
            %
            %    obj = ManageAxesGrid(nRows, nColumns)
            %    Inputs:
            %      nRows    - Number of rows in the grid
            %      nColumns - Number of columns in the grid
            %
            %    obj = ManageAxesGrid(n)
            %    Inputs:
            %      n - Number of rows and columns in the grid (Produces a
            %      square grid)
            %
            %    obj = ManageAxesGrid
            %       Constructs a default grid with one row and one column.
            %
            
            % Check number of Inputs
            narginchk(0,6);
            
%             if nargin == 0
%                 % If no inputs are given, construct a 1-by-1 axes grid by
%                 % default
%                 nRows = 1;
%                 nCols = 1;
%             elseif nargin == 1
%                 % One input - equal number of rows and columns
%                 nRows = varargin{1};
%                 nCols = varargin{1};
%             elseif nargin == 2
%                 % nRows and nCols
%                 nRows = varargin{1};
%                 nCols = varargin{2};
%             elseif nargin == 3
%                 % nRows and nCols
%                 nRows = varargin{1};
%                 nCols = varargin{2};
%             end

            p = inputParser;
            p.addOptional('nRows',1)
            p.addOptional('nCols',[])
            p.addParameter('BackgroundAxes',true)
            p.addParameter('Parent',[])
            parse(p,varargin{:});
            
            if isempty(p.Results.nCols)
                nCols = p.Results.nRows;
            else
                nCols = p.Results.nCols;
            end

            % Validate nRows and nCols
            controllib.ui.plotmatrix.internal.ManageAxesGrid.localCheckFcn(p.Results.nRows);
            controllib.ui.plotmatrix.internal.ManageAxesGrid.localCheckFcn(nCols);
            
            % If validated, create the axes grid
                        
            if isempty(p.Results.Parent)
                h = axes;
            else
                h = axes('Parent',p.Results.Parent);
            end
            AG = ctrluis.axesgridPlotmatrix([p.Results.nRows, nCols], h);

            % Set label location
            AG.ColumnLabelStyle.Location = 'bottom';
            AG.ColumnLabelStyle.Location = 'left';
            % Axes created successfully
            this.AxesGrid = AG;
            % add object being destroyed listener
            this.DeleteListener = handle.listener(AG,'ObjectBeingDestroyed',@(es,ed)delete(this));
            
            if p.Results.BackgroundAxes
                createBackgroundAxes(this);
            end
            
            % Set the position
            % this.Position = this.AxesGrid.BackgroundAxes.Position;
            
            % Label Sharing depending on type of plot
            this.LabelSharing = 'default';

        end

        function toggleToolbar(this,onoff)

            ax1 = getAxes(this);
            ax2 = getaxes(this.AxesGrid);
            ax = [ax1(:), ax2(:)];
            for ct=1:numel(ax)
                ax(ct).Toolbar.Visible = onoff;
            end
        end
        
        %% FUNCTION SIGNATURES
        % ADDITION
        addAxes(this, varargin);
        
        % REMOVAL
        removeAxes(this, varargin);
        
        % RESIZE
        resize(this, varargin);
        
        % Size
        varargout = size(this, varargin)
        
        % Return axes
        Axes = getAxes(this,BackAxFlag)
        
        % Return menu anchor
        Anchor = getMenuAnchor(this)
            
    end
    
    % GETTERS AND SETTERS
    methods
        %% Background axes
        function createBackgroundAxes(this)
            if isempty(this.BackgroundAxes)
                %                 % Create background axes for positioning and legend
                this.BackgroundAxes = axes('Parent',double(this.AxesGrid.Parent),'Visible','off','HandleVisibility','off',...
                    'Xlim',[0 1],'Ylim',[0 1],'XTick',[],'YTick',[],'XTickLabel',[],'YTickLabel',[],...
                    'Position',this.AxesGrid.Position,'HitTest','off');
            end
            %             Axes = this.BackgroundAxes;
        end
        %% Position
        function set.Position(this, Position)
            % SET Position - Specify Size and position of the axes grid
            % within the figure or uipanel that contains the axes,
            % specified as a four-element vector of the form [left bottom
            % width height].
            CurrentPosition = this.Position;
            try
                layout(this, Position);
                if ~isempty(this.BackgroundAxes)
                    this.BackgroundAxes.Position = Position;
                end
            catch
                this.Position = CurrentPosition;
            end
        end
        
        function Position = get.Position(this)
            if isempty(this.BackgroundAxes)
                Position = this.AxesGrid.Position;
            else
                Position = this.BackgroundAxes.Position;
            end
        end
        
        %% Independent axes
        function set.IndependentAxes(this, Idx)
            this.AxesGrid.LimitFcn = {@customUpdateLimits this Idx};
        end
        
        %% Axes Visibility
        function AV = get.AxesVisibility(this)
            % GET AxesVisibility -  Return current AxesVisibility
            %     Output: AxesVisibility - n-by-m logical cell-array ('on'
            %                              or 'off')
            %                    n - number of columns in axesgrid
            %                    m - number of rows in axesgrid
            
            % Get all the axes
            AllAxes = getAxes(this);
            [nR,nC] = size(this);
            
            % Return visibility
            AV = reshape({AllAxes.Visible},nR,nC);
        end
        
        function set.AxesVisibility(this, AxesVisibility)
            % SET AxesVisibility - Set the visibility of axes in the axes grid
            %     Input: AxesVisibility - n-by-m logical cell-array ('on'
            %                              or 'off')
            %                    n - number of columns in axesgrid
            %                    m - number of rows in axesgrid
            
            % Get all the axes
            % Update RowVisible and ColumnVisible property of AxesGrid
            % according to AllVisibleAxes - This has to be done before
            % turning off visibility for invisible axes, as setting
            % RowVisible and ColumnVisible overrides setting the visibility
            % of the axes directly.
            setRowColumnVisible(this, AxesVisibility);
            
            AllAxes = getaxes(this.AxesGrid); %#ok<MCSUP>
            
            % Find indices of visible axes
            
            
            % Apply new visibility to HG axes and set zoom property
            % based on visibility of axis
            AllVisibleAxes = AllAxes(strcmp(AxesVisibility,'on'));
            
            % Turn on visibility
            set(AllVisibleAxes,'Visible','on','ContentsVisible','on');
            bh = hgbehaviorfactory('Zoom');
            set(bh, 'Enable', true);
            hgaddbehavior(AllVisibleAxes,bh);
            
            % find indices of invisible axes
            NotVisIdx = strcmp(AxesVisibility,'off');
            AllInvisibleAxes = AllAxes(NotVisIdx);
            
            % Turn off legends
            %             legend(AllInvisibleAxes,'hide')
            
            % Turn off visibility
            set(AllInvisibleAxes,'Visible','off','ContentsVisible','off');
            bh = hgbehaviorfactory('Zoom');
            set(bh, 'Enable', false);
            hgaddbehavior(AllInvisibleAxes,bh);
            
            % Set the AxesVisibility property
            this.AxesVisibility = AxesVisibility;
            
            setTickMarks(this);
            
            this.notify('VisibilityChanged');
        end
        
        %% Grid
        function GridValue = get.Grid(this)
            % GET Grid - Return Grid from AxesGrid
            %     Output: Grid - 1-by-1 Logical ('on' or 'off')
            GridValue = this.AxesGrid.Grid;
        end
        
        function set.Grid(this, GridValue)
            % SET Grid - Turn on/ off grid
            %     Input: Grid - 1-by-1 Char ('on' or 'off')
            
            % Pass-through to axes grid
            setGrid_(this, GridValue);
            this.notify('GridChanged');
        end
        
        %% Geometry
        function set.Geometry(this, GeometryValue)
            % SET Geometry - Set spacing for axes grid
            
            % Pass through
            if isstruct(GeometryValue) && isequal(fieldnames(this.Geometry), fieldnames(GeometryValue))
                this.AxesGrid.Geometry = GeometryValue;
            else
                error(message('Controllib:general:UnexpectedError', ...
                    'Geometry should be a structure with fields HeightRatio, HorizontalGap, LeftMargin, TopMargin, VerticalGap'));
            end
        end
        
        function GeometryValue = get.Geometry(this)
            % GET Geometry - Return current geometry values for axes grid
            GeometryValue = this.AxesGrid.Geometry;
        end
        
        %% Sharing
        function set.XAxesSharing(this, SharingValue)
            % SET XAxesSharing - Set the sharing to Default or All
            
            % Validate sharing
            controllib.ui.plotmatrix.internal.ManageAxesGrid.localValidateSharing(SharingValue);
            % Pass through to AxesGrid
            if strcmpi(SharingValue, 'default')
                SharingValue = 'column';
            end
            this.AxesGrid.XLimSharing = SharingValue;
        end
        
        function SharingValue = get.XAxesSharing(this)
            % GET XAxesSharing - Return current XAxesSharing
            SharingValue = this.AxesGrid.XLimSharing;
            if strcmpi(SharingValue, 'Column')
                SharingValue = 'Default';
            end
        end
        
        function set.YAxesSharing(this, SharingValue)
            % SET YAxesSharing - Set the sharing to Default or All
            
            % Validate sharing
            controllib.ui.plotmatrix.internal.ManageAxesGrid.localValidateSharing(SharingValue);
            % Pass through to AxesGrid
            if strcmpi(SharingValue, 'default')
                SharingValue = 'row';
            end
            this.AxesGrid.YLimSharing = SharingValue;
        end
        
        function SharingValue = get.YAxesSharing(this)
            % GET YAxesSharing - Return current YAxesSharing
            SharingValue = this.AxesGrid.YLimSharing;
            if strcmpi(SharingValue, 'row')
                SharingValue = 'Default';
            end
        end
        
        
        %% Limits
        function XLim = get.XLim(this)
            % GET XLim - Return current XLim
            %     Output: XLim - n-by-m cell array of 1-by-2 vectors,
            %                    n - number of columns in axesgrid
            %                    m - number of rows in axesgrid
            
            % Get the size
            [nR, nC] = size(this);
            
            % Get XLim from Axes Grid
            XLim = this.AxesGrid.getxlim;
            if strcmpi(this.DiagonalAxesSharing,'XOnly')
                ax = this.AxesGrid.getaxes;
                if nR>1
                    XLim{1} = ax(2,1).XLim;
                else
                    % 1-by-1 plot - only the histogram is visible
                    XLim{1} = this.HistogramAxes(1).XLim;
                end
            end
            % Reshape
            % There is one element for each column - repeat for each row to
            % get a property equal to the size of axes grid.
            if iscell(XLim)
                % Sharing is set to column
                XLim = XLim';
                XLim = repmat(XLim, nR, 1);
            else
                % Sharing is set to all
                XLim = repmat({XLim}, nR, nC);
            end
        end
        
        function set.XLim(this, NewValue)
            % SET XLim - Set the XLim of axes in the axes grid
            %     Input: XLim - n-by-m cell array of 1-by-2 vectors,
            %                    n - number of columns in axesgrid
            %                    m - number of rows in axesgrid
            
            setPropertyValue(this, 'XLim', NewValue, @setXLim_, 'XAxesSharing');
            this.notify('XLimChanged');
        end
        
        function YLim = get.YLim(this)
            % GET YLim - Return current YLim
            %     Output: YLim - n-by-m cell array of 1-by-2 vectors,
            %                    n - number of columns in axesgrid
            %                    m - number of rows in axesgrid
            
            % Get size and current value from axes grid
            [nR, nC] = size(this);
            YLim = this.AxesGrid.getylim;
            if strcmpi(this.DiagonalAxesSharing,'XOnly')
                ax = this.AxesGrid.getaxes;
                if nC>1
                    YLim{1} = ax(2,1).YLim;
                else
                    % 1-by-1 plot - only the histogram is visible
                    YLim{1} = this.HistogramAxes(1).XLim;
                end
            end
            % Reshape
            % There is one element for each row - repeat for each row to
            % get a property equal to the size of axes grid.
            if iscell(YLim)
                % Sharing is set to row
                YLim = repmat(YLim, 1, nC);
            else
                % Sharing is set to all
                YLim = repmat({YLim}, nR, nC);
            end
        end
        
        function set.YLim(this, NewValue)
            % SET YLim - Set the YLim of axes in the axes grid
            %     Input: YLim - n-by-m cell array of 1-by-2 vectors,
            %                    n - number of columns in axesgrid
            %                    m - number of rows in axesgrid
            
            setPropertyValue(this, 'YLim', NewValue, @setYLim_, 'YAxesSharing');
            this.notify('YLimChanged');
        end
        
        %% Scale
        function XScale = get.XScale(this)
            % GET XScale - Return current XScale
            %     Output: XScale - n-by-m cell array of strings ('log' or
            %                     'linear'
            %                      n - number of columns in axesgrid
            %                      m - number of rows in axesgrid
            
            % Get size and current value from axes grid
            [nR, ~] = size(this);
            XScale = this.AxesGrid.XScale;
            % There is one element for each column - repeat for each row to
            % get a property equal to the size of axes grid.
            % Limit is shared across column - repeat for each cell
            XScale = XScale';
            XScale = repmat(XScale, nR, 1);
        end
        
        function set.XScale(this, NewValue)
            % SET Scale - Set the XScale of axes in the axes grid
            %     Input: XScale - n-by-m cell array of strings ('log' or
            %                     'linear'
            %                      n - number of columns in axesgrid
            %                      m - number of rows in axesgrid
            
            setPropertyValue(this, 'XScale', NewValue, @setXScale_, 'XAxesSharing');
            this.notify('XScaleChanged');
        end
        
        function YScale = get.YScale(this)
            % GET YScale - Return current YScale
            %     Output: YScale - n-by-m cell array of strings ('log' or
            %                     'linear'
            %                      n - number of columns in axesgrid
            %                      m - number of rows in axesgrid
            
            % Get size and current value from axes grid
            [~, nC] = size(this);
            YScale = this.AxesGrid.YScale;
            % There is one element for each row - repeat for each row to
            % get a property equal to the size of axes grid.
            % Limit is shared across column - repeat for each cell
            YScale = repmat(YScale, 1, nC);
        end
        
        function set.YScale(this, NewValue)
            % SET YScale - Set the YScale of axes in the axes grid
            %     Input: YScale - n-by-m cell array of strings ('log' or
            %                     'linear'
            %                      n - number of columns in axesgrid
            %                      m - number of rows in axesgrid
            
            setPropertyValue(this, 'YScale', NewValue, @setYScale_, 'YAxesSharing');
            this.notify('YScaleChanged');
        end
        %% Labels
        function XLabel = get.XLabel(this)
            % GET XLabel - Return current XLabel
            %     Output: XLabel - n-by-m cell array of strings
            %                      n - number of columns in axesgrid
            %                      m - number of rows in axesgrid
            
            % Get current size and labels from AxesGrid
            [nR, nc] = size(this);
            XLabel = this.AxesGrid.ColumnLabel;
            
            % ColumnLabel can be [nc,1] or [1,nc]. If it comes in as size
            % [nc,1], transpose it.
            if all(size(XLabel) == [nc,1])
                XLabel = XLabel';
            end
            % Reshape
            % There is one element for each column - repeat for each row to
            % get a property equal to the size of axes grid.
            XLabel = repmat(XLabel, nR, 1);
        end
        
        function set.XLabel(this, NewValue)
            % SET XLabel - Set XLabel
            %     Output: XLabel - n-by-m cell array of strings
            %                      n - number of columns in axesgrid
            %                      m - number of rows in axesgrid
            
            % Note: XLabel does not follow sharing. For this type of plot,
            % the XLabel is always shared across the column, even if the
            % Sharing is set to 'all'.
            
            setPropertyValue(this, 'XLabel', NewValue, @setXLabel_, 'LabelSharing');
            setInterpreter(this);
        end
        
        function YLabel = get.YLabel(this)
            % GET YLabel - Return current YLabel
            %     Output: YLabel - n-by-m cell array of strings
            %                      n - number of columns in axesgrid
            %                      m - number of rows in axesgrid
            
            % Get current size and labels from AxesGrid
            [~, nC] = size(this);
            YLabel = this.AxesGrid.RowLabel;
            
            % Reshape
            % There is one element for each row - repeat for each row to
            % get a property equal to the size of axes grid.
            
            YLabel = repmat(YLabel, 1, nC);
        end
        
        function set.YLabel(this, NewValue)
            % SET YLabel - Return current YLabel
            %     Output: YLabel - n-by-m cell array of strings
            %                      n - number of columns in axesgrid
            %                      m - number of rows in axesgrid
            
            % Note: YLabel does not follow sharing. For this type of plot,
            % the YLabel is always shared across the column, even if the
            % Sharing is set to 'all'.
            
            setPropertyValue(this, 'YLabel', NewValue, @setYLabel_, 'LabelSharing');
            setInterpreter(this);
        end
        
        %% Title
        function Title = get.Title(this)
            % GET Title - Return current Title from AxesGrid
            %     Output: Title - k-by-1 Character
            NorthPeripheral = getPeripheralAxesGrid(this, 'Top');
            if isempty(NorthPeripheral)
                Title = this.AxesGrid.Title;
            else
                Title = NorthPeripheral.Title;
            end
        end
        
        function set.Title(this, Title)
            % SET Title - Set title of AxesGrid
            %     Input: Title - k-by-1 Character
            
            % Pass-through           
            NorthPeripheral = getPeripheralAxesGrid(this, 'Top');
            if isempty(NorthPeripheral)
                this.AxesGrid.Title = Title;
            else
                NorthPeripheral.Title = Title;
            end
            setInterpreter(this);
        end
        
        %% Parenting
        function parent(this, AxesLocation, Handles)
            Axes = getAxes(this);
            for ct = 1:numel(Handles)
                Handles(ct).Parent = Axes(AxesLocation);
            end
        end
        
        function p = get.Parent(this)
            p = this.AxesGrid.Parent;
        end
        
        function set.Parent(this,Parent)
            Ax = getaxes(this.AxesGrid);
            for ct = 1:numel(Ax)
                Ax(ct).Parent = Parent;
            end
            this.AxesGrid.BackgroundAxes.Parent = Parent;
            if ~isempty(this.BackgroundAxes)
                this.BackgroundAxes.Parent = Parent;
            end
            if ~isempty(this.HistogramAxes)
                for ct = 1:numel(this.HistogramAxes)
                    this.HistogramAxes(ct).Parent = Parent;
                end
            end
            
            if ~isempty(this.PeripheralAxes)
                PAx = getPeripheralAxesGrid(this,'Top');
                if ~isempty(PAx)
                    Ax = getaxes(PAx);
                    for ct =1:numel(Ax)
                        Ax(ct).Parent = Parent;
                    end
                    PAx.BackgroundAxes.Parent = Parent;
                end
                PAx = getPeripheralAxesGrid(this,'Bottom');
                if ~isempty(PAx)
                    Ax = getaxes(PAx);
                    for ct =1:numel(Ax)
                        Ax(ct).Parent = Parent;
                    end
                    PAx.BackgroundAxes.Parent = Parent;
                end
                PAx = getPeripheralAxesGrid(this,'Left');
                if ~isempty(PAx)
                    Ax = getaxes(PAx);
                    for ct =1:numel(Ax)
                        Ax(ct).Parent = Parent;
                    end
                    PAx.BackgroundAxes.Parent = Parent;
                end
                PAx = getPeripheralAxesGrid(this,'Right');
                if ~isempty(PAx)
                    Ax = getaxes(PAx);
                    for ct =1:numel(Ax)
                        Ax(ct).Parent = Parent;
                    end
                    PAx.BackgroundAxes.Parent = Parent;
                end
            end
        end
        
        %% Interpreter        
        % set label interpreter for XLabel and YLabel
        function set.Interpreter(this, Interpreter)
            this.Interpreter = Interpreter;
            setInterpreter(this);
        end
        %% Limit update
        function updateLims(this)
            updatelims(this.AxesGrid);
        end
    end
    
    % PRIVATE METHOD SIGNATURES
    methods (Access = private)
        % Change number of axes
        addAxes_(this, NumRows, NumColumns);
        resize_(this, nR, nC);
        
        % Visibility
        setRowColumnVisible(this, AxesVisibility);
        
        % Set given value to specified property according to sharing
        NewValue = setPropertyValue(this, PropertyName, PropertyValue, SetFcnHandle, SharingProperty)
        
        % Tick Marks management
        setTickMarks(this)
        
        % Peripheral axes set
        setPeripheralAxes(this, P)
        
        % Peripheral axes resize - Along with setting axes properties
        resizePeripheralAxes(this, nr, nc, Location)
        
        % Layout peripheral axes around the core axes
        layout(this, Position);
        
        % Get Peripheral axes grid for position
        PAx = getPeripheralAxesGrid(this, Position);
        
        % Get Histogram Axes
        h = getHistogramAxes(this);
        
    end
    
    methods (Access = private)
        %% SETTERS for properties
        function setGrid_(this, GridValue)
            % Pass through Grid to ctrluis.axesgrid
            this.AxesGrid.Grid = GridValue;
        end
        
        function setXLim_(this, NewValue)
            % Pass through XLim to ctrluis.axesgrid
            for ct = 1:1:size(NewValue, 2)
                setxlim(this.AxesGrid, NewValue{ct}, ct)
            end
        end
        
        function setYLim_(this, NewValue)
            % Pass through YLim to ctrluis.axesgrid
            for ct = 1:1:size(NewValue, 1)
                setylim(this.AxesGrid, NewValue{ct}, ct)
            end
        end
        
        function setXScale_(this, NewValue)
            % Pass through XScale to ctrluis.axesgrid
            if ~iscell(NewValue)
                NewValue = repmat({NewValue}, size(this.AxesGrid.XScale));
            end
            this.AxesGrid.XScale = NewValue;
        end
        
        function setYScale_(this, NewValue)
            % Pass through YScale to ctrluis.axesgrid
            if ~iscell(NewValue)
                NewValue = repmat({NewValue}, size(this.AxesGrid.YScale));
            end
            this.AxesGrid.YScale = NewValue;
        end
        
        function setXLabel_(this, NewValue)
            % Pass through XLabel to ctrluis.axesgrid
            if isscalar(NewValue)
                NewValue = repmat(NewValue, size(this.AxesGrid.ColumnLabel));
            end
            this.AxesGrid.ColumnLabel = NewValue;
            layout(this);
        end
        
        function setYLabel_(this, NewValue)
            % Pass through YLabel to ctrluis.axesgrid
            if isscalar(NewValue)
                NewValue = repmat({NewValue}, size(this.AxesGrid.RowLabel));
            end
            this.AxesGrid.RowLabel = NewValue;
            layout(this);
        end
        
        function setAxesVisibility_(this, NewVisibility)
            this.AxesVisibility = reshape(NewVisibility, size(this.AxesVisibility));
        end
        
        function resizeHistogramAxes(this)
            [nR_New,nC_New] = size(this);
            
            if nR_New == nC_New
                delete(this.HistogramAxes);
                this.HistogramAxes = [];
                if ~isempty(this.HistogramListeners)
                    delete(this.HistogramListeners.XLimListener);
                    for ct=1:numel(this.HistogramListeners.L1)
                        delete(this.HistogramListeners.L1{ct});
                    end
                    for ct=1:numel(this.HistogramListeners.L2)
                        delete(this.HistogramListeners.L2(ct));
                    end
                end
                this.HistogramAxes = getHistogramAxes(this);
            end
        end
        
        function setHistogramXLim(this)
            
            XLim = this.XLim;
            for ct = 1:length(this.HistogramAxes)
                this.HistogramListeners.XLimListener(ct).Enabled = false;
                this.HistogramAxes(ct).XLim = XLim{ct,ct};
                this.HistogramListeners.XLimListener(ct).Enabled = true;
            end
        end
        
        function setHistogramXScale(this)
            XScale = this.AxesGrid.XScale;
            for ct = 1:length(this.HistogramAxes)
                this.HistogramAxes(ct).XScale = XScale{ct};
            end
        end
        
        function setHistogramVisibility(this)
            AllAxes = getaxes(this.AxesGrid);
            [nR,nC] = size(this);
            
            % Return visibility
            AV = reshape({AllAxes.Visible},nR,nC);
            for ct = 1:length(this.HistogramAxes)
                if strcmp(AV{ct,ct},'on')
                    set(this.HistogramAxes(ct),'Visible','on','ContentsVisible','on');
                    bh = hgbehaviorfactory('Zoom');
                    set(bh, 'Enable', true);
                    hgaddbehavior(this.HistogramAxes(ct),bh);
                else
                    set(this.HistogramAxes(ct),'Visible','off','ContentsVisible','off');
                    bh = hgbehaviorfactory('Zoom');
                    set(bh, 'Enable', false);
                    hgaddbehavior(this.HistogramAxes(ct),bh);
                    
                end
            end
        end
        
        function setXLimFromHistogram(this,idx)
            for ct = 1:numel(this.HistogramListeners.L1)
                this.HistogramListeners.L1{ct}.Enabled = false;
            end
            
            for ct = 1:numel(this.HistogramListeners.L2)
                this.HistogramListeners.L2(ct).Enabled = 'off';
            end
            XLim = this.HistogramAxes(idx).XLim;
            this.XLim{1,idx} = XLim;
            for ct = 1:numel(this.HistogramListeners)
                this.HistogramListeners.L1{ct}.Enabled = true;
            end
            for ct = 1:numel(this.HistogramListeners.L2)
                this.HistogramListeners.L2(ct).Enabled = 'on';
            end
        end
        
        function setHistogramPosition(this,ed)
            if strcmpi(this.DiagonalAxesSharing,'XOnly')
                ax = getAxes(this);
                ax_ = getaxes(this.AxesGrid);
                [nR,~] = size(this);
                for ct = 1:nR
                    % Create axes
                    set(ax(ct,ct),'Position', get(ax_(ct,ct),'Position'));
                end
            end
        end
    end
    
    % QE METHODS
    methods (Hidden = true)
        function AG = qeGetAxesGrid(this)
            AG = this.AxesGrid;
        end
        
        function qeSetLabelSharing(this, LabelSharing)
            this.LabelSharing = LabelSharing;
        end
        
        function PAx = qeGetPeripheralAxes(this)
            PAx = this.PeripheralAxes;
        end
        
        function Ax = qeGetDiagonalAxes(this)
           Ax = this.HistogramAxes;
        end
        
        function setInterpreter(this)
            Ax  = this.AxesGrid.BackgroundAxes;
            Ax.Title.Interpreter = this.Interpreter;
            
            Ax = this.AxesGrid.getaxes;
            for ct=1:numel(Ax)
                set(Ax(ct).XLabel,'Interpreter',this.Interpreter);
                set(Ax(ct).YLabel,'Interpreter',this.Interpreter);
            end
            
           NorthPeripheral = this.getPeripheralAxesGrid('Top');
           if ~isempty(NorthPeripheral)
               Ax = getaxes(NorthPeripheral);
               for ct = 1:numel(Ax)
                   set(Ax(ct).XLabel,'Interpreter',this.Interpreter);
                   set(Ax(ct).YLabel,'Interpreter',this.Interpreter);
               end
               Ax = NorthPeripheral.BackgroundAxes;
               Ax.Title.Interpreter = this.Interpreter;
           end
           
           SouthPeripheral = this.getPeripheralAxesGrid('Bottom');
           if ~isempty(SouthPeripheral)
               Ax = getaxes(SouthPeripheral);
               for ct = 1:numel(Ax)
                   set(Ax(ct).XLabel,'Interpreter',this.Interpreter);
                   set(Ax(ct).YLabel,'Interpreter',this.Interpreter);
               end
           end
           
           EastPeripheral = this.getPeripheralAxesGrid('Right');
           if ~isempty(EastPeripheral)
               Ax = getaxes(EastPeripheral);
               for ct = 1:numel(Ax)
                   set(Ax(ct).XLabel,'Interpreter',this.Interpreter);
                   set(Ax(ct).YLabel,'Interpreter',this.Interpreter);
               end
           end
           
           WestPeripheral = this.getPeripheralAxesGrid('Left');
           if ~isempty(WestPeripheral)
               Ax = getaxes(WestPeripheral);
               for ct = 1:numel(Ax)
                   set(Ax(ct).XLabel,'Interpreter',this.Interpreter);
                   set(Ax(ct).YLabel,'Interpreter',this.Interpreter);
               end
           end
        end
    end
    
    methods
        function delete(this)
            delete(this.HistogramAxes);
            this.HistogramAxes = [];
            if ~isempty(this.HistogramListeners)
                delete(this.HistogramListeners.XLimListener);
                for ct=1:numel(this.HistogramListeners.L1)
                    delete(this.HistogramListeners.L1{ct});
                end
                for ct=1:numel(this.HistogramListeners.L2)
                    delete(this.HistogramListeners.L2(ct));
                end
            end
        end
    end
    
    % Static method function signatures
    methods (Static = true)
        result = localCheckFcn(x);
        p = localParseInputsForAddRemove(varargin);
        NewValue = localValidateValue(CurrentValue, NewValue, ValidateFcnHandle);
        result = localValidateSharing(x)
    end
    
    
    % Events
    events
        %% To maintain peripheral axes in sync
        SizeChanged
        XLimChanged
        YLimChanged
        XScaleChanged
        YScaleChanged
        GridChanged
        VisibilityChanged
    end
    
end

% LocalWords:  ctrluis XScale XLabel YScale YTick XAxes YAxes XOnly nc
