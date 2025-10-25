function cleargrid(h,varargin)
%CLEARGRID  Clears grid lines.

%   Copyright 1986-2008 The MathWorks, Inc.

delete(h.GridLines(ishghandle(h.GridLines)))
h.GridLines = [];
