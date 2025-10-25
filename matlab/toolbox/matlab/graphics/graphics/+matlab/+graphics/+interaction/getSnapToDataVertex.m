function val = getSnapToDataVertex(obj)
%

%   Copyright 2020-2023 The MathWorks, Inc.

if matlab.graphics.interaction.interactionoptions.useInteractionOptions(obj)
    val = obj.InteractionOptions.DatatipsPlacementMethod;
else
    hFig = ancestor(obj,'figure');
    dm = datacursormode(hFig);
    val = dm.SnapToDataVertex;
end
end
