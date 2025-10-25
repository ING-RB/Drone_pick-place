classdef ColumnFormatTextFormatDecorator < matlab.ui.internal.controller.uitable.viewservices.TextFormatter
    %COLUMNFORMATTEXTFORMATDECORATOR This implements the TextFormatter
    %   interface in order to create text formatted considering the raw 
    %   uitable source data and the ColumnFormat property.
    
    properties (SetAccess = immutable)        
        ActiveFormatter;
        ActiveDataTypeStrategy;
        FormatterMap;
    end
    
    methods       
        function obj = ColumnFormatTextFormatDecorator(strategy)
            obj.ActiveDataTypeStrategy = strategy;
            obj.FormatterMap = obj.buildFormatterMaps();
            obj.ActiveFormatter = obj.getAllFormatterFunctions(strategy);           
        end
    end
    
    methods
        function doesSupportData = supportsData(obj, rawData)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            
            doesSupportData = obj.ActiveDataTypeStrategy.supportsData(rawData);
        end
    end
    
    methods (Static)
        function doesSupportColumnFormat = isColumnFormatDecorator()
            % SUPPORTSCOLUMNFORMAT - This strategy supports column format.
            doesSupportColumnFormat = true;
        end
        function doesSupportColumnFormatDecorator = supportsColumnFormatDecorator()
            % SUPPORTSCOLUMNFORMAT - By default column format is not
            % supported by most strategies.
            doesSupportColumnFormatDecorator = false;
        end
    end
    
    methods
        function viewFormattedValue = getFormattedData(obj, model, sourceRowIndices, sourceColIndices, sourceDataType)
            % GETFORMATTEDDATA - returns a cell array matching the row
            % range and column range of the uitable source data.
            
            defaultFormatter = @(model, sourceRowIndices, sourceColIndices, sourceDataType)obj.ActiveDataTypeStrategy.getFormattedData(model, sourceRowIndices, sourceColIndices, sourceDataType);            
            
            colArray = obj.getValidColumnRange(model, sourceColIndices);
            
            viewFormattedValue = cell.empty(numel(sourceRowIndices), 0);
            
            for sourceCol = colArray                
                
                % If specialized formatter has been setup, use it.
                if numel(model.ColumnFormat) >= sourceCol && ...
                        ischar(model.ColumnFormat{sourceCol}) && obj.ActiveFormatter.isKey(model.ColumnFormat{sourceCol})
                        
                        formatter = obj.ActiveFormatter(model.ColumnFormat{sourceCol});
                        viewFormattedValue(:, end + 1) = ...
                            formatter(model.Data, model.ColumnFormat{sourceCol}, sourceRowIndices, sourceCol);
                        
                % Delegate to strategy for formatting
                else
                    viewFormattedValue(:, end + 1) = ...
                       defaultFormatter(model, sourceRowIndices, sourceCol, sourceDataType);
                end
                    
            end
            
        end
    end
    
    methods(Access = 'private')
        
         function formatterMap = getAllFormatterFunctions(obj, strategy)
            % GETALLFORMATTERFUNCTIONS - This function returns the
            % appropriate formatters for the currently stored strategy
            
            formatterMapKey = obj.getFormatterMapKey(strategy);
            formatterMap = obj.FormatterMap(formatterMapKey);
        end
        
        function formatterMap = buildFormatterMaps(obj)
            % BUILDSTRATEGYFORMATTERMAP - This function returns the
            % per strategy map of all formatters.
            formatterMap = containers.Map();
            
            % String
            formatterKey = 'StringArrayTextFormatter';           
            stringFormatterKeyset = {'logical'};
            stringFormatterValueset = {@(rawData, columnFormat, sourceRowIndices, column)obj.formatStringAsLogical(rawData, columnFormat, sourceRowIndices, column)};
            formatterMap(formatterKey) = containers.Map(stringFormatterKeyset, stringFormatterValueset);
            
            % Cellstr
            formatterKey = 'CellstrArrayTextFormatter';
            cellstrFormatterKeyset = {'logical'};
            cellstrFormatterValueset = {@(rawData, columnFormat, sourceRowIndices, column)obj.formatCellstrAsLogical(rawData, columnFormat, sourceRowIndices, column)};
            formatterMap(formatterKey) = containers.Map(cellstrFormatterKeyset, cellstrFormatterValueset);
                     
            % Logical
            formatterKey = 'LogicalArrayTextFormatter';                
            numericFormatter = @(rawData, columnFormat, sourceRowIndices, column)obj.formatNumericWithColumnFormat(rawData, columnFormat, sourceRowIndices, column);
            charFormatter = @(rawData, columnFormat, sourceRowIndices, column)obj.formatNumericAsChar(rawData, columnFormat, sourceRowIndices, column);
                
            numericFormats = {'+', 'bank', 'hex', 'long', 'longE', 'longEng', 'longG',...
                'rat', 'short', 'shortE', 'shortEng', 'shortG'};
            numericFormatterKeyset = [{'char'}, numericFormats];
            numericFormatterValueset = [{charFormatter}, repmat({numericFormatter}, size(numericFormats))];

            formatterMap(formatterKey) = containers.Map(numericFormatterKeyset, numericFormatterValueset);
            
            % Numeric (builds on logical)
            formatterKey = 'NumericArrayTextFormatter';
            logicalFormatter = @(rawData, columnFormat, sourceRowIndices, column)obj.formatNumericAsLogical(rawData, columnFormat, sourceRowIndices, column);
            logicalFormatterKeyset = [numericFormatterKeyset, {'logical'}];
            logicalFormatterValueset = [numericFormatterValueset, {logicalFormatter}];
            formatterMap(formatterKey) = containers.Map(logicalFormatterKeyset, logicalFormatterValueset);
            
            % Cell
            formatterKey = 'CellArrayTextFormatter';
            cellFormatterKeyset = [stringFormatterKeyset, cellstrFormatterKeyset, numericFormatterKeyset, logicalFormatterKeyset];            
            cellFormatter = @(rawData, columnFormat, sourceRowIndices, column)obj.formatCellArray(formatterMap, rawData, columnFormat, sourceRowIndices, column);
            cellFormatterValueset = repmat({cellFormatter}, size(cellFormatterKeyset));
            formatterMap(formatterKey) = containers.Map(cellFormatterKeyset, cellFormatterValueset);
            
        end
    end
    
    methods (Static)
        function formattedValue = formatStringAsLogical(rawData, columnFormat, sourceRowIndices, column)
            % FORMATSTRINGASLOGICAL - Cell content is '1' for '1' or true,
            % else it is '0'.

            formattedValue = repmat({'0'}, [numel(sourceRowIndices), 1]);
            
            % Both "1" and "true" will be interpreted as true.
            formattedValue(rawData(sourceRowIndices, column) == "1") = {'1'};
            formattedValue(rawData(sourceRowIndices, column) == "true") = {'1'};
        end
        
        function formattedValue = formatCellstrAsLogical(rawData, columnFormat, sourceRowIndices, column)
            % FORMATCELLSTRASLOGICAL - Cell content is '1' for '1' or true,
            % else it is '0'.
            
            formattedValue = repmat({'0'}, [numel(sourceRowIndices), 1]);
            
            % Both "1" and "true" will be interpreted as true.
            formattedValue(string(rawData(sourceRowIndices, column)) == "1") = {'1'};
            formattedValue(string(rawData(sourceRowIndices, column)) == "true") = {'1'};
        end
        
        function formattedValue = formatNumericWithColumnFormat(rawData, columnFormat, sourceRowIndices, column)
            % FORMATNUMERICWITHCOLUMNFORMAT - Data and column format is 
            % supported by the numeric display utilities.

             formattedValue = ...
                 matlab.ui.internal.controller.uitable.utils.DataFormatUtils.formatNumericData(...
                 rawData(sourceRowIndices, column), columnFormat);
        end
        
        function formattedValue = formatNumericAsLogical(rawData, columnFormat, sourceRowIndices, column)
            % FORMATNUMERICASLOGICAL - Cast to logical and format as 'short'
        
            dataSubset = rawData(sourceRowIndices, column);
            missingRows = ismissing(dataSubset);

            % NaN needs to be replaced before casting.  This operation
            % will create a copy of the data.
            dataSubset(missingRows) = 0;

            logicalStrategy = matlab.ui.internal.controller.uitable.viewservices.LogicalArrayTextFormatter;
            formattedValue = ...
            logicalStrategy.formatData(dataSubset==1);

        end
        
        function formattedValue = formatNumericAsChar(rawData, columnFormat, sourceRowIndices, column)
            % FORMATNUMERICASCHAR - Return text version of data.  Logical
            % data is returned as 'true' or 'false'.
            
            nonMissingRows = ~ismissing(rawData(sourceRowIndices, column));
            formattedValue = cellstr(string(rawData(sourceRowIndices, column)));
            
            % Special case NaN because string missing is equivalent to ''
            formattedValue(~nonMissingRows, 1:numel(column)) = {'NaN'};
        end
        
        function formattedValue = formatCellArray(formatterMap, rawData, columnFormat, sourceRowIndices, column)
            % FORMATCellArray - Return text version of data.  
            
            % Initialize formattedValue
            formattedValue = rawData(sourceRowIndices, column);          
            isemptyIndices = cellfun('isempty', formattedValue);
            formattedValue(isemptyIndices) = {''}; 
            
            % Get datatype specific indices
            ischarIndices = cellfun('isclass', formattedValue, 'char');
            islogicalIndices = cellfun('islogical', formattedValue);
            isnumericIndices = ~(islogicalIndices | ischarIndices | isemptyIndices);
            
            formattedValue = formatMixedCell(formattedValue, 'CellstrArrayTextFormatter', ischarIndices, columnFormat);
            formattedValue = formatMixedCell(formattedValue, 'LogicalArrayTextFormatter', islogicalIndices, columnFormat);
            


            numericLinearIndices = find(isnumericIndices);
            numericdata = reshape([formattedValue{numericLinearIndices}], [], 1);
            if isa(numericdata, 'double')
                % Numeric arrays of all double are the most common
                % Collapsing the cell values into a double array means each
                % individual numeric value was of type double.
                formattedValue = formatMixedCell(formattedValue, 'NumericArrayTextFormatter', isnumericIndices, columnFormat);
            else
                % Numeric values could be of heterogenous types which will
                % cast down when combined.  Each individual value must be
                % calculated in isolation to avoid data corruption via casting.
                for idx = 1:numel(numericLinearIndices)
                    formattedValueIndex = numericLinearIndices(idx);
                    formattedValue(formattedValueIndex) = formatMixedCell(formattedValue(formattedValueIndex), 'NumericArrayTextFormatter', isnumericIndices(formattedValueIndex), columnFormat);
                end
            end
            
            function formattedValue = formatMixedCell(formattedValue, formatterName, indicesToFormat, columnFormat)
                % FORMATMIXEDCELL - This helper function formats a specific
                % set of indices.  The indices are expected to be a
                % homogeneous set that can all be formatted by the input
                % designated by formatterName
                % This function uses formatterMap  as defined in the
                % calling function.
                
                if any(indicesToFormat)
                    specializedFormatterMap = formatterMap(formatterName);
                    linearIndices = find(indicesToFormat);


                    if specializedFormatterMap.isKey(columnFormat)
                        specializedFormatterFunction = specializedFormatterMap(columnFormat);
                        
                        % Create cell array containing just the data to format
                        dataToFormat = formattedValue(linearIndices);
                        
                        % Reformat as regular array if not cellstr 
                        %     (numeric or logical)
                        if ~iscellstr(dataToFormat) 
                            dataToFormat = [dataToFormat{:}];
                        end
                        formattedValue(linearIndices) = specializedFormatterFunction(reshape(dataToFormat, [], 1), columnFormat, 1:numel(linearIndices), 1);
                    elseif formatterName == "LogicalArrayTextFormatter"
                        formattedValue(linearIndices) = matlab.ui.internal.controller.uitable.viewservices.LogicalArrayTextFormatter.formatData(reshape([formattedValue{linearIndices}], [], 1));
                    elseif formatterName == "NumericArrayTextFormatter"
                        formattedValue(linearIndices) = matlab.ui.internal.controller.uitable.viewservices.NumericArrayTextFormatter.formatData(reshape([formattedValue{linearIndices}], [], 1));
                    end
                end
            end          
        end
    end
    
    methods(Static, Access = private)
        
        function key = getFormatterMapKey(strategy)
            key = '';
            
            % String
            strategyNames = ["matlab.ui.internal.controller.uitable.viewservices.StringArrayTextFormatter", ...                       
            ...% Cellstr
            "matlab.ui.internal.controller.uitable.viewservices.CellstrArrayTextFormatter", ...                     
            ...% Logical
            "matlab.ui.internal.controller.uitable.viewservices.LogicalArrayTextFormatter", ...                           
            ...% Numeric (builds on logical)
            "matlab.ui.internal.controller.uitable.viewservices.NumericArrayTextFormatter", ...            
            ...% Cell
            "matlab.ui.internal.controller.uitable.viewservices.CellArrayTextFormatter",...            
            ...% Table
            "matlab.ui.internal.controller.uitable.viewservices.TableArrayTextFormatter"];
        
            for index = 1:numel(strategyNames)
                if isa(strategy, strategyNames(index))
                    key = replace(strategyNames(index), "matlab.ui.internal.controller.uitable.viewservices.", "");
                    break
                end
            end     
        end
    end
end

