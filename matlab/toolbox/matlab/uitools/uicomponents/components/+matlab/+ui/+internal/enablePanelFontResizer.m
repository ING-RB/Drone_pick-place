function enablePanelFontResizer(enable)
% This function is undocumented and will change in a future release

% ENABLEPANELFONTRESIZER Enables or disables Apps OBD workaround to resize uipanel FontSize
% This is meant to workaround the different sized Panel header that leads to clipped components.
%
% ENABLEPANELFONTRESIZER(true) Enables listener that will reduce the FontSize property of
% all Panel objects upon creation.
%
% ENABLEPANELFONTRESIZER(false) Disables listener that will reduce the FontSize property of
% all Panel objects upon creation.
    
% Copyright 2020 The MathWorks, Inc.
    
    persistent listener;  % Singleton listener

    % Create the listener if it hasn't been created yet
    if isempty(listener)
        PanelClass = ?matlab.ui.container.Panel;
        listener = addlistener(PanelClass,'InstanceCreated',@(o,e)ResizePanelFontSize(o,e));
    end
    
    % Enable or disable the listener
    listener.Enabled = enable;
end

function ResizePanelFontSize(~, evt)
    panel = evt.Instance;
    try
        % Add a dynamic property to mark this Panel as having been resized
        addprop(panel,'ResizedForOBD');
    catch ME %#ok<NASGU>
    end

    % Only resize the Panel once (InstanceCreated can be called multiple times).
    if isempty(panel.ResizedForOBD)
        panel.ResizedForOBD = true;
        set(panel,'FontSize',get(panel,'FontSize')-3);  % Decrease FontSize by 3
    end
end
