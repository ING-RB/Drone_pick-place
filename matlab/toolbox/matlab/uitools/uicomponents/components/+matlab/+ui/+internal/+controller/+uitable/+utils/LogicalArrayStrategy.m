classdef LogicalArrayStrategy< matlab.ui.internal.controller.uitable.utils.ArrayWithColumnFormatSupportStrategy
    %LOGICALARRAYSTRATEGY - This contains any code that specialized for
    %when the Data property contains logical array (vs table, cell or
    %numeric array).
        
    methods (Static)
        function dataType = getDataType(data)
            % GETDATATYPE - Return cell array of strings representing the
            % datatype sent to the view for each column
            
            dataType = repmat({class(data)}, 1, size(data, 2));
        end
        
        function doesSupportGroup = supportsGroupColumnSize()
            % SUPPORTSGROUPCOLUMNSIZE - Returns true if this strategy supports group
            % column size that is non-default of 1
            
            doesSupportGroup = false;            
        end 
        
        function doesSupportData = supportsData(data)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            
            doesSupportData = islogical(data);
            
        end
        
        function supportsSorting = dataSupportsSorting(data, columnIndex, datatype)
            % DATASUPPORTSSORTING - Returns true if the column of data
            % supports sorting, returns false if not.  Returns a boolean
            % array the same size as columnIndex;
            supportsSorting = true(size(columnIndex));
        end
    end
end