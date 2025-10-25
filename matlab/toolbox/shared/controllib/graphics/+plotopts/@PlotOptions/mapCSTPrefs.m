function this = mapCSTPrefs(this,varargin)
%MAPCSTPREFS Maps the CST or view prefs to the PlotOptions

%  Copyright 1986-2015 The MathWorks, Inc.


if isempty(varargin)
    prefs = cstprefs.tbxprefs;
    toolboxPrefs = prefs;
else
    prefs = varargin{1};
    toolboxPrefs = cstprefs.tbxprefs;
end

this.Title.FontSize = prefs.TitleFontSize;
this.Title.FontWeight = prefs.TitleFontWeight;
this.Title.FontAngle = prefs.TitleFontAngle;
this.Title.Color =[0 0 0];
             
this.XLabel.FontSize =   prefs.XYLabelsFontSize;
this.XLabel.FontWeight = prefs.XYLabelsFontWeight;
this.XLabel.FontAngle =  prefs.XYLabelsFontAngle;
this.XLabel.Color = [0.15 0.15 0.15];
this.ColorMode.XLabel = "auto";

this.YLabel.FontSize =   prefs.XYLabelsFontSize;
this.YLabel.FontWeight = prefs.XYLabelsFontWeight;
this.YLabel.FontAngle =  prefs.XYLabelsFontAngle;
this.YLabel.Color = [0.15 0.15 0.15];       
this.ColorMode.YLabel = "auto";

this.TickLabel.FontSize = prefs.AxesFontSize;
this.TickLabel.FontWeight = prefs.AxesFontWeight;
this.TickLabel.FontAngle = prefs.AxesFontAngle;
this.TickLabel.Color = prefs.AxesForegroundColor;
if isequal(prefs.AxesForegroundColor,toolboxPrefs.AxesForegroundColorFactoryValue)
    this.ColorMode.TickLabel = "auto";
else
    this.ColorMode.TickLabel = "manual";
end

this.Grid = prefs.Grid;

this.GridColor = prefs.GridColor;
if isequal(prefs.GridColor,toolboxPrefs.GridColorFactoryValue)
    this.ColorMode.Grid = "auto";
else
    this.ColorMode.Grid = "manual";
end
