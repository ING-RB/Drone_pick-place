function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with a SectorIndexView object.


%  Copyright 2015 The MathWorks, Inc.

h = [this.Curves];
h = reshape(h,[1 1 length(h)]);