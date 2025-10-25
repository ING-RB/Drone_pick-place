function applystyle(this,Style,RowIndex,ColIndex,RespIndex)
%APPLYSTYLE  Applies style of parent @waveform to characteristics dots.

%  Copyright 2013-2015 The MathWorks, Inc.
[nr,nc] = size(this.Points);
for ir = 1:nr
   for ic = 1:nc
      Color = getstyle(Style,RowIndex(ir),ColIndex(ic),RespIndex);
      controllib.plot.internal.utils.setColorProperty(this.Points(ir,ic),'Color',Color)
   end
end
