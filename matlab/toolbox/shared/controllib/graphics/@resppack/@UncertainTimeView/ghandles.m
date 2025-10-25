function h = ghandles(this)
%  GHANDLES  Returns a 3-D array of handles of graphical objects associated
%            with a UncertainTimeView object.

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2015 The MathWorks, Inc.

if strcmpi(this.UncertainType,'Bounds')
    h =  cat(4,cat(3, this.UncertainPatch));
else
    h =  cat(4,cat(3, this.UncertainLines));
end


