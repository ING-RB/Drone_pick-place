function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with a UncertainTimeView object.

%  Copyright 2015 The MathWorks, Inc.

if strcmpi(this.UncertainType,'Bounds')
    h = cat(3, this.UncertainPatch);
else
    h = cat(3, this.UncertainLines);
end
