classdef TableArrayTextFormatter < matlab.ui.internal.controller.uitable.viewservices.TextFormatter
    %TABLEARRAYTEXTFORMATTER This implements the TextFormatter interface.
    
    properties
        Formatter;
        SupportedFormats;
    end
        
    methods
        
        function obj = TableArrayTextFormatter()
            
            obj.Formatter = obj.getAllFormatterFunctions();
            obj.SupportedFormats = string(fields(obj.Formatter));
        end
    end
    
    methods (Static)
        % Returns true if the strategy supports the datatype
        function doesSupportData = supportsData(data)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            
            doesSupportData = istable(data);
            
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
            % range and column range of the table data.  Multicolumn
            % variables are represented by nested cell arrays.
            
            data = model.Data;
            viewFormattedValue = [];
            variableNames = data.Properties.VariableNames;
            colArray = obj.getValidColumnRange(model, sourceColIndices);
            
            for index = colArray
                
                name = variableNames{index};
                datatype = sourceDataType{index};
                
                sz = size(data.(name));
                
                if numel(sz) > 2 || any(sz == 0)
                    % 3d arrays and empty arrays require a contained
                    % display.  They are not editable in the view.  They
                    % should look similar to how table arrays display on
                    % the commandline.
                    rawData = data.(name)(sourceRowIndices, :);
                    variableData = reshape(rawData, [numel(sourceRowIndices), sz(2:end)]);
                    formattedVariableData = obj.getColumnArrayContainedDisplay(variableData);
                else
                    variableData = data.(name)(sourceRowIndices, :);
                
                    if strcmp(datatype, 'char')
                        % multidimensional char arrays are special cased
                        % each row should be a separate entry in the table rows.
                        % This only happens at the first level.  Multidimensional
                        % char arrays within cells are not expanded.
                        formattedVariableData = cellstr(variableData);
                    elseif strcmp(datatype, 'cell')
                        formattedVariableData = obj.formatCellVariable(variableData);
                    else
                        formattedVariableData = obj.formatArrayWithSpecifiedFormat(variableData, datatype);
                    end               
                end
                % MultiColumnVariables have special expectations
                formattedVariableData = obj.getMultiColumnVariableFormat(formattedVariableData);
                
                viewFormattedValue= [viewFormattedValue, formattedVariableData];
                
            end
        end
        
        function formattedData = formatArrayWithSpecifiedFormat(obj, value, format)
            % FORMATARRAYWITHSPECIFIEDFORMAT - return formatted data of the
            % same size as the inputted data.
            %
            % formattedData - a cellstr of the same size as value
           
            % Straight forward homogeneus array or cell array
            if any(strcmp(obj.SupportedFormats, format))
                formatterFunction = obj.Formatter.(format);
                
                % Get Formatted data.  This is a string array.
                formattedData = formatterFunction(value);

            else
                
                % Array is nested in a cell and should  be returned in
                % the simple format mxn classname
                formattedData = matlab.ui.internal.controller.uitable.viewservices.TableArrayTextFormatter.getArrayContainedDisplay(value);
            end
            
            % Reshape data so that it is a cell str or cell with
            % nested cellstr            
            if isstring(formattedData)
                % Converting arrays of strings should be the most
                % common case
                formattedData = cellstr(formattedData);
            end            
        end
    end
    
    methods(Access = 'private')
        
        function formatterFunction = getAllFormatterFunctions(obj)
            % GETALLFORMATTERFUNCTIONS - This function returns function
            % handles for the first class data types
            %
            % Numeric: "double", "single", "int8", "int16", "int32",...
            %   "int64", "uint8", "uint16", "uint32", "uint64", "logical" ...
            % String: "string", "categorical", "datetime", "duration"
            % Specialized: "cell", "cellstr"
            
            numericFormatter = @(value)matlab.ui.internal.controller.uitable.utils.DataFormatUtils.formatNumericData(value, 'short');
            
            stringifyableFormatter = @(value)obj.formatStringifyableArray(value);
            
            cellstrFormatter = @(value)matlab.ui.internal.controller.uitable.viewservices.TableArrayTextFormatter.formatCellstrArray(value);
            
            cellFormatter = @(value)matlab.ui.internal.controller.uitable.viewservices.TableArrayTextFormatter.getScalarContainedDisplay(value);
            
            formatterFunction = struct(...
                "double", numericFormatter,...
                "single", numericFormatter,...
                "int8", numericFormatter,...
                "int16", numericFormatter,...
                "int32",numericFormatter,...
                "int64", numericFormatter,...
                "uint8", numericFormatter,...
                "uint16", numericFormatter,...
                "uint32", numericFormatter,...
                "uint64", numericFormatter,...
                "logical", numericFormatter,...
                "cellstr", cellstrFormatter,...
                "string", stringifyableFormatter,...
                "categorical", stringifyableFormatter,...
                "datetime", stringifyableFormatter,...
                "duration", stringifyableFormatter,...
                "calendarDuration", stringifyableFormatter,...
                "cell", cellFormatter...
                );
        end
        
        
        function formattedValue = formatCellVariable(obj, value)
            % Formatted Value - Will return column vector cell array doing
            % a best bet of the cell array contents.  for scalar data in
            % cells, it will be formatted as is, for nested cell arrays the
            % display will be less specific (i.e. 1x4 timeseries)
             
            % loop through contents
            formattedValue = cell(size(value));
            for row = 1:size(value, 1)
                for col = 1:size(value, 2)
                    cellContents = value{row, col};
                    sz = size(cellContents);
                    if isrow(cellContents) && ischar(cellContents)
                        formattedValue(row, col) = cellstr(cellContents);
                    elseif isnumeric(cellContents) && any(sz==0)
                        formattedValue(row, col) = {''};
                    elseif ismissing(cellContents)
                        % Get representation of missing as it shows on the
                        % commandline
                        % <missing>, <undefined>, NaT, NaN
                        formattedValue(row, col) = {strtrim(evalc('disp(cellContents)'))};
                    elseif isscalar(cellContents)
                        % Straight forward homogeneus array or cell array
                        format = class(cellContents);
                        formattedValue(row, col) = obj.formatArrayWithSpecifiedFormat(cellContents, format);
                    else
                        formattedValue(row, col) = matlab.ui.internal.controller.uitable.viewservices.TableArrayTextFormatter.getScalarContainedDisplay(cellContents);
                    end
                end
            end
        end
    end
    
    methods(Static, Access = 'private')
        
        function formattedValue = getMultiColumnVariableFormat(value)
            % Handle the special case of multicolumn variables.  If
            % that is the case, the variable data will be mxn. Each
            % row needs to be wrapped in a cell array to be
            % understood by the framework.
                
            if iscolumn(value)
                % FormattedColumn is column vector and cell, take as is.
                formattedValue = value;
            else
                    
                % Manually create a column cell array out of the
                % contents of the formatter
                formattedValue = cell([size(value, 1), 1]);
                for row = 1:size(value, 1)
                    formattedValue{row} = value(row, :);
                end
            end
            
        end
        
        function formattedValue = getArrayContainedDisplay(value)
            % GETARRAYCONTAINEDDISPLAY - This is the most generic formatting
            % for objects or arrays which will not display in the view
            %
            % the output is a m x n array of {'1x1 classname'}
            % It is assumed that the value is 2d|column for this function.
               
            import internal.matlab.legacyvariableeditor.peer.PeerDataUtils;
            
            formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
            
            [numRow, numCol] = size(value);
            formattedValue = repmat({['1' PeerDataUtils.TIMES_SYMBOL '1 ' formatDataUtils.getClassString(value, true)]}, numRow,numCol);
           
        end
        
        function formattedValue = getColumnArrayContainedDisplay(value)
            % GETCOLUMNARRAYCONTAINEDDISPLAY - This is the most generic formatting
            % for objects or arrays which will not display in the view
            %
            % the output is a m x 1 array of {'1x1 classname'}
            % for 3d arrays, the output reflects dimensions for
            % [sz1,sz2,sz3] = size(A) you would get {'1xsz2xsz3 classname'}
               
            import internal.matlab.legacyvariableeditor.peer.PeerDataUtils;
            
            formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
            
            sz = size(value); 
            numRow = sz(1);
            
            repeatedDimensions = sprintf([PeerDataUtils.TIMES_SYMBOL,'%d'], sz(2:end));
            formattedSingleValue = {sprintf('1%s %s', repeatedDimensions, formatDataUtils.getClassString(value, true))};         
            
            formattedValue = repmat(formattedSingleValue, numRow, 1);
        end
        
        function formattedValue = getScalarContainedDisplay(value)
            % GETSCALARCONTAINEDDISPLAY - This is the most generic formatting
            % for objects or arrays which will not display in the view
            %
            % the output is {'m x n classname'}

            import internal.matlab.legacyvariableeditor.peer.PeerDataUtils;
            
            formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
            
            sz = size(value);
            
            displayStart = sprintf(['%d',PeerDataUtils.TIMES_SYMBOL], sz(1:end-1));
            formattedValue = {sprintf('%s%d %s', displayStart, sz(end), formatDataUtils.getClassString(value, true))};
        end
        
        function formattedValue = formatStringifyableArray(value)
            % FORMATSTRINGIFYABLEARRAY - This formats any datatype that can
            % rely on a simple string casting (datetime, categorical etc.)
            % Any missing values must be converted to their display
            % versions.
            
            formattedValue = string(value);
            if any(ismissing(value))
                % Get representation of missing as it shows on the
                % commandline
                % <missing>, <undefined>, NaT, NaN
                missingPlaceholder = string(strtrim(evalc(['disp(', class(value), '(missing))'])));
                
                % Replace missing with string version
                formattedValue(ismissing(value)) = missingPlaceholder;
                
            end
            
        end
        
        function formattedValue = formatCellstrArray(value)
            % FORMATCELLSTRARRAY - This is the most generic formatting for
            % objects or arrays which will not display in the view
            
            try
                % Try stringing the cellstr for performance reasons.
                % String will error if the char contents are not a row
                formattedValue = string(value);
            catch ME %#ok<NASGU>
                                
                % loop through contents
                formattedValue = cell(size(value));
                for row = 1:size(value, 1)
                    for col = 1:size(value, 2)
                        cellContents = value{row, col};
                    
                        if isrow(cellContents)
                            formattedValue(row, col) = {cellContents};
                        else
                            formattedValue(row, col) = matlab.ui.internal.controller.uitable.viewservices.TableArrayTextFormatter.getScalarContainedDisplay(cellContents);
                        end
                    end
                end
            end
        end        
    end
end

