classdef ManagePeripheralAxesGrid_LR < handle
    
    % ManagePeripheralAxesGrid_LR Manage layout and properties of a grid of
    % axes placed along the left or right periphery of a core axes grid.
    
    % This class provides methods to set independent properties of a
    % peripheral axes grid, placed to the left or right of a core axes
    % grid managed by the ManageAxesGrid class object.
    
    % Copyright 2014-2015 The MathWorks, Inc.
    
    properties (Access = private)
        PeripheralGrid
    end
    
    properties (Dependent = true)
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
        
        % Specify the label for Y-axes in the axes grid.
        % YLabel is an n-by-m cell array of strings
        %           n - number of columns in axesgrid
        %           m - number of rows in axesgrid
        YLabel 
    end
    
    properties (SetAccess = private, Dependent = true)
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
    
    properties %(Hidden = true, SetAccess = private, GetAccess = ?controllib.ui.plotmatrix.internal.ManageAxesGrid)
        AxesGrid
        Position
    end
    
    methods
        function this = ManagePeripheralAxesGrid_LR(PeripheralGrid, AxesGrid)
            this.PeripheralGrid = PeripheralGrid;
            this.AxesGrid = AxesGrid;
        end
        
        function XLim = get.XLim(this)
           XLim = this.PeripheralGrid.XLim;
        end
        
        function set.XLim(this, XLim)
          this.PeripheralGrid.XLim = XLim;
        end
        
        function YLim = get.YLim(this)
            YLim = this.PeripheralGrid.YLim;
        end
        
        function XScale = get.XScale(this)
           XScale = this.PeripheralGrid.XScale;
        end
        
        function set.XScale(this, XScale)
          this.PeripheralGrid.XScale = XScale;
        end
        
        function YScale = get.YScale(this)
            YScale = this.PeripheralGrid.YScale;
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
        
        function Axes = getAxes(this)
            Axes = getaxes(this.PeripheralGrid.AxesGrid);
        end
        
        function AG = get.AxesGrid(this)
            AG = this.AxesGrid;
        end
        
        function Position = get.Position(this)
            Position = this.AxesGrid.Position;
        end
        function customUpdateLimits(this, Lim)
            Ax = getaxes(this.AxesGrid);
%             vis = reshape(strcmp(get(Ax,'Visible'),'on'),size(Ax));  % 1 for visible axes
            for ct = numel(Lim):-1:1
                set(Ax(ct), 'YLim', Lim{ct});
            end
%             % Turn off backdoor listeners
%             LimitMgrEnable = this.AxesGrid.LimitManager;  % can be 'off' in call with 3 inputs
%             this.AxesGrid.LimitManager = 'off';
%             
%             XLimMode = this.AxesGrid.YLimMode;  % Use current settings
%             % Switch to auto mode for visible axes with YLimMode=auto
%             xauto = strcmp(XLimMode,'auto');
%             if length(xauto)==1
%                 xauto = repmat(xauto,size(Ax));
%             else
%                 xauto = repmat(xauto,[size(Ax,2),1]);
%             end
%             set(Ax(vis & xauto),'XlimMode','auto')
%             LocalEqualizeLims(Ax(vis),'Xlim','XScale',zeros(size(Ax)));
%             this.AxesGrid.LimitManager = LimitMgrEnable;
            %             customUpdateLimits(this.PeripheralGrid);
        end
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