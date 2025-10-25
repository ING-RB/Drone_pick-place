classdef UITableViewManager < handle
    %UITABLEVIEWMANAGER This is the view manager related to text display.
    % It takes advantage of strategy modules to provide the view information
    % The datastore is requiring.
    
    methods (Abstract)
        outputArg = getFormattedData(obj, model, sourceRowIndices, sourceColIndices);
        
    end
end

