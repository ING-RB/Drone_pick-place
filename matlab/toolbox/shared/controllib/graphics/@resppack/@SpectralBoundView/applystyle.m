function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line style to @view objects.
%
%  Applies line style to all gobjects making up the @view instance
%  (as returned by GHANDLES).

%  Author(s): C. Buhr
%  Copyright 1986-2012 The MathWorks, Inc.
Curves = ghandles(this);
for ct1 = 1:size(Curves,1)
   for ct2 = 1:size(Curves,2)
      Color = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
      if ~Style.EnableTheming
        Color = wrfc.transformColor(Color);
      end
      controllib.plot.internal.utils.setColorProperty(this.SpectralRadiusPatch,["FaceColor","EdgeColor"],Color);
      set(this.SpectralRadiusPatch,FaceAlpha=0.6);
      controllib.plot.internal.utils.setColorProperty(this.SpectralAbscissaPatch,["FaceColor","EdgeColor"],Color);
      set(this.SpectralAbscissaPatch,FaceAlpha=0.6);
   end
end






