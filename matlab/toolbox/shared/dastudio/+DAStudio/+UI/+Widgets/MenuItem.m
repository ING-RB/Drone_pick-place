classdef MenuItem < DAStudio.UI.Core.BaseObject    
    properties
        name = '';
        callback = '';
        on = false;
        accel = '';
        visible = true;
        enabled = false;
        toggleaction = 'off';
        icon = '';
    end    
     methods             
        function this = MenuItem()
           this.Type = 'MenuItem';
        end
     end
end