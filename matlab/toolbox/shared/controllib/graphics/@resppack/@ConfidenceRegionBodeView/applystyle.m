function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line style to @view objects.
%
%  Applies line style to all gobjects making up the @view instance
%  (as returned by GHANDLES).

%  Author(s): C. Buhr
%  Copyright 1986-2010 The MathWorks, Inc.

Curves = ghandles(this);

for ct1 = 1:size(Curves,1)
    for ct2 = 1:size(Curves,2)
        Color = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
        if ~Style.EnableTheming
            Color = wrfc.transformColor(Color);
        end

        hCurves = Curves(ct1,ct2,:);
        hCurves = hCurves(ishandle(hCurves));

        if strcmpi(this.UncertainType,'Bounds')
            controllib.plot.internal.utils.setColorProperty(hCurves,"FaceColor",Color);
            set(hCurves,EdgeColor='none',FaceAlpha=0.2);
        else
            controllib.plot.internal.utils.setColorProperty(hCurves,"Color",Color);
        end
    end
end



