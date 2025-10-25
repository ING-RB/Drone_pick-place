function [pts] = getArrowPoints(pos, dir)
% This function is for internal use only. It may be removed in the future.

%getArrowPoints Get points to draw an error for the conversion block mask
% according to the block's position (width/height) and orientation /
% direction.

% Copyright 2017-2018 The MathWorks, Inc.

switch dir
    case 'right'
        sign = 1;
        xyIndices = [1, 2];
    case 'left'
        sign = -1;
        xyIndices = [1, 2];
    case 'down'
        sign = -1;
        xyIndices = [2, 1];
    case 'up'
        sign = 1;
        xyIndices = [2, 1];
end

whFixed = [15, 15]; % Desired fixed width and height
whMin = [100, 25]; % Minimum width and height
wh = pos(3:4) - pos(1:2);
wh = wh(xyIndices);

% Draw arrows
if all(wh >= whMin)
    % Keep size fixed
    scale = whFixed ./ wh;
    center = [0.5, 0.5];
    pts = getSimpleArrowPoints(center, scale * sign);
    pts = pts(:, xyIndices);
else
    pts = zeros(0, 2);
end
end

function [ptsTransformed] = getSimpleArrowPoints(center, scale)
%getSimpleArrowPoints Get arrow points in normalized coordinates, then
% transform and scale according to inputs
L = 1;
w = 0.5;
h = w / 2;
d = L - w;
% Top coordinates
ptsTop = [
    0, 0;
    0, h;
    d, h;
    d, w;
    L, 0;
    ];
% Reflect point across x-axis
ptsReflect = ptsTop(end - 1:-1:1, :);
ptsReflect(:, 2) = -ptsReflect(:, 2);
% Concatenate upper and lower portions
pts = [ptsTop; ptsReflect];
% Move box to be centered and scaled
ptsTransformed = transformBox(pts, center, scale);
end

function [pts] = transformBox(pts, center, scale)
%transformBox Move a set of points (centered by a simple bounding box) to a
% specified center and scale the points about the center.
ptsExtrema = [min(pts, [], 1); max(pts, [], 1)];
ptCenter = (ptsExtrema(1, :) + ptsExtrema(2, :)) / 2;
ptsCentered = pts - ptCenter;
pts = scale .* ptsCentered + center;
end
