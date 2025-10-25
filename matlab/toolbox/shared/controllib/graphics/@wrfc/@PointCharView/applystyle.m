function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies style of parent @waveform to characteristics dots.

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.
[nr,nc] = size(this.Points);
for ct2 = 1:nc
    for ct1 = 1:nr
        Color = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
            controllib.plot.internal.utils.setColorProperty(this.Points(ct1,ct2),...
            ["Color","MarkerEdgeColor","MarkerFaceColor"],Color);
    end
end