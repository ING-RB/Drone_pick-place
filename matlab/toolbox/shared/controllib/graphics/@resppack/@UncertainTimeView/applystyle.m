function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line style to @view objects.
%
%  Applies line style to all gobjects making up the @view instance
%  (as returned by GHANDLES).

%  Author(s): John Glass
%  Copyright 1986-2014 The MathWorks, Inc.

Curves = ghandles(this);

for ct1 = 1:size(Curves,1)
   for ct2 = 1:size(Curves,2)
      [Color] = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
      c = Curves(ct1,ct2,:);
      if ~Style.EnableTheming
        Color = localGetColor(Color);
      end
      if strcmpi(this.UncertainType,'Bounds')
          controllib.plot.internal.utils.setColorProperty(c(ishandle(c)),["FaceColor","EdgeColor"],Color);
          set(c(ishandle(c)),FaceAlpha=0.8);
      else
          controllib.plot.internal.utils.setColorProperty(c(ishandle(c)),'Color',Color);
      end
   end
end



function Color = localGetColor(Color)

hsvcolor = rgb2hsv(Color);
Color = hsv2rgb(hsvcolor.*[1,.2,1]);