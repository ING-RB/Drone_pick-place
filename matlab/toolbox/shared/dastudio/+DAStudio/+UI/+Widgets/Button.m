classdef Button < DAStudio.UI.Core.BaseWidget    
    properties
        Label = '';
        Icon = '';
        Flat = false;
    end
    
     methods             
        function this = Button()
           this.Type = 'Button';
        end
     end
end