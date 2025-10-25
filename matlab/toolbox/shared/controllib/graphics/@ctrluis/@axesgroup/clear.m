function clear(h)
%CLEAR  Clears wrapper object without destroying axes.

%   Author(s): P. Gahinet
%   Copyright 1986-2004 The MathWorks, Inc.

h.Axes = [];
delete(h)