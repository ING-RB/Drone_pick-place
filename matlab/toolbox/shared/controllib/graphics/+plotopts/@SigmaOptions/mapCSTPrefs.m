function mapCSTPrefs(this,varargin)
%MAPCSTPREFS Maps the CST or view prefs to the SigmaPlotOptions

%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin)
    CSTPrefs = cstprefs.tbxprefs;
else
    CSTPrefs = varargin{1};
end

mapCSTPrefs@plotopts.RespPlotOptions(this,CSTPrefs);


this.FreqUnits = CSTPrefs.FrequencyUnits; 
this.FreqScale = CSTPrefs.FrequencyScale; 
this.MagUnits = CSTPrefs.MagnitudeUnits; 
this.MagScale = CSTPrefs.MagnitudeScale; 

