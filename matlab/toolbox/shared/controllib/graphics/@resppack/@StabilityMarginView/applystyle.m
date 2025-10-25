function applystyle(this,Style,RowIndex,ColIndex,RespIndex)
%APPLYSTYLE  Applies style of parent response.

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.
Color = getstyle(Style,1,1,RespIndex);
controllib.plot.internal.utils.setColorProperty([this.MagPoints(ishandle(this.MagPoints)) ; ...
      this.PhasePoints(ishandle(this.PhasePoints))],...
   ["Color","MarkerEdgeColor","MarkerFaceColor"],Color);