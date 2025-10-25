function getDiskMarginPlotOpts(this,h,varargin)
%GETPLOTOPTS Gets plot options of @bodeplot h 

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

if allflag
   getRespPlotOpts(this,h,allflag);
end



