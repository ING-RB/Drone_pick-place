function applystyle(this,Style,~,~,RespIndex)
% Applies specific style.

%  Copyright 1986-2012 The MathWorks, Inc.
[Color,~,~] = getstyle(Style,1,1,RespIndex);

if ~Style.EnableTheming
    Color = wrfc.transformColor(Color);
end

allPatches = [this.MagPatch ; this.PhasePatch];
allPatches = allPatches(ishandle(allPatches));
set(allPatches,'FaceAlpha',0.5);

controllib.plot.internal.utils.setColorProperty(allPatches,["FaceColor","EdgeColor"],Color);

