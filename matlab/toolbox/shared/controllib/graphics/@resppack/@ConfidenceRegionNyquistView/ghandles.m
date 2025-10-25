function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with a UncertainNyquistView object.

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2011 The MathWorks, Inc.

h = cat(3, this.UncertainNyquistCurves,this.UncertainNyquistNegCurves, ...
    this.UncertainNyquistMarkers,this.UncertainNyquistNegMarkers);

