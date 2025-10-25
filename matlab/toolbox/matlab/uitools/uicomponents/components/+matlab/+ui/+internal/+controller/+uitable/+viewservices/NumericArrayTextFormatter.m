classdef NumericArrayTextFormatter < matlab.ui.internal.controller.uitable.viewservices.TextFormatter
    %NUMERICARRAYTEXTFORMATTER This implements the TextFormatter interface.
    
    methods (Static)
        % Returns true if the strategy supports the datatype
        function doesSupportData = supportsData(data)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            
            doesSupportData = isnumeric(data);
            
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
                matlab.ui.internal.controller.uitable.utils.DataFormatUtils.formatNumericData(...
                data, 'short');
            
        end
    end
end

