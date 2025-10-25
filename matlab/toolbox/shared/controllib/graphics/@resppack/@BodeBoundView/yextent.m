function hy = yextent(this,VisFilter)
% YEXTENT  Gathers all handles contributing to Y limits.

%  Copyright 1986-2014 The MathWorks, Inc.
hy = [this.MagPatch;this.PhasePatch];
hy = hy(VisFilter,:); % = wrfc.createDefaultHandle;  % discard invisible curves
