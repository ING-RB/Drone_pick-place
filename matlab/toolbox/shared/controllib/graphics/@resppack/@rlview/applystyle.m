function applystyle(this,Style,RowIndex,ColumnIndex,RespIndex)
%APPLYSTYLE  Applies style to root locus plot.

%  Copyright 1986-2004 The MathWorks, Inc.
[Color,LineStyle,Marker] = getstyle(Style,1,1,RespIndex);

set(this.Locus,'LineStyle',LineStyle,'Marker',Marker,'LineWidth',Style.LineWidth)
controllib.plot.internal.utils.setColorProperty(this.Locus,"Color",Color);
controllib.plot.internal.utils.setColorProperty([this.SystemZero,this.SystemPole],"Color",Color);
