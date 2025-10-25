function hy = yextent(this,VisFilter)
%YEXTENT  Gathers all handles contributing to Y limits.
%
%  HY is a 2D array where H(i,:) contains the visible
%  handles for the i-th row of axes (i-th output).

%  Author(s): P. Gahinet, Bora Eryilmaz
%  Copyright 1986-2010 The MathWorks, Inc.

% Handles contributing to mag extent
if this.ShowFullContour
   hy = [this.PosCurves,this.NegCurves];
   VisFilter = [VisFilter,VisFilter];
else
   hy = this.PosCurves;
end
hy(~VisFilter) = wrfc.createDefaultHandle;