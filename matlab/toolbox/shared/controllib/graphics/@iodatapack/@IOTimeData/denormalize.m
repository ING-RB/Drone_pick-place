function ydata = denormalize(~,ydata,Xlims,t0,y0)
%DENORMALIZE  Infers true Y value from normalized Y value.
%
%  Input arguments:
%    * YDATA is the Y data to be normalized
%    * XLIMS are the X limits for the axes of interest
%    * The last argument(s) is either an absolute index or a pair
%      of row/column indices specifying the axes location in the 
%      axes grid.
%    * (T0, Y0) are original time and amplitude data commensurate in size
%    with YDATA.

%  Copyright 2013 The MathWorks, Inc.

   [ymin,ymax,FlatY] = ydataspan(t0,y0,Xlims);
   ydata = (ymin+ymax)/2 + ydata * ((ymax-ymin)/2+FlatY);
