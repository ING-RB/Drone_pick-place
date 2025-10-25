function applyNyquistPlotOpts(this,h,varargin)
%APPLYNYQUISTPLOTOPTS  set Nyquist plot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin) 
    allflag = false;
else
    allflag = varargin{1};
end

if strcmpi(this.FreqUnits,'auto')
    try
        h.setAutoFrequencyUnits;
    catch ME
        disp('This plot type does not support auto units.')
    end
else
    h.FrequencyUnits = this.FreqUnits;
end

h.MagnitudeUnits = this.MagUnits;
h.PhaseUnits = this.PhaseUnits;
h.ShowFullContour = this.ShowFullContour;

h.Options.ConfidenceNumSD = this.ConfidenceRegionNumberSD;
h.Options.ConfidenceDisplaySampling = this.ConfidenceRegionDisplaySpacing;

if allflag
   applyRespPlotOpts(this,h,allflag);
end