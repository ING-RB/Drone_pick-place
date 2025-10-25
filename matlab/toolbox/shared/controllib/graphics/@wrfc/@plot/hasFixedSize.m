function [hasFixedRowSize,hasFixedColSize] = hasFixedSize(this)
%HASFIXEDSIZE  Indicates when plot's row or column size is fixed, i.e.,
%              independent of the plot contents.

%  Copyright 1986-2004 The MathWorks, Inc.
hasFixedRowSize = false;
hasFixedColSize = false;