classdef Edit < DAStudio.UI.Core.BaseWidget    
    properties
        Text = '';
        EnableAutoCompletion = false;
    end
    
     methods             
        function this = Edit()
           this.Type = 'Edit';
        end
     end
end