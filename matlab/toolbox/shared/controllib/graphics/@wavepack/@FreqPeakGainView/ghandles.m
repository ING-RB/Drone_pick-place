function h = ghandles(this)
%GHANDLES  Returns a 3-D array of handles of graphical objects associated
%          with a FreqPeakRespView object.

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2013 The MathWorks, Inc.

GridSize = this.AxesGrid.Size;
RespSize = size(this.Points);

pad = repmat(wrfc.createDefaultHandle, [RespSize(1:2), prod(GridSize(3:end))-1]);

VLines = cat(3,this.VLines,pad);
HLines = cat(3,this.HLines,pad);
Points = cat(3,this.Points,pad);
h = cat(length(GridSize)+1, VLines, HLines, Points);
