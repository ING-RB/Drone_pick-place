classdef StringArrayTextFormatter < matlab.ui.internal.controller.uitable.viewservices.TextFormatter
    %STRINGARRAYTEXTFORMATTER This implements the TextFormatter interface.
    
    methods (Static)
        % Returns true if the strategy supports the datatype
        function doesSupportData = supportsData(data)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            % This formatter supports string arrays and empty char.  Empty
            % char is the only char variant supported by Table Data.
            
            
            doesSupportData = isstring(data) || ischar(data);  
            
        end
    end
    
    methods
        function viewFormattedValue = getFormattedData(obj, model, sourceRowIndices, sourceColIndices, sourceDataType)
            % GETFORMATTEDDATA - returns a cell array matching the row
            % range and column range of the data.

            colArray = obj.getValidColumnRange(model, sourceColIndices);
            viewFormattedValue = ...
                obj.formatData(...
                model.Data(sourceRowIndices, colArray));
            
        end
    end
    
    methods(Static)
        function viewFormattedValue = formatData(data)
            % GETFORMATTEDDATA - returns a cell array matching the row
            % range and column range of the data.
            
            viewFormattedValue = ...
                cellstr(data);
            
        end
    end
end

