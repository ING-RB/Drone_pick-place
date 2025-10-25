function mapCSTPrefs(this,varargin)
%MAPCSTPREFS Maps the CST or view prefs to the RespPlotOptions

%  Copyright 1986-2015 The MathWorks, Inc.

if isempty(varargin)
    CSTPrefs = cstprefs.tbxprefs;
else
    CSTPrefs = varargin{1};
end


mapCSTPrefs@plotopts.PlotOptions(this,CSTPrefs);

this.InputLabels = struct('FontSize', CSTPrefs.IOLabelsFontSize , ...
                          'FontWeight', CSTPrefs.IOLabelsFontWeight, ...
                          'FontAngle', CSTPrefs.IOLabelsFontAngle, ...
                          'Color', [0.4000 0.4000 0.4000]);


this.OutputLabels =  struct('FontSize', CSTPrefs.IOLabelsFontSize , ...
                            'FontWeight', CSTPrefs.IOLabelsFontWeight, ...
                            'FontAngle', CSTPrefs.IOLabelsFontAngle, ...
                            'Color', [0.4000 0.4000 0.4000]);
                        
                       




