function applySigmaPlotOpts(this,h,varargin)
%APPLYSIGMAPLOTOPTS  set Sigma plot properties

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
    h.AxesGrid.XUnits = this.FreqUnits;
end
h.AxesGrid.XScale = this.FreqScale;



h.AxesGrid.XScale = this.FreqScale;

% Apply Magnitude Properties
h.AxesGrid.YUnits = this.MagUnits;
h.AxesGrid.YScale = this.MagScale;

if allflag
   applyRespPlotOpts(this,h,allflag);
end