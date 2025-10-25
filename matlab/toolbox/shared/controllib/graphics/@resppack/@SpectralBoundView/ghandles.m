function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with the SpectralBoundView object.

%  Author(s): Craig Buhr
%  Revised:
%   Copyright 1986-2012 The MathWorks, Inc.

h = cat(3, this.SpectralRadiusPatch, this.SpectralAbscissaPatch);

