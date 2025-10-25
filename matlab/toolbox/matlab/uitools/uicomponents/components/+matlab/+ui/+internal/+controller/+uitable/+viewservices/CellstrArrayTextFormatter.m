classdef CellstrArrayTextFormatter < matlab.ui.internal.controller.uitable.viewservices.TextFormatter
    %CELLSTRARRAYTEXTFORMATTER This implements the TextFormatter interface.
    
    methods (Static)
        % Returns true if the strategy supports the datatype
        function doesSupportData = supportsData(data)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            
            doesSupportData = iscellstr(data);  
            
        end
    end
    
    methods
        function viewFormattedValue = getFormattedData(obj, model, sourceRowIndices, sourceColIndices, sourceDataType)
            % GETFORMATTEDDATA - returns a cell array matching the row
            % range and column range of the data.
            
            colArray = obj.getValidColumnRange(model, sourceColIndices);
            viewFormattedValue = ...
                obj.formatData(model.Data(sourceRowIndices, colArray));
            
        end
    end
    methods(Static)
        function viewFormattedValue = formatData(data)
            % GETFORMATTEDDATA - returns a cell array matching the row
            % range and column range of the data.
            
            viewFormattedValue = data;
            
        end
    end
end

