classdef CellArrayTextFormatter < matlab.ui.internal.controller.uitable.viewservices.TextFormatter
    %CELLARRAYTEXTFORMATTER This implements the TextFormatter
    %   interface in order to create text formatted considering the raw 
    %   uitable source data and the ColumnFormat property.
    
    methods
        
        function obj = CellArrayTextFormatter()

        end
    end
    
    methods (Static)
        % Returns true if the strategy supports the datatype
        function doesSupportData = supportsData(data)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            
            doesSupportData = iscell(data);  
            
        end
    end
    
    methods
        function viewFormattedValue = getFormattedData(obj, model, sourceRowIndices, sourceColIndices, sourceDataType)
            % GETFORMATTEDDATA - returns a cell array matching the row
            % range and column range of the uitable source data.

            colArray = obj.getValidColumnRange(model, sourceColIndices);
            viewFormattedValue = obj.formatData(model.Data(sourceRowIndices, colArray));
            
        end
    end
    
    methods(Static)
        function viewFormattedValue = formatData(data)
            % GETFORMATTEDDATA - returns a cell array matching the row
            % range and column range of the data.
            
            logicalStrategy = matlab.ui.internal.controller.uitable.viewservices.LogicalArrayTextFormatter;
            numericStrategy = matlab.ui.internal.controller.uitable.viewservices.NumericArrayTextFormatter;
            
            % Cellstr is implicitly handled by using viewData as default
            viewFormattedValue = data;
            emptyIndices = cellfun('isempty', viewFormattedValue);
            viewFormattedValue(emptyIndices) = {''}; 
            
            % Convert logical values
            logicalIndices = cellfun('islogical', viewFormattedValue);
            linearIndices = find(logicalIndices);
            viewFormattedValue(linearIndices) = logicalStrategy.formatData([viewFormattedValue{linearIndices}]);
                        
            % Convert numeric values which will be all non-converted values
            numericIndices = ~cellfun('isclass', viewFormattedValue, 'char');
            linearIndices = find(numericIndices);
            
            if isa([viewFormattedValue{linearIndices}], 'double')
                % Concatenating the numeric values will case to the lowest
                % common class. When the concatenated values are double,
                % that means every value is a double.
                viewFormattedValue(linearIndices) = numericStrategy.formatData([viewFormattedValue{linearIndices}]);
            else
                for index = 1:numel(linearIndices)
                    viewFormattedValue(linearIndices(index)) = numericStrategy.formatData([viewFormattedValue{linearIndices(index)}]);
                end             
            end
        end
    end
end

