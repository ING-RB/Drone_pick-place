function applyTimePlotOpts(this,h,varargin)
%APPLYTIMEPLOTOPTS  set timeplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin) 
    allflag = false;
else
    allflag = varargin{1};
end

if strcmpi(this.TimeUnits,'auto')
    try
        h.setAutoTimeUnits;
    catch ME
        disp('This plot type does not support auto units.')
    end
else
    h.AxesGrid.XUnits = {this.TimeUnits};
end
h.AxesGrid.YNormalization = this.Normalize;  
h.Options.SettlingTimeThreshold = this.SettleTimeThreshold;
h.Options.RiseTimeLimits = this.RiseTimeLimits;  
h.Options.ConfidenceNumSD = this.ConfidenceRegionNumberSD;
                 
if allflag
   applyRespPlotOpts(this,h,allflag);
end