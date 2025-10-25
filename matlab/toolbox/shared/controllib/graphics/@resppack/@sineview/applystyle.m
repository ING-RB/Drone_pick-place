function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line style to @view objects.
%
%  Applies line style to all gobjects making up the @view instance
%  (as returned by GHANDLES).

%  Author(s): Erman Korkut 17-Mar-2009
%  Copyright 1986-2009 The MathWorks, Inc.
Curves = ghandles(this);
for ct1 = 1:size(Curves,1)
   for ct2 = 1:size(Curves,2)
      [Color,LineStyle,Marker] = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
      c = Curves(ct1,ct2,:);
      set(c(ishandle(c)),'LineStyle',LineStyle,'Marker',Marker,'LineWidth',Style.LineWidth);
      controllib.plot.internal.utils.setColorProperty(c(ishandle(c)),"Color",Color);
   end
end

% Repeat the same for steady state, making lines thicker
SSCurves = this.SSCurves;
for ct1 = 1:size(SSCurves,1)
   for ct2 = 1:size(SSCurves,2)
      [Color,LineStyle,Marker] = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
      c = SSCurves(ct1,ct2,:);
      set(c(ishandle(c)),'LineStyle',LineStyle,'Marker',Marker,'LineWidth',Style.LineWidth+2);
      controllib.plot.internal.utils.setColorProperty(c(ishandle(c)),"Color",Color);
   end
end

