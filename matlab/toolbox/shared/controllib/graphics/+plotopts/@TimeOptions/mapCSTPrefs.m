function mapCSTPrefs(this,varargin)
%MAPCSTPREFS for TimePlotOptions

%  Copyright 1986-2021 The MathWorks, Inc.


if isempty(varargin)
    CSTPrefs = cstprefs.tbxprefs;
else
    CSTPrefs = varargin{1};
end


mapCSTPrefs@plotopts.RespPlotOptions(this,CSTPrefs);


this.TimeUnits = CSTPrefs.TimeUnits;

this.SettleTimeThreshold = CSTPrefs.SettlingTimeThreshold;
this.RiseTimeLimits = CSTPrefs.RiseTimeLimits;
