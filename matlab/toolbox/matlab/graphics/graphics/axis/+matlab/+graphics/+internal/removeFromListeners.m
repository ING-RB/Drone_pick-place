function removeFromListeners(p, ax)
% This function is undocumented and will change in a future release

%   Copyright 2010-2013 The MathWorks, Inc.

% Create subplot listeners to align plot boxes automatically

        if isappdata(ax, 'SubplotDeleteListenersManager')
                temp = getappdata(ax, 'SubplotDeleteListenersManager');
                delete(temp.SubplotDeleteListener);
                rmappdata(ax, 'SubplotDeleteListenersManager');
        end
        
        if isappdata(p, 'SubplotListenersManager')
            slm = getappdata(p, 'SubplotListenersManager');
            slm.removeFromListeners(ax);
            setappdata(p, 'SubplotListenersManager', slm)
        end 
end