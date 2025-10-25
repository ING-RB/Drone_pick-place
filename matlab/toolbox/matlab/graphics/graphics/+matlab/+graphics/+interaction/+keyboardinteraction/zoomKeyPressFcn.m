function keyconsumed = zoomKeyPressFcn(ax, evd)
%

%   Copyright 2020-2023 The MathWorks, Inc.

% If the key being pressed corresponds to an up or down arrow key, perform
% the zoom, and return true.
% Else, return false to indicate that the key event was not consumed. 

% Factor is the quantum by which we zoom in / out. 
% Values greater than 1 mean we zoom in.
% Values lesser than 1 mean we zoom out.
factor = 1.1;

switch evd.Key
    case {'uparrow', 'plus'}
        localDoZoom(ax, factor);
        keyconsumed = true;
    case {'downarrow', 'minus'}
        localDoZoom(ax, 1/factor);
        keyconsumed = true;
    otherwise
        keyconsumed = false;
end

end

function localDoZoom(ax, factor)

import matlab.graphics.interaction.internal.zoom.zoomAxisAroundPoint;
import matlab.graphics.interaction.internal.UntransformLimits;
import matlab.graphics.interaction.internal.initializeView;
import matlab.graphics.interaction.validateAndSetLimits;

drawnow nocallbacks;

initializeView(ax);
new_lims = zoomAxisAroundPoint([0,1], 0.5, factor);

normalized_limits = [new_lims new_lims new_lims];

%Constrain the limits to the specified dimenion/s 
constrained_limits = matlab.graphics.interaction.internal.constrainNormalizedLimitsToDimensions(normalized_limits, ax.InteractionOptions.LimitsDimensions);

%Set the new limits
[new_xlim, new_ylim, new_zlim] = UntransformLimits(ax.ActiveDataSpace,constrained_limits(1:2),constrained_limits(3:4),constrained_limits(5:6));

% Checks the following:
% 1. Zooming out?
% 2. ZoomLimits are bounded? 
% 3. Inside the bounds?
if(factor < 1 && ax.InteractionOptions.ZoomLimitsBounded && matlab.graphics.interaction.internal.isInsideInteractionOptionsOuterBounds(ax))

   % If the above is true then it will grab the interaction options bounds and set them 

   bounds = matlab.graphics.interaction.interactionoptions.getOuterLimitsBounds(ax);
   [new_xlim, new_ylim, new_zlim] =  matlab.graphics.interaction.internal.boundLimitsAllAxes([new_xlim,new_ylim,new_zlim],bounds, ax, false, true);
  
end


            
if is2D(ax)
   validateAndSetLimits(ax,new_xlim,new_ylim);
else
   validateAndSetLimits(ax,new_xlim,new_ylim,new_zlim);
end

end


