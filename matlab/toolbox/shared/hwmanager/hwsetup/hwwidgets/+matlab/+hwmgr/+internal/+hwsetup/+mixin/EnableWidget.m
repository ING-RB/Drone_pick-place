classdef (Abstract) EnableWidget < matlab.hwmgr.internal.hwsetup.WidgetPeer
    % matlab.hwmgr.internal.hwsetup.mixin.EnableWidget is a class that
    % defines an interface for the Enable property of a widget
    
    %   Copyright 2016-2017 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
    
        %Enable - Operational control of the widget indicating if the
        %   user can interact with it or not specified as 'on' or 'off'
        Enable
    end
    
    properties(GetAccess=public, SetAccess=protected)
        % Inherited Properties
        % Peer
    end
    
    methods
        function set.Enable(obj, enable)
            validstr = validatestring(enable, {'on', 'off'});
            
            if(isprop(obj.Peer, 'Enable'))
                obj.Peer.Enable =  validstr;
            else
                obj.setEnable(validstr);
            end
            drawnow(); % change should be immediately reflected
        end
        
        function enable = get.Enable(obj)
            if(isprop(obj.Peer, 'Enable'))
                enable = obj.Peer.Enable;
            else
                enable = obj.getEnable();
            end
        end
      
    end
end