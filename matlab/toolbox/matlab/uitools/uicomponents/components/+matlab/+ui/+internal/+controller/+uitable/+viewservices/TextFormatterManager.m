classdef TextFormatterManager < handle
    %TEXTFORMATTERMANAGER This is the manager related to text display.
    % It takes advantage of strategy modules to provide the view information
    % The datastore is requiring.
    
    properties
        Strategy;
    end
    
    methods
        
        function obj = TextFormatterManager(model)
            obj.Strategy = obj.getStrategy(model);
        end
                
        function outputArg = getFormattedData(obj, model, sourceRowIndices, sourceColIndices, sourceDataType)
            % GETFORMATTEDDATA - returns a cell array matching the row
            % range and column range of the table data, that is also
            % consistent with the requirements of the strategy.

            outputArg = obj.Strategy.getFormattedData(model, sourceRowIndices, sourceColIndices, sourceDataType);
        
        end    
       
        function handleDataChanged(obj, model)
            % HANDLEDATACHANGED - Updates strategy if the current strategy
            % does not have the same data support as required.
            
            if ~obj.Strategy.supportsData(model.Data)
                obj.Strategy = obj.getStrategy(model);
            end        
        end
        
        function handleColumnFormatChanged(obj, model)
            % HANDLECOLUMNFORMATCHANGED - Updates strategy if the current
            % strategy does not have the same level of column format
            % support as required.
            
            if obj.hasColumnFormat(model) ~= obj.Strategy.isColumnFormatDecorator()
                obj.Strategy = obj.getStrategy(model);
            end     
        end 
    end
    
    methods (Static, Access = private)
       
        function strategy = getStrategy(model)
            % GETSTRATEGY - Gets the strategy consistent with the content of
            % the data and column format.
            import matlab.ui.internal.controller.uitable.viewservices.*;
            strategy = TextFormatterManager.getTextFormatterStrategyByData(model.Data);
            
            if strategy.supportsColumnFormatDecorator() && TextFormatterManager.hasColumnFormat(model)
                % If there are any column format values, then decorate the
                % strategy with the column format decorator.
                
                strategy = ColumnFormatTextFormatDecorator(strategy);
            end        
        end
        
        function hasColumnFormat = hasColumnFormat(model)
            % HASCOLUMNFORMAT - Returns true if any of the column format
            % properties are not empty
            
            hasColumnFormat = any(~cellfun('isempty', model.ColumnFormat));
        end
        
        function strategy = getTextFormatterStrategyByData(data)
            % GETDATASTRATEGY - Returns strategy that supports the right
            % data.  
            
            import matlab.ui.internal.controller.uitable.viewservices.*;
            if TableArrayTextFormatter.supportsData(data)
                strategy = TableArrayTextFormatter;
            elseif NumericArrayTextFormatter.supportsData(data)
                strategy = NumericArrayTextFormatter;
            elseif StringArrayTextFormatter.supportsData(data)
                strategy = StringArrayTextFormatter;
            elseif CellstrArrayTextFormatter.supportsData(data)
                strategy = CellstrArrayTextFormatter;
            elseif CellArrayTextFormatter.supportsData(data)
                strategy = CellArrayTextFormatter;
            elseif LogicalArrayTextFormatter.supportsData(data)
                strategy = LogicalArrayTextFormatter;
            else
                error('Strategy for %s data type not implemented', class(data));
            end                  
        end
    end
end

