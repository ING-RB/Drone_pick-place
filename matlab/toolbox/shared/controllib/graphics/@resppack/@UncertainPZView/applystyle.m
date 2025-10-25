function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line style to @view objects.
%
%  Applies line style to all gobjects making up the @view instance
%  (as returned by GHANDLES).

%  Author(s): John Glass
%  Copyright 1986-2014 The MathWorks, Inc.

% Line width adjustment
LW = Style.LineWidth;
pMS = ceil(6.5+LW);  % pole marker size
zMS = ceil(5.5+LW);

[Ny,Nu] = size(this.UncertainPoleCurves);
for ct1 = 1:Ny
   for ct2 = 1:Nu
      Color = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
      if ~Style.EnableTheming
        Color = localGetColor(Color);
      end
      set(this.UncertainPoleCurves(ct1,ct2,:),'LineWidth',LW,'MarkerSize',pMS);
      controllib.plot.internal.utils.setColorProperty(this.UncertainPoleCurves(ct1,ct2,:),"Color",Color);
      set(this.UncertainZeroCurves(ct1,ct2,:),'LineWidth',LW,'MarkerSize',zMS)
      controllib.plot.internal.utils.setColorProperty(this.UncertainZeroCurves(ct1,ct2,:),"Color",Color);
   end
end



function Color = localGetColor(Color)

hsvcolor = rgb2hsv(Color);
Color = hsv2rgb(hsvcolor.*[1,.2,1]);


