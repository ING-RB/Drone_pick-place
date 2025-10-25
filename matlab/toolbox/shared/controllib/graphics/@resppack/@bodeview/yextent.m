function hy = yextent(this,VisFilter)
%YEXTENT  Gathers all handles contributing to Y limits.
%
%  HY is a 3D array where HY(:,:,1) contains the visible
%  mag. handles over the I/O grid, and HY(:,:,2) contains 
%  the visible phase handles 

%  Author(s): P. Gahinet, Bora Eryilmaz
%  Copyright 1986-2010 The MathWorks, Inc.

% Handles contributing to mag extent
hmag = this.MagCurves;
hmag(~VisFilter(:,:,1)) = wrfc.createDefaultHandle;

% Handles contributing to mag extent
hphase = this.PhaseCurves;
hphase(~VisFilter(:,:,2)) = wrfc.createDefaultHandle;

% Form HY array
hy = cat(3,hmag,hphase);
