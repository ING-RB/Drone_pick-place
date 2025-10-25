function hy = yextent(this,VisFilter)
%YEXTENT  Gathers all handles contributing to Y limits.

%  Author(s): P. Gahinet, Bora Eryilmaz
%  Copyright 1986-2011 The MathWorks, Inc.

% Handles contributing to mag extent
hy = this.MagCurves;
hy(~VisFilter(:,:)) = wrfc.createDefaultHandle;
