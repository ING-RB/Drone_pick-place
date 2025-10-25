function applystyle(this,Style,RowIndex,ColIndex,RespIndex)
%APPLYSTYLE  Applies style of parent @waveform to characteristics dots.

%  Copyright 2015 The MathWorks, Inc.
[nr, nc] = size(this.Points);
for i = 1:nr
   for j = 1:nc
      Color = getstyle(Style,RowIndex(i),ColIndex(j),RespIndex);
      controllib.plot.internal.utils.setColorProperty(this.Points(i,j),'Color',Color)
   end
end
