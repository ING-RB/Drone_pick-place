classdef qeContextMenuEventData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for "qeRightClick"
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        ContextObject;
        InteractionInformation;
    end
    
    methods

        function obj = qeContextMenuEventData(tbl,cellIdx)
            % for white space,  cellIdx is [], otherwise, a 1-by-2 index array 
            if isempty(cellIdx)
                rowIdx = [];
                colIdx = [];
            else
                rowIdx = cellIdx(1);
                colIdx = cellIdx(2);
            end

            obj = obj@matlab.ui.eventdata.internal.AbstractEventData();
            obj.ContextObject = tbl;
            obj.InteractionInformation = struct(...
                'RowHeader',false,...
                'ColumnHeader',false,...
                'DisplayRow',rowIdx,...
                'DisplayColumn',colIdx,...
                'Row',rowIdx,...
                'Column',colIdx...
                );
        end
        
    end
    
end

