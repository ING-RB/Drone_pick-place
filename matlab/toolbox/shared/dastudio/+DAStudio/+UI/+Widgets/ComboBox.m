classdef ComboBox < DAStudio.UI.Core.BaseWidget    
    properties
        Editable = false;
        CurrentText;
        PlaceholderText;
        Entries = [];
        Index = -1;     
    end
    
     methods             
        function this = ComboBox()
           this.Type = 'ComboBox';
        end
     end
end