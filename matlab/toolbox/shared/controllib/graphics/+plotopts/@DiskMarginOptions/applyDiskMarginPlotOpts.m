function applyDiskMarginPlotOpts(this,h,varargin)
%APPLYPLOTOPTS  set plot properties

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
    catch
        disp('This plot type does not support auto units.')
    end
else
    h.AxesGrid.XUnits = this.FreqUnits;
end
h.AxesGrid.XScale = this.FreqScale;

% Apply Magnitude Properties
h.AxesGrid.YUnits(1) = {this.MagUnits};
h.AxesGrid.YScale(1) = {this.MagScale};

% Apply Phase Properties
h.AxesGrid.YUnits(2) = {this.PhaseUnits};

% Call parent class method
if allflag
   applyRespPlotOpts(this,h,allflag);
end

