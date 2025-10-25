function applyPZMapOpts(this,h,varargin)
%APPLYPZMAPOPTS  set pzplot properties

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

if strcmpi(this.TimeUnits,'auto')
    try
        h.setAutoTimeUnits;
    catch ME
        disp('This plot type does not support auto units.')
    end
else
    h.TimeUnits = this.TimeUnits;
end

h.Options.ConfidenceNumSD = this.ConfidenceRegionNumberSD;
   

if allflag
   applyRespPlotOpts(this,h,allflag);
end