function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies style of parent @waveform to characteristics dots.

%  Copyright 2013-2015 The MathWorks, Inc.
[nr, nc] = size(this.Points);
for i = 1:nr
   for j = 1:nc
      Color = getstyle(Style,RowIndex(i),ColumnIndex(j),RespIndex);
      controllib.plot.internal.utils.setColorProperty(this.Points(i,j),...
          ["Color","MarkerEdgeColor","MarkerFaceColor"],Color);
   end
end
