function getIOFrequencyPlotOpts(this,h,varargin)
%GETIOFREQUENCYPLOTOPTS Gets plot options from plot handle

%  Copyright 2014 The MathWorks, Inc.
if isempty(varargin) 
   allflag = false;
else
    allflag = varargin{1};
end

this.FreqUnits = h.AxesGrid.XUnits;
this.FreqScale = h.AxesGrid.XScale{1};
this.MagUnits = h.AxesGrid.YUnits{1};
this.MagScale = h.AxesGrid.YScale{1};
this.PhaseUnits = h.AxesGrid.YUnits{2};

this.MagVisible = h.MagVisible;
this.PhaseVisible = h.PhaseVisible;

if strcmp(h.Options.UnwrapPhase,'on')
    this.PhaseWrapping = 'off';
else
    this.PhaseWrapping = 'on';
end

if strcmp(h.Options.MinGainLimit.Enable,'on')
    this.MagLowerLimMode = 'manual';
else
    this.MagLowerLimMode = 'auto';
end
this.MagLowerLim = h.Options.MinGainLimit.MinGain;

ComparePhase = h.Options.ComparePhase;

this.PhaseMatching = ComparePhase.Enable;
this.PhaseMatchingFreq = ComparePhase.Freq;
this.PhaseMatchingValue = ComparePhase.Phase;
this.PhaseWrappingBranch = h.Options.PhaseWrappingBranch;
this.ConfidenceRegionNumberSD = h.Options.ConfidenceNumSD;

if allflag
    getRespPlotOpts(this,h,allflag);
end

switch h.AxesGrid.Orientation
   case '2row'
      Or = 'two-row';
   case '2col'
      Or = 'two-column';
   case '1row'
      Or = 'single-row';
   case '1col'
      Or = 'single-column';
end

this.Orientation = Or;
