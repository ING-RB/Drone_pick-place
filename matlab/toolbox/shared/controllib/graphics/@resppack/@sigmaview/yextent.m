function hy = yextent(this,VisFilter)
%  YEXTENT  Gathers all handles contributing to Y limits.

%  Author: Pascal Gahinet
%  Revised: Kamesh Subbarao, 10-16-2001
%  Copyright 1986-2010 The MathWorks, Inc.

hy = this.Curves;
hy(~VisFilter) = wrfc.createDefaultHandle;  % discard invisible curves
