function getPlotOpts(this,h)
% GETPLOTOPTS Gets plot options of @plot h

%  Copyright 1986-2022 The MathWorks, Inc.

% For title, xlabel, ylabel: Create structure and assign it to the Title
% property. This avoids creating an array of structures when
% h.AxesGrid.Title is a cell array (label consisting of multiple lines).

% Get Title info 
TitleStyle = h.AxesGrid.TitleStyle;
titleStruct.String = h.AxesGrid.Title;
titleStruct.FontSize = TitleStyle.FontSize;
titleStruct.FontWeight = TitleStyle.FontWeight;
titleStruct.FontAngle = TitleStyle.FontAngle;
titleStruct.Color = TitleStyle.Color;
this.Title = titleStruct;
     
% Get Xlabel info
XLabelStyle = h.AxesGrid.XLabelStyle;
xlabelStruct.String = h.AxesGrid.XLabel;
xlabelStruct.FontSize = XLabelStyle.FontSize;
xlabelStruct.FontWeight = XLabelStyle.FontWeight;
xlabelStruct.FontAngle = XLabelStyle.FontAngle;
xlabelStruct.Color = XLabelStyle.Color;
this.XLabel = xlabelStruct;

% Get Ylabel info
YLabelStyle = h.AxesGrid.YLabelStyle;
ylabelStruct.String = h.AxesGrid.YLabel;
ylabelStruct.FontSize = YLabelStyle.FontSize;
ylabelStruct.FontWeight = YLabelStyle.FontWeight;
ylabelStruct.FontAngle = YLabelStyle.FontAngle;
ylabelStruct.Color = YLabelStyle.Color;
this.YLabel = ylabelStruct;

% Get Tick Label info
TickLabelStyle = h.AxesGrid.AxesStyle;
this.TickLabel = struct('FontSize',   TickLabelStyle.FontSize, ...
                     'FontWeight', TickLabelStyle.FontWeight, ...
                     'FontAngle',  TickLabelStyle.FontAngle, ...
                     'Color',     TickLabelStyle.XColor);                  

% Get Grid info
this.Grid = h.AxesGrid.Grid;
this.GridColor = h.AxesGrid.AxesStyle.GridColor;

% Get Lim and Limmode info
ax = h.AxesGrid.getaxes('2d');  
this.XLim = get(ax(1,:),{'Xlim'});     
this.XLimMode = h.AxesGrid.XLimMode;

this.YLim = get(ax(:,1),{'Ylim'});
this.YLimMode = h.AxesGrid.YLimMode;

% ColorModes
this.ColorMode.Title = TitleStyle.ColorMode;
this.ColorMode.XLabel = XLabelStyle.ColorMode;
this.ColorMode.YLabel = YLabelStyle.ColorMode;
this.ColorMode.TickLabel = TickLabelStyle.XColorMode;
this.ColorMode.Grid = h.AxesGrid.AxesStyle.GridColorMode;