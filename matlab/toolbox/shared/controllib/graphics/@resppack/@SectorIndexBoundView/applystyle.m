function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line styles to @SectorIndexView.

%  Copyright 1986-2015 The MathWorks, Inc.

Color = getstyle(Style,1,1,RespIndex);
if ~Style.EnableTheming
    Color = wrfc.transformColor(Color);
end

controllib.plot.internal.utils.setColorProperty(this.Curves(ishandle(this.Curves)),...
    ["FaceColor","EdgeColor"],Color);
    set(this.Curves(ishandle(this.Curves)),FaceAlpha=0.5);
end