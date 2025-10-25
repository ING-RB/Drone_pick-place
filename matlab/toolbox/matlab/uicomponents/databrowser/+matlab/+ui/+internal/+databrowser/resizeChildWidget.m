function resizeChildWidget(parent, child)
    % Resize handler to position the child widget inside its parent and
    % cover 99% of the parent area.  Parent and child must be ui containers
    % and controls.
    %
    %   resizeChildWidget(parent, child)
    %
    % To be used for resizing purpose in AppContainer

    % Copyright 2020 The MathWorks, Inc.
    
    % Left Bottom Width Height
    if isa(child,'matlab.ui.container.GridLayout')
        % do not resize uigridlayout.  it is auto.
        return
    else
        availableSize = parent.Position(3:4); % [width height]
        widgetSize = max(floor(0.99 * availableSize),[1 1]); % ensure non-zero
        topMargin = floor(0.5 * (availableSize(2)-widgetSize(2))); % minimum 0
        leftMargin = floor(0.5 * (availableSize(1)-widgetSize(1))); % minimum 0
        child.Position = [leftMargin availableSize(2) - widgetSize(2) - topMargin widgetSize];
    end
end        
