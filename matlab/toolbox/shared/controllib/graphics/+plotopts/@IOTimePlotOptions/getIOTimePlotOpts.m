function getIOTimePlotOpts(this,h,varargin)
%GETIOTIMEPLOTOPTS Gets plot options of @ioTimePlot h 

%  Copyright 2013-2014 The MathWorks, Inc.
if isempty(varargin) 
   allflag = false;
else
    allflag = varargin{1};
end

switch h.AxesGrid.Orientation
   case '2row'
      Or = 'two-row';
   case '2col'
      Or = 'two-column';
   case '1row'
      Or = 'single-row';
   case '1col'
      Or = 'single-column';
end

this.Orientation = Or;
this.TimeUnits = h.AxesGrid.XUnits;
this.Normalize = h.AxesGrid.YNormalization;    
if allflag
    getRespPlotOpts(this,h,allflag);
end
