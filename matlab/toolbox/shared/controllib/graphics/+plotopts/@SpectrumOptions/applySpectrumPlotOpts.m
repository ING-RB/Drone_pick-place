function applySpectrumPlotOpts(this,h,varargin)
%APPLYSPECTRUMPLOTOPTS  set spectrumplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

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
h.AxesGrid.YUnits = this.MagUnits;
h.AxesGrid.YScale(1:2:end) = {this.MagScale};

Options = h.Options;
if strcmpi(this.MagLowerLimMode,'auto')
    Options.MinGainLimit.Enable = 'off';
else
    Options.MinGainLimit.Enable = 'on';
end
Options.MinGainLimit.MinGain = this.MagLowerLim;
Options.ConfidenceNumSD = this.ConfidenceRegionNumberSD;
h.Options = Options;

% Call parent class method
if allflag
   applyRespPlotOpts(this,h,allflag);
end

