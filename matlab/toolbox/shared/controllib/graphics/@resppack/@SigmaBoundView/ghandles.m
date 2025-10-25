function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with a sigmaview object.

%  Author(s): C. Buhr
%  Copyright 1986-2012 The MathWorks, Inc.

h = [this.Curves];
h = reshape(h,[1 1 length(h)]);