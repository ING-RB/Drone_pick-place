function getNyquistPlotOpts(this,h,varargin)
%GETNYQUISTPLOTOPTS Gets plot options of @nyquistplot h  

%  Author(s): C. Buhr
%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin) 
   allflag = false;
else
    allflag = varargin{1};
end


this.FreqUnits = h.FrequencyUnits;
this.MagUnits = h.MagnitudeUnits;
this.PhaseUnits = h.PhaseUnits;
this.ShowFullContour = h.ShowFullContour;

this.ConfidenceRegionNumberSD = h.Options.ConfidenceNumSD;
this.ConfidenceRegionDisplaySpacing = h.Options.ConfidenceDisplaySampling;

if allflag
    getRespPlotOpts(this,h,allflag);
end