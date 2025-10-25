function clear(h)
%CLEAR  Clears wrapper object without destroying axes.

%   Copyright 1986-2004 The MathWorks, Inc.

h.Axes = [];
h.BackgroundAxes = [];

delete(h)