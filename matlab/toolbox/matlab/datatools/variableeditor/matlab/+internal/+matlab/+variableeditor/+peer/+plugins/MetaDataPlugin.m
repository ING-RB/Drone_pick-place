
classdef MetaDataPlugin < internal.matlab.variableeditor.peer.plugins.ServerConnectedPlugin
    % Base Plugin that communicates during metadata set events. 
    % To be implemented by other plugins that need to update any metaData
    % when DataStore communicates metadata requests or updates
    
    % Copyright 2019-2024 The MathWorks, Inc.
    
    methods
        function updateRowModelInformation(~, startRow, endRow)
        end
        
        function updateColumnModelInformation(~, startColumn, endColumn)
        end
        
        function updateCellModelInformation(~, startRow, endRow, startColumn, endColumn)
        end
        
        function updateTableModelInformation(~)
        end
    end
end

