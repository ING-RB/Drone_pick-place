function specifyIconID(component, icon, width, height)
    %

    % Do not remove above white space
    % Copyright 2022 The MathWorks, Inc.

    arguments 
        component (1,1) matlab.ui.control.internal.model.mixin.IconIDableComponent
        icon char = '';
        width double {mustBePositive} = 24;
        height double {mustBePositive} = 24;
    end

    iconID = struct();
    if ~isempty(icon)
        if nargin == 2
            iconID = struct('id', icon);
        elseif nargin == 3
            iconID = struct('id', icon, 'width', width, 'height', width);
        else
            iconID = struct('id', icon, 'width', width, 'height', height);
        end
    end
    component.specifyIconID(iconID);
end

