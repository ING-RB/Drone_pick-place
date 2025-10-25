% ImportActions
% Action to track the header row of the data in the Import Tool

% Copyright 2018 The MathWorks, Inc.

classdef ImportActions < handle
    
    methods        
        function status = setImportAction(this, ~, funcStr)
            doc = this.manager.FocusedDocument;  
            status = doc.ViewModel.handleImportActions(funcStr);
        end              
    end
end

