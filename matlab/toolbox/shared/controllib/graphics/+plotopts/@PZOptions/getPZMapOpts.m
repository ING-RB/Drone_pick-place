function getPZMapOpts(this,h,varargin)
%GETPZMAPPLOTOPTS Gets plot options of @pzplot h 

%  Author(s): C. Buhr
%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin) 
   allflag = false;
else
    allflag = varargin{1};
end


this.FreqUnits = h.FrequencyUnits;
this.TimeUnits = h.TimeUnits;

this.ConfidenceRegionNumberSD = h.Options.ConfidenceNumSD;
                 
if allflag
    getRespPlotOpts(this,h,allflag);
end