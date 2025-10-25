function initialize(this,hgaxes)
%INITIALIZE  Configures axes grid.

%   Author: P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

nr = prod(this.Size([1 3]));  % total number of rows in axes grid
nc = prod(this.Size([2 4]));  % total number of columns in axes grid

% Create supporting plotarray instances
this.Axes = ctrluis.plotarrayPlotmatrix(this.Size,hgaxes(:));   % private
this.Axes4d = getaxes(this.Axes);  % array of HG axes of size GRIDSIZE
this.Axes2d = reshape(permute(this.Axes4d,[3 1 4 2]),[nr,nc]);

% Disable rotate 3D for the axes
this.disableRotate3D;

% Settings inherited from template axes
this.XLimMode = hgaxes(1).XLimMode;
this.YLimMode = hgaxes(1).YLimMode;
this.NextPlot = hgaxes(1).NextPlot;
this.ColumnLabel = repmat({''},[nc 1]);
this.RowLabel = repmat({''},[nr 1]);

Props = struct(this.AxesStyle);

% Configure axes
set(this.Axes2d,'Units','normalized','Box','on',...
   'linewidth', hgaxes(1).LineWidth, ...  
   'XtickMode','auto','YtickMode','auto',...
   'XScale',hgaxes(1).XScale,'YScale',hgaxes(1).YScale,...
   'Xlim',hgaxes(1).XLim,'Ylim',hgaxes(1).YLim,...
   'NextPlot',this.NextPlot,'UIContextMenu',this.UIContextMenu,...
   'XGrid','off','YGrid','off',Props);

% Add listeners
addlisteners(this)

% Add bypass for TITLE, AXIS,...
addbypass(this)
