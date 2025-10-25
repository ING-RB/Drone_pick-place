function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with a TimePeakRespView object.

%  Author(s): Bora Eryilmaz
%  Revised:
%  Copyright 1986-2005 The MathWorks, Inc.

h = cat(3, this.VLines, this.HLines, this.Points);

% REVISIT: Include line tips when handle(NaN) workaround removed
