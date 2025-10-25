function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies line style to @view objects.
%
%  Applies line style to all gobjects making up the @view instance
%  (as returned by GHANDLES).

%  Author(s): C. Buhr
%  Copyright 1986-2010 The MathWorks, Inc.

% Line width adjustment
LW = Style.LineWidth;
pMS = ceil(6.5+LW);  % pole marker size
zMS = ceil(5.5+LW);

[Ny,Nu] = size(this.UncertainPoleCurves);
for ct1 = 1:Ny
    for ct2 = 1:Nu
        Color = getstyle(Style,RowIndex(ct1),ColumnIndex(ct2),RespIndex);
        if ~Style.EnableTheming
            Color = wrfc.transformColor(Color);
        end
        
        set(this.UncertainPoleCurves(ct1,ct2,:),'LineWidth',LW,'MarkerSize',pMS);
        set(this.UncertainZeroCurves(ct1,ct2,:),'LineWidth',LW,'MarkerSize',zMS);
        
        controllib.plot.internal.utils.setColorProperty(this.UncertainPoleCurves(ct1,ct2,:),"Color",Color);
        controllib.plot.internal.utils.setColorProperty(this.UncertainZeroCurves(ct1,ct2,:),"Color",Color);
    end
end






