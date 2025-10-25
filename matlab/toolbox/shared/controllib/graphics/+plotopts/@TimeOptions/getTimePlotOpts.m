function getTimePlotOpts(this,h,varargin)
%GETTIMEPLOTOPTS Gets plot options of @timeplot h 

%  Author(s): C. Buhr
%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin) 
   allflag = false;
else
    allflag = varargin{1};
end

this.TimeUnits = h.AxesGrid.XUnits;
this.Normalize = h.AxesGrid.YNormalization;     
this.SettleTimeThreshold = h.Options.SettlingTimeThreshold;
this.RiseTimeLimits = h.Options.RiseTimeLimits;
        
this.ConfidenceRegionNumberSD = h.Options.ConfidenceNumSD;

if allflag
    getRespPlotOpts(this,h,allflag);
end