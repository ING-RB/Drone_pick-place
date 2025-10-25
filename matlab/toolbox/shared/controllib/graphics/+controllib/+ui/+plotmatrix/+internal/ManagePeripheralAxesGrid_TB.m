classdef ManagePeripheralAxesGrid_TB < handle
    
    % ManagePeripheralAxesGrid_TB Manage layout and properties of a grid of
    % axes placed along the top or bottom periphery of a core axes grid.
    
    % This class provides methods to set independent properties of a
    % peripheral axes grid, placed at the top or bottom of a core axes
    % grid managed by the ManageAxesGrid class object. Any property not
    % exposed here depends on the core axes grid, and hence cannot be set
    % independantly.
    
   
    
    % Copyright 2014-2015 The MathWorks, Inc.
    
    properties %(Access = private)
        PeripheralGrid
    end
    
    properties (Dependent = true)        
        % Specify the label for X-axes in the axes grid.
        % XLabel is an n-by-m cell array of strings
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        YLabel
        
        % Specify the label for Y-axes in the axes grid.
        % YLabel is an n-by-m cell array of strings
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        XLabel 
    end

    properties (Dependent, GetAccess=private)
        % Specify the x limits of any axes in the figure
        % XLim is an n-by-m cell array of 1-by-2 vectors,
        %            n - number of columns of axes
        %            m - number of rows of axes
        YLim
        
        
        % Specify the scale of any X-axes in the axes grid
        % XScale is an n-by-m cell array of strings ('log' or 'linear'),
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        YScale
    end
    
    properties (SetAccess = private, Dependent = true)
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
    end
    
    properties %(Hidden = true, SetAccess = private, GetAccess = ?controllib.ui.plotmatrix.internal.ManageAxesGrid)
        AxesGrid
        Position
    end
        
    
    methods
        function this = ManagePeripheralAxesGrid_TB(PeripheralGrid, AxesGrid)
            this.PeripheralGrid = PeripheralGrid;
            this.AxesGrid = AxesGrid;
        end
        
        function XLim = get.XLim(this)
           XLim = this.PeripheralGrid.XLim;
        end
        
        function set.XLim(this, XLim)
          this.PeripheralGrid.XLim = XLim;
        end
        
        function XScale = get.XScale(this)
           XScale = this.PeripheralGrid.XScale;
        end
        
        function set.XScale(this, XScale)
          this.PeripheralGrid.XScale = XScale;
        end
        
        function XLabel = get.XLabel(this)
           XLabel = this.PeripheralGrid.XLabel;
        end
        
        function set.XLabel(this, XLabel)
            this.PeripheralGrid.XLabel = XLabel;
        end
        
        function YLabel = get.YLabel(this)
            YLabel = this.PeripheralGrid.YLabel;
        end
        
        function set.YLabel(this, YLabel)
            this.PeripheralGrid.YLabel = YLabel;
        end
        
        function AG = get.AxesGrid(this)
            AG = this.AxesGrid;
        end
        function Position = get.Position(this)
            Position = this.AxesGrid.BackgroundAxes.Position;
        end
        function customUpdateLimits(this, Lim)
            Ax = getaxes(this.AxesGrid);
            for ct = 1:numel(Lim)
                set(Ax(ct), 'XLim', Lim{ct});
            end
        end
%             customUpdateLimits(this.PeripheralGrid);
    end
end

%------------------ Local Functions -----------------------

function LocalEqualizeLims(ax,LimProp,ScaleProp,IdxToIgnor)
% Enforce common limits for all axes in handle array AX
% All axes are assumed visible.
ax = ax(~logical(IdxToIgnor));
% Compute common limits
Lmin = NaN;
Lmax = NaN;
for ct=1:numel(ax)
   Lims = get(ax(ct),LimProp);
   Lmin = min(Lmin,Lims(1));
   Lmax = max(Lmax,Lims(2));
end

% Enforce these limits
set(ax,LimProp,[Lmin Lmax])
end