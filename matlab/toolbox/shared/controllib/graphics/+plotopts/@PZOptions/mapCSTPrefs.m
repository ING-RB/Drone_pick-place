function mapCSTPrefs(this,varargin)
%MAPCSTPREFS for PZMapPlotOptions

%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin)
    CSTPrefs = cstprefs.tbxprefs;
else
    CSTPrefs = varargin{1};
end

mapCSTPrefs@plotopts.RespPlotOptions(this,CSTPrefs);

this.FreqUnits = CSTPrefs.FrequencyUnits; 
this.TimeUnits = CSTPrefs.TimeUnits;