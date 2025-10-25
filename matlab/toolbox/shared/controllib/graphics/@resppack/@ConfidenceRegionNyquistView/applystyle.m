function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line style to @view objects.
%
%  Applies line style to all gobjects making up the @view instance
%  (as returned by GHANDLES).

%  Author(s): C. Buhr
%  Copyright 1986-2010 The MathWorks, Inc.

[Ny,Nu] = size(this.UncertainNyquistCurves);
for ct1 = 1:Ny
   for ct2 = 1:Nu
      Color = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
      if ~Style.EnableTheming
        Color = wrfc.transformColor(Color,.5);
      end
      
      controllib.plot.internal.utils.setColorProperty(this.UncertainNyquistCurves(ct1,ct2,:),'Color',Color);
      controllib.plot.internal.utils.setColorProperty(this.UncertainNyquistNegCurves(ct1,ct2,:),'Color',Color);
      controllib.plot.internal.utils.setColorProperty(this.UncertainNyquistMarkers(ct1,ct2,:),'Color',Color);
      controllib.plot.internal.utils.setColorProperty(this.UncertainNyquistNegMarkers(ct1,ct2,:),'Color',Color);

   end
end






