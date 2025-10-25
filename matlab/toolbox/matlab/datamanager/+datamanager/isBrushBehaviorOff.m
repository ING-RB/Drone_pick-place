function off = isBrushBehaviorOff(ax)
%isBrushBehaviorOff Test if brush behavior is off

%  Copyright 2015-2023 The MathWorks, Inc.

off = false;
b = hggetbehavior(ax,'Brush','-peek');
if ~isempty(b)
    off = ~b.Enable;
end
if matlab.graphics.interaction.interactionoptions.useInteractionOptions(ax)
    off = ~ax.InteractionOptions.BrushSupported;
end
