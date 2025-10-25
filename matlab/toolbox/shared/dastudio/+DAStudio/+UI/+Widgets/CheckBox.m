classdef CheckBox < DAStudio.UI.Core.BaseWidget    
    properties
        Checked = false;
    end
    
     methods             
        function this = CheckBox()
           this.Type = 'CheckBox';
        end
     end
end