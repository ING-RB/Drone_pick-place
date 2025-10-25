function h = ghandles(this)
%GHANDLES  Returns a 3-D array of handles of graphical objects associated
%          with a view object.

%  Copyright 1986-2020 The MathWorks, Inc.
h = cat(3, this.FiniteSV, this.InfiniteSV, this.ErrorBnd);