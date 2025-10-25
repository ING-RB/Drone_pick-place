function applyNicholsPlotOpts(this,h,varargin)
%APPLYNICHOLSPLOTOPTS  set nicholsplot properties

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
   
h.AxesGrid.XUnits = this.PhaseUnits;
Options = h.Options;

if strcmp(this.PhaseWrapping,'off')
    Options.UnwrapPhase = 'on';
else
    Options.UnwrapPhase = 'off';
end

if strcmpi(this.MagLowerLimMode,'auto')
    Options.MinGainLimit.Enable = 'off';
else
    Options.MinGainLimit.Enable = 'on';
end
Options.MinGainLimit.MinGain = this.MagLowerLim;

Options.ComparePhase = struct( ...
    'Enable',this.PhaseMatching, ...
    'Freq', this.PhaseMatchingFreq, ...
    'Phase', this.PhaseMatchingValue);
Options.PhaseWrappingBranch = this.PhaseWrappingBranch_;

h.Options = Options;

if allflag
   applyRespPlotOpts(this,h,allflag);
end