function ydata = normalize(~,ydata,Xlims,t0,y0)
%NORMALIZE  Scales Y data to normalized time data range.
%
%  Input arguments:
%    * YDATA is the Y data to be normalized
%    * XLIMS are the X limits for the axes of interest
%    * (T0, Y0) are original time and amplitude data commensurate in size
%    with YDATA.

%  Copyright 2013 The MathWorks, Inc.

[ymin,ymax,FlatY] = ydataspan(t0,y0,Xlims);
ydata = (ydata - (ymin+ymax)/2)/((ymax-ymin)/2+FlatY);
