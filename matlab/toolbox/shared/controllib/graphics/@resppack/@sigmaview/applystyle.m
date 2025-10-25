function applystyle(this,Style,~,~,RespIndex)
%APPLYSTYLE  Applies line styles to @sigmaview.

%  Copyright 1986-2021 The MathWorks, Inc.
[Color,LineStyle,Marker] = getstyle(Style,1,1,RespIndex);

set(this.Curves(:),'LineStyle',LineStyle,'Marker',Marker,'LineWidth',Style.LineWidth);
controllib.plot.internal.utils.setColorProperty(this.Curves(:),"Color",Color);

controllib.plot.internal.utils.setColorProperty([this.PosArrows(:);this.NegArrows(:)],...
   ["FaceColor","EdgeColor"],Color);
   

