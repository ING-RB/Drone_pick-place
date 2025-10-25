function applyIOFrequencyPlotOpts(this,h,varargin)
%APPLYIOFREQUENCYPLOTOPTS  Set iofrequencyplot properties.

%  Copyright 2013-2014 The MathWorks, Inc.
if isempty(varargin) 
    allflag = false;
else
    allflag = varargin{1};
end

% Apply Frequency Properties
if strcmpi(this.FreqUnits,'auto')
    try
        h.setAutoFrequencyUnits;
    catch ME
        disp('This plot type does not support auto units.')
    end
else
    h.AxesGrid.XUnits = {this.FreqUnits};
end
h.AxesGrid.XScale = {this.FreqScale};

% Apply Magnitude Properties
h.AxesGrid.YUnits(1) = {this.MagUnits};
h.AxesGrid.YScale(1:2:end) = {this.MagScale};
h.MagVisible = this.MagVisible;

Options = h.Options;

if strcmpi(this.MagLowerLimMode,'auto')
    Options.MinGainLimit.Enable = 'off';
else
    Options.MinGainLimit.Enable = 'on';
end
Options.MinGainLimit.MinGain = this.MagLowerLim;

% Apply Phase Properties
h.AxesGrid.YUnits(2) = {this.PhaseUnits};
h.PhaseVisible = this.PhaseVisible;
if strcmp(this.PhaseWrapping,'off')
    Options.UnwrapPhase = 'on';
else
    Options.UnwrapPhase = 'off';
end

Options.ComparePhase = struct( ...
    'Enable',this.PhaseMatching, ...
    'Freq', this.PhaseMatchingFreq, ...
    'Phase', this.PhaseMatchingValue);
Options.PhaseWrappingBranch = this.PhaseWrappingBranch;
Options.ConfidenceNumSD = this.ConfidenceRegionNumberSD;

h.Options = Options;


% Call parent class method
if allflag
   applyRespPlotOpts(this,h,allflag);
end

switch this.Orientation
   case 'two-row'
      Or = '2row';
   case 'two-column'
      Or = '2col';
   case 'single-row'
      Or = '1row';
   case 'single-column'
      Or = '1col';
end

h.AxesGrid.Orientation = Or;
