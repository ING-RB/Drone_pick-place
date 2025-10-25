function keyconsumed = rotateKeyPressFcn(ax, evd)
%

%   Copyright 2020-2022  The MathWorks, Inc.

% If the key being pressed corresponds to an arrow key, perform the
% rotation and return true.
% Else, return false to indicate that the key event was not consumed.

% Sensitivity is the quantum by which the view should change.
% The higher the value, the more drastic the shift.
sensitivity = 2;

switch evd.Key
    case 'leftarrow'
        view_diff = [sensitivity 0];
        localDoRotate(ax, view_diff);
        keyconsumed = true;
    case 'rightarrow'
        view_diff = [-sensitivity 0];
        localDoRotate(ax, view_diff);
        keyconsumed = true;
    case 'uparrow'
        view_diff = [0 -sensitivity];
        localDoRotate(ax, view_diff);
        keyconsumed = true;
    case 'downarrow'
        view_diff = [0 sensitivity];
        localDoRotate(ax, view_diff);
        keyconsumed = true;
    otherwise
        keyconsumed = false;
end

end

function localDoRotate(ax, view_diff)

import matlab.graphics.interaction.internal.initializeView;
initializeView(ax);

% Use the colon operator to preserve the shape of the View property.
% See g2889593. 
ax.View(:) = ax.View(:) + view_diff(:);

end

