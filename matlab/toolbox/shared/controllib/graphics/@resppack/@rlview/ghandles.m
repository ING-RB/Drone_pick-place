function h = ghandles(this)
%GHANDLES  Returns a 3-D array of handles of graphical objects associated
%          with a rlview object.

%  Copyright 1986-2004 The MathWorks, Inc.
h = [this.Locus(:);this.SystemZero;this.SystemPole];
h = reshape(h,[1 1 length(h)]);
