classdef Panel < DAStudio.UI.Core.BaseWidget  
    properties
       Direction = 'LeftToRight';
       Children = {};
       Stretches = [];
    end
    
     methods             
        function this = Panel()
           this.Type = 'Panel';
        end
     end
end