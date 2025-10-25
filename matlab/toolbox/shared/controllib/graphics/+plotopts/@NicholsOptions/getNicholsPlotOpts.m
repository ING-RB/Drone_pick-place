function getNicholsPlotOpts(this,h,varargin)
%GETNICHOLSPLOTOPTS Gets plot options of @nichols plot h 

%  Author(s): C. Buhr
%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin) 
   allflag = false;
else
    allflag = varargin{1};
end


this.FreqUnits = h.FrequencyUnits;
this.PhaseUnits = h.AxesGrid.XUnits;

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
this.PhaseWrappingBranch_ = h.Options.PhaseWrappingBranch;


if allflag
    getRespPlotOpts(this,h,allflag);
end