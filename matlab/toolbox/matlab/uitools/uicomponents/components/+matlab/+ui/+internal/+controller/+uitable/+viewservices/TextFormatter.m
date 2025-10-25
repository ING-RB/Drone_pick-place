classdef TextFormatter
    %TEXTFORMATTER This is the interface for services around getting
    %   appropriate text for the data.
    
    methods (Abstract)
        outputArg = getFormattedData( obj, model, sourceRowIndices, sourceColIndices, sourceDataType);
    end
    
    methods (Abstract, Static)
        % Returns true if the strategy supports the datatype
        supportsData(data)
    end
    
    methods (Static)
        function colArray = getValidColumnRange(model, sourceColIndices)  
            % GETVALIDCOLUMNRANGE - Return an array of columns based on the
            % size of the actual data and the startColumn, endColumn named.
            
            % Use width of data as maximum.
            % Assume that startColumn and endColumn will never be negative
            % to simplify the logic
            maxColumn = size(model.Data, 2);
            colArray = sourceColIndices(sourceColIndices <= maxColumn);
            
        end
        function doesSupportColumnFormat = isColumnFormatDecorator()
            % SUPPORTSCOLUMNFORMAT - By default column format is not
            % supported by most strategies. This means that this strategy
            % does not use ColumnFormat when deciding how to format.
            doesSupportColumnFormat = false;
        end
        
        function doesSupportColumnFormatDecorator = supportsColumnFormatDecorator()
            % SUPPORTSCOLUMNFORMATDECORATOR - This determins whether this
            % strategy can be decorated by the ColumnFormat decorator.
            doesSupportColumnFormatDecorator = true;
        end
    end
end

