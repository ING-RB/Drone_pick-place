function h = ghandles(this)
%  GHANDLES  Returns a array of handles of graphical objects associated
%            with a ConfidenceRegionSpectrumView object.

%  Author(s): Rajiv Singh
%  Copyright 1986-2011 The MathWorks, Inc.

if strcmpi(this.UncertainType,'Bounds')
    h = this.UncertainMagPatch;
else
    h = this.UncertainMagLines;
end
