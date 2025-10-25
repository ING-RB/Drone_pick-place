function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with a sigmaview object.

%  Copyright 1986-2014 The MathWorks, Inc.
h = reshape([this.MagPatch;this.PhasePatch],[1 1 2]);