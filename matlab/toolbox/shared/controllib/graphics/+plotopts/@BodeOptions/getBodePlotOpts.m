function getBodePlotOpts(this,h,varargin)
%GETBODEPLOTOPTS Gets plot options of @bodeplot h 

%  Author(s): C. Buhr
%  Copyright 1986-2021 The MathWorks, Inc.

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

this.ConfidenceRegionNumberSD = h.Options.ConfidenceNumSD;
this.PhaseWrappingBranch_ = h.Options.PhaseWrappingBranch;

if allflag
    getRespPlotOpts(this,h,allflag);
end



