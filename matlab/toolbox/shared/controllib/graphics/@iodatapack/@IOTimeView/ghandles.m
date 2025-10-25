function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with a IOTiemView object.

%  Copyright 2013 The MathWorks, Inc.
h = cat(3, this.Curves);

