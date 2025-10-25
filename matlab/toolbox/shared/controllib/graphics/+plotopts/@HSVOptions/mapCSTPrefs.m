function mapCSTPrefs(this,varargin)
%MAPCSTPREFS Maps the CST or view prefs to the HSVPlotOptions

%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin)
    CSTPrefs = cstprefs.tbxprefs;
else
    CSTPrefs = varargin{1};
end

mapCSTPrefs@plotopts.PlotOptions(this,CSTPrefs);


