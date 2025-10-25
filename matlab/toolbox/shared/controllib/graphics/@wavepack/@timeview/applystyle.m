function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line style to @view objects.
%
%  Applies line style to all gobjects making up the @view instance
%  (as returned by GHANDLES).

%  Copyright 1986-2004 The MathWorks, Inc.
Curves = ghandles(this);
for ct1 = 1:size(Curves,1)
    for ct2 = 1:size(Curves,2)
        [Color,LineStyle,Marker] = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
        c = Curves(ct1,ct2,:);

        set(c(ishandle(c)),'LineStyle',LineStyle,'Marker',Marker,'LineWidth',Style.LineWidth);
        controllib.plot.internal.utils.setColorProperty(c(ishandle(c)),"Color",Color);
    end
end
