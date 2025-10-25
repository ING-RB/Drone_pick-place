function applySectorPlotOpts(this,h,varargin)
%APPLYSECTORPLOTOPTS  set sector index plot properties

%  Copyright 2015 The MathWorks, Inc.

if isempty(varargin) 
    allflag = false;
else
    allflag = varargin{1};
end

% Apply Frequency Properties
if strcmpi(this.FreqUnits,'auto')
    try %#ok<TRYNC>
        h.setAutoFrequencyUnits;
    end
else
    h.AxesGrid.XUnits = this.FreqUnits;
end
h.AxesGrid.XScale = this.FreqScale;

% Apply Magnitude Properties
h.AxesGrid.YUnits = 'abs';  % always in 'abs' units
h.AxesGrid.YScale = this.IndexScale;

if allflag
   applyRespPlotOpts(this,h,allflag);
end