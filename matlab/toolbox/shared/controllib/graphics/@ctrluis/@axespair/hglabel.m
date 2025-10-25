function hlabel = hglabel(h,LabelType)
%HGLABEL  Returns handle(s) of visible HG labels of a given type.

%   Copyright 1986-2004 The MathWorks, Inc.
hlabel = get(h.Axes2d,LabelType);
hlabel = cat(1,hlabel{:});
