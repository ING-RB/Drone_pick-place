function applystyle(this,Style,~,~,RespIndex)
%APPLYSTYLE  Applies line styles to view object

%  Copyright 1986-2012 The MathWorks, Inc.
Color = getstyle(Style,1,1,RespIndex);
if ~Style.EnableTheming
    Color = wrfc.transformColor(Color);
end

if ishandle(this.Patch)
   controllib.plot.internal.utils.setColorProperty(this.Patch,["FaceColor","EdgeColor"],Color);
   set(this.Patch,FaceAlpha=0.5);
end