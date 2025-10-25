function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line styles to @bodeview.

%  Copyright 1986-2021 The MathWorks, Inc.
Curves = cat(3, this.MagCurves, this.PhaseCurves);
Arrows = cat(3, this.MagPosArrows, this.PhasePosArrows,...
    this.MagNegArrows, this.PhaseNegArrows);
for ct1 = 1:size(Curves,1)
    for ct2 = 1:size(Curves,2)
        [Color,LineStyle,Marker] = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);

        set(Curves(ct1,ct2,:),'LineStyle',LineStyle,'Marker',Marker,'LineWidth',Style.LineWidth)
        
        controllib.plot.internal.utils.setColorProperty(Curves(ct1,ct2,:),"Color",Color);
        controllib.plot.internal.utils.setColorProperty(Arrows(ct1,ct2,:),["FaceColor","EdgeColor"],Color);
    end
end