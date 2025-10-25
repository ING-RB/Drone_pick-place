function getSectorPlotOpts(this,h,varargin)
%GETSECTORPLOTOPTS Gets plot options of @sectorplot h 

%  Copyright 2015 The MathWorks, Inc.
if isempty(varargin) 
   allflag = false;
else
    allflag = varargin{1};
end

this.FreqUnits = h.AxesGrid.XUnits;
this.FreqScale = h.AxesGrid.XScale;
this.IndexScale = h.AxesGrid.YScale;

if allflag
    getRespPlotOpts(this,h,allflag);
end