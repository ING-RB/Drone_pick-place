function hy = yextent(this,VisFilter)
%YEXTENT  Gathers all handles contributing to Y limits.

%  Copyright 1986-2010 The MathWorks, Inc.

hy = this.Curves;
hy(~VisFilter) = wrfc.createDefaultHandle;  % discard invisible curves