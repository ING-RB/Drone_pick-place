function keyconsumed = panKeyPressFcn(ax, evd)
%

%   Copyright 2020-2023 The MathWorks, Inc.

% If the key being pressed corresponds to arrow key, perform the pan and
% return true.
% Else, return false to indicate that the key event was not consumed.

% Sensitivity is the quantum by which the limits should change.
% The higher the value, the more drastic the shift.
sensitivity = 5;

switch evd.Key
    case 'leftarrow'
        pixel_diff = [-sensitivity 0];
        localDoPan(ax, pixel_diff);
        keyconsumed = true;
    case 'rightarrow'
        pixel_diff = [sensitivity 0];
        localDoPan(ax, pixel_diff);
        keyconsumed = true;
    case 'uparrow'
        pixel_diff = [0 sensitivity];
        localDoPan(ax, pixel_diff);
        keyconsumed = true;
    case 'downarrow'
        pixel_diff = [0 -sensitivity];
        localDoPan(ax, pixel_diff);
        keyconsumed = true;
    otherwise
        keyconsumed = false;
end

end

function localDoPan(ax, pixel_diff)

import matlab.graphics.interaction.internal.initializeView;
initializeView(ax);

if(is2D(ax))
    localDo2DPan(ax, pixel_diff);
else
    localDo3DPan(ax, pixel_diff);
end

end

function localDo2DPan(ax, pixel_diff)

import matlab.graphics.interaction.internal.pan.panFromPixelToPixel2D;
import matlab.graphics.interaction.internal.UntransformLimits;
import matlab.graphics.interaction.validateAndSetLimits;
import matlab.graphics.interaction.internal.constrainNormalizedLimitsToDimensions;

orig_limits = [0, 1, 0, 1, 0, 1];
wh = ax.GetLayoutInformation().PlotBox(3:4);
dataspace = ax.ActiveDataSpace;


transformed_limits = panFromPixelToPixel2D(...
    orig_limits, pixel_diff, wh);

transformed_limits = [transformed_limits, 0, 1];

clamped_limits = constrainNormalizedLimitsToDimensions(transformed_limits, ...
    ax.InteractionOptions.LimitsDimensions);

[new_x_limits, new_y_limits] = UntransformLimits(dataspace, ...
    clamped_limits(1:2), ...
    clamped_limits(3:4), ...
    [0 1]);

% Interaction Options OuterLimits
[new_x_limits, new_y_limits] = calcOuterLimits(ax, new_x_limits, new_y_limits, [0 1]);

validateAndSetLimits(ax, new_x_limits, new_y_limits);

end

function localDo3DPan(ax, pixel_diff)

import matlab.graphics.interaction.internal.pan.panFromPointToPoint3D;
import matlab.graphics.interaction.internal.pan.getMVP;
import matlab.graphics.interaction.internal.pan.transformPixelsToPoint;
import matlab.graphics.interaction.internal.UntransformLimits;
import matlab.graphics.interaction.validateAndSetLimits;
import matlab.graphics.interaction.internal.constrainNormalizedLimitsToDimensions;

orig_limits = [0, 1, 0, 1, 0, 1];
dataspace = ax.ActiveDataSpace;

mvp_matrix = getMVP(ax);

orig_ray = transformPixelsToPoint(mvp_matrix, [0, 0]);
curr_ray = transformPixelsToPoint(mvp_matrix, pixel_diff);

transformed_limits = panFromPointToPoint3D(orig_limits, orig_ray, curr_ray);


clamped_limits = constrainNormalizedLimitsToDimensions(transformed_limits, ...
    ax.InteractionOptions.LimitsDimensions);


[new_x_lims, new_y_lims, new_z_lims] = UntransformLimits(dataspace, ...
    clamped_limits(1:2), ...
    clamped_limits(3:4), ...
    clamped_limits(5:6));

% Interaction Options OuterLimits
[new_x_lims, new_y_lims, new_z_lims] = calcOuterLimits(ax, new_x_lims, new_y_lims, new_z_lims);

validateAndSetLimits(ax, new_x_lims, new_y_lims, new_z_lims);

end

function [newX, newY, newZ] = calcOuterLimits(ax, curX,curY,curZ)
    
    if(ax.InteractionOptions.PanLimitsBounded && matlab.graphics.interaction.internal.isInsideInteractionOptionsOuterBounds(ax))

        % If the above is true then it will grab the interaction options bounds and set them 
        bounds = matlab.graphics.interaction.interactionoptions.getOuterLimitsBounds(ax);
        [newX, newY, newZ] =  matlab.graphics.interaction.internal.boundLimitsAllAxes([curX,curY,curZ],bounds,ax,true,true);

    else
        newX = curX; 
        newY = curY; 
        newZ = curZ; 
    end
end

