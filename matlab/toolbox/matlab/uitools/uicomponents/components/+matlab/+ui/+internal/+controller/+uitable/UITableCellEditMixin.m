classdef UITableCellEditMixin < handle
    % UITABLECELLEDITMIXIN class is to handle cell editing from
    % UITable view. 

    
    properties (Access='private')
        Model;

        % Non-numeric editable data types
        EditableDataTypesInTable = {'logical', 'char', 'string', 'datetime', 'categorical'};
    end
    
    properties (Access='protected')
        IsEditing = false;
        EditingIndex = [];
    end
    
    % Abstract methods in order to use this mixin.
    methods (Abstract)
        fireCallbacksFromCellEdit(obj, index, displayIndex, editValue, oldValue, newValue, err, valueChanged);
    end
        
    
    methods
        
        function obj = UITableCellEditMixin (model)
            obj.Model = model;
        end
        
        % Handle text input from cell editing event.
        %
        % Text input examples:
        %   - number:           '123'
        %   - char/string:      'foo'
        %   - logical:          '1'/'0'
        %   - datetime:         '12/01/2018'
        %   - categorical:      'Male' 
        function handleCellEditFromClient(obj, displayRow, displayCol, editValue, varargin)     
            sourceRow = obj.getSourceRowFromDisplayRow(displayRow);
            sourceCol = obj.getSourceColumnFromDisplayColumn(displayCol);
            if isempty(varargin)
                columnIndex = 1;            % sub index for single-column variables.
            else
                columnIndex = varargin{1};  % sub index for multi-column variables.
            end

            % Do not allow edit if ColumnFormat is categorical (cell array)
            % for displayCol and editValue does not exist in the categories.
            % Table array data does not support ColumnFormat
            if ~istable(obj.Model.Data) ...
                && displayCol <= length(obj.Model.ColumnFormat) ...
                && iscell(obj.Model.ColumnFormat{displayCol}) ...
                && ~any(find(strcmp(obj.Model.ColumnFormat{displayCol}, editValue)))
                % Assert here so the RemoteDataStore knows that the
                % validation failed and can revert the value in the view
                assert(false,'Invalid edit value for protected categorical');
            end
            
            % Fire cell edit callback in c++ model.
            if istable(obj.Model.Data) || isstring(obj.Model.Data)
                % Table and string array data are validated in MATLAB.
                obj.handleCellEditOnTableAndStringData(displayRow, displayCol, editValue, columnIndex);
            else
                % Legacy data types are validated in C++: 
                % numeric array, logical array and cell array of numeric, logical and char
                
                if islogical(obj.Model.Data)
                    % C++ model expects editValue to be logical data type
                    % for logical array data
                    if strcmp(editValue, "1")
                        editValue = true;
                    elseif strcmp(editValue, "0")
                        editValue = false;
                    end
                    valueChanged = ~isequal(editValue, obj.Model.Data(sourceRow, sourceCol));
                elseif isnumeric(obj.Model.Data)
                    % C++ model expects editValue to be char data type for
                    % all other legacy data
                    valueChanged = ~isequal(str2double(editValue), obj.Model.Data(sourceRow, sourceCol));
                else
                    % Cell array data
                    if islogical(obj.Model.Data{sourceRow, sourceCol})
                        % Convert char to logical for C++ model
                        if strcmp(editValue, "1")
                        editValue = true;
                        elseif strcmp(editValue, "0")
                            editValue = false;
                        end
                        valueChanged = ~isequal(editValue, obj.Model.Data{sourceRow, sourceCol});
                    elseif isnumeric(obj.Model.Data{sourceRow, sourceCol})
                        valueChanged = ~isequal(str2double(editValue), obj.Model.Data{sourceRow, sourceCol});
                    else
                        valueChanged = ~isequal(editValue, obj.Model.Data{sourceRow, sourceCol});
                    end
                end
                
                % valueChanged determines whether we update the table data
                % and fire the CellEditCallback
                % It is true if we get a new valid cell input value, and
                % false if the valid input value is equal to the existing
                % value in the cell
                if valueChanged
                    % Since validation is in C++, oldValue, newValue, err
                    % will be passed in as empty []
                    obj.fireCallbacksFromCellEdit([sourceRow sourceCol], [displayRow displayCol], editValue, [], [], [], valueChanged);
                    % Refresh the view for the edited cell
                    obj.updateSingleCellData(sourceRow, sourceCol);
                end
            end
        end
        
        function handleCellEditOnTableAndStringData(obj, displayRow, displayCol, editValue, columnIndex)
            sourceRow = obj.getSourceRowFromDisplayRow(displayRow);
            sourceCol = obj.getSourceColumnFromDisplayColumn(displayCol);
            
            % Turn on editing flag to tell the controller to update the
            % view for the single edited cell only
            obj.IsEditing = true;
            
            % Store the index of the edited cell
            obj.EditingIndex = [sourceRow sourceCol];
            
            dataVal = obj.getValueAt(sourceRow, sourceCol, columnIndex);
            datatype = class(dataVal);

            % If not numeric and not a non-numeric editable data type
            if ~any(strcmp(datatype, obj.EditableDataTypesInTable)) && ...
               ~isnumeric(dataVal)
                % not valid for editing.
                % This path should never be hit, but if it is,
                % assert here so the RemoteDataStore knows that the
                % validation failed and can revert the value in the view
                assert(false,'Invalid data type for editing');
            end
            
            % validate input.
            [validatedValue, err] = obj.validateInput(editValue, dataVal, datatype, sourceRow, sourceCol, columnIndex);
            
            % Construct oldValue and newValue of cell editing callback.
            % For table data
            if istable(obj.Model.Data)
                if size(obj.Model.Data.(sourceCol), 2) > 1
                    % for cell editing in a multi-column variable. 
                    % newValue/oldValue is the tuple across all sub columns.                
                    oldValue = obj.getValueAt(sourceRow, sourceCol); 
                    newValue = oldValue;
                    newValue(columnIndex) = validatedValue;
                else
                    % for single-column variable.
                    oldValue = obj.getValueAt(sourceRow, sourceCol); 
                    newValue = validatedValue;
                end
            else
                % For string data
                % No multi-column variables, so consider single-column only
                oldValue = obj.getValueAt(sourceRow, sourceCol); 
                newValue = validatedValue;
            end

            % Store DisplayRowOrder to reset after Data is updated
            displayRowOrder = obj.Model.DisplayRowOrder;
            
            % set newValue to model data.
            newValue = obj.setValueAt(sourceRow, sourceCol, newValue);

            % Set DisplayRowOrder to stored value
            obj.Model.DisplayRowOrder = displayRowOrder;
            
            % Turn off editing flag and clear the index of the edited cell
            % This happens after editing the cell value and before firing
            % the CellEditCallback to open up the whole table view for view
            % data updates
            obj.IsEditing = false;
            obj.EditingIndex = [];
            
            valueChanged = ~isequal(oldValue, newValue);
            % Fire cell edit callback in c++ model.
            obj.fireCallbacksFromCellEdit([sourceRow sourceCol], [displayRow displayCol], editValue, oldValue, newValue, err, valueChanged);
        end
    end
    
    
    methods (Access='protected')
        % Utility methods to validate input text value.
        % Return validated value and error/warning msg if necessary.
        function [validatedValue, err] = validateInput(obj, inputText, dataVal, datatype, row, column, varargin)
            % default return.
            validatedValue = inputText;
            err = [];
            
            % get value from the given sub column.
            if nargin < 7
                columnIndex = 1;            % sub index for single-column variables.
            else
                columnIndex = varargin{1};  % sub index for multi-column variables.
            end
            
            % validate the input char value.
            if isnumeric(dataVal) || islogical(dataVal)
                % cast to the valid data type
                validatedValue = cast(str2double(inputText), datatype);
            else
                % non-numeric and non-logical datatypes
                switch datatype
                    case 'char'
                        validatedValue = char(inputText);
                    case 'string'
                        validatedValue = string(inputText);
                    case 'datetime'
                        [validatedValue, err] = obj.validateDatetime(inputText, row, column, columnIndex);
                    case 'categorical'
                        validatedValue = inputText;
                    otherwise
                        % no other data types are allowed to be edited.
                        % This path should never be hit, but if it is,
                        % assert here so the RemoteDataStore knows that the
                        % validation failed and can revert the value in the view
                        assert(false,'Invalid data type for editing');
                end
            end
        end
        
        % Utility method to get value(s) from model data.
        function value = getValueAt(obj, row, column, varargin)
            
            % Table data
            if istable(obj.Model.Data)
                if isempty(varargin)
                    % Get all values across sub columns if any.
                    % For table data, a cell value will always be a cellstr
                    if iscell(obj.Model.Data.(column))
                        value = obj.Model.Data.(column){row};
                    else
                        value = obj.Model.Data.(column)(row);
                    end 
                else
                    % Get value from the given sub column of multicolumn
                    % variable
                    columnIndex = varargin{:};
                    if iscell(obj.Model.Data.(column))
                        value = obj.Model.Data.(column){row, columnIndex};
                    else
                        value = obj.Model.Data.(column)(row, columnIndex);
                    end        
                end
            % Non-table data
            % No multicolumn variables allowed in non-table data, so use
            % row and column for indexing
            elseif iscell(obj.Model.Data)
                % For non-table data, cell arrays can only contain a mix of
                % numeric, logical, and char values.
                value = obj.Model.Data{row, column};
            else
                value = obj.Model.Data(row, column);
            end
        end
        
        % Utility method to set newValue back to model data.
        function retValue = setValueAt(obj, row, column, newValue, varargin)
            %%%%%%%%%%%%% g1714322 %%%%%%%%%%%%%
            % disable warning of 
            %   'MATLAB:uitable:NonEditableDataTypes' from ColumnEditable
            %   'MATLAB:uitable:ColumnFormatNotSupported' from ColumnFormat
            % as a short term solution for above warning triggered by cell
            % edit from view.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % disable warnings
            warning('off', 'MATLAB:uitable:ColumnFormatNotSupported');
            warning('off', 'MATLAB:uitable:NonEditableDataTypes');
            
            %Setting Model UpdateFromView property as true to enable
            %correct editing workflow (Synchronously)
            obj.Model.setCellEditedFromClient(true);
            
            % Table data
            if istable(obj.Model.Data)
                % For table data, a cell value will always be a cellstr
                if iscell(obj.Model.Data.(column))
                    if iscategorical(obj.Model.Data.(column){row})
                        % Need to index further into the categorical array
                        % in order to get correct categorical conversion
                        obj.Model.Data.(column){row}(1) = newValue;
                        % If the categorical array within the cell is
                        % larger than 1x1, delete the other values since
                        % editing always results in a 1x1 value
                        obj.Model.Data.(column){row}(2:end) = [];
                    else
                        obj.Model.Data.(column){row} = newValue;
                    end
                else
                    obj.Model.Data.(column)(row) = newValue;
                end  
            % Non-table data
            elseif iscell(obj.Model.Data)
                % For non-table data, cell arrays can only contain a mix of
                % numeric, logical, and char values.
                obj.Model.Data{row, column} = newValue;
            else
                obj.Model.Data(row, column) = newValue;
            end
            
            % restore warnings
            warning('on', 'MATLAB:uitable:ColumnFormatNotSupported');
            warning('on', 'MATLAB:uitable:NonEditableDataTypes');
            
            % get the new value as it appears after being set in the Model
            retValue = obj.getValueAt(row, column);
        end
        
        % Utility method to construct a new Datetime from the input text
        function [newValue, err] = validateDatetime(obj, editValue, row, column, columnIndex)
                   
            % get the current Datetime Format and TimeZone
            if iscell(obj.Model.Data.(column))
                format = obj.Model.Data.(column){row, columnIndex}.Format;
                timezone = obj.Model.Data.(column){row, columnIndex}.TimeZone;
            else
                format = obj.Model.Data.(column).Format;
                timezone = obj.Model.Data.(column).TimeZone;
            end
            
            err = [];

            % save and clear warning.
            [warn_msg, warn_id] = lastwarn;
            lastwarn('');
            
            % get the active locale from settings.
            s=settings;
            activeLocale = s.matlab.datetime.DisplayLocale.ActiveValue;
            
            try 
                % first, try with the current input format and active locale.
                % use evalc to set lastwarn but not display to command window.
                evalc('newValue = datetime(editValue, ''InputFormat'', format, ''Locale'', activeLocale, ''TimeZone'', timezone)');

            catch ME %#ok<NASGU>
                try 
                    % second, try with the current input format and factory 
                    % locale (used by datetime by default).
                    % use evalc to set lastwarn but not display to command window.
                    evalc('newValue = datetime(editValue, ''InputFormat'', format, ''TimeZone'', timezone)');
                    
                catch  ME %#ok<NASGU>
                    try
                        % third, try with the default format (without input
                        % format) and the active locale
                        % use evalc to set lastwarn but not display to command window.
                        evalc('newValue = datetime(editvalue, ''Locale'', activeLocale, ''TimeZone'', timezone)');
                        
                    catch ME %#ok<NASGU>
                        try 
                            % last, try the default format (without input format) and factory locale.
                            % use evalc to set lastwarn but not display to command window.
                            evalc('newValue = datetime(editValue, ''TimeZone'', timezone)');

                        catch e
                            newValue = NaT;
                            err = e;
                        end
                    end
                end
            end  
            
            % if no errors, try to capture any warnings.
            if isempty(err) && ~isempty(lastwarn)
                [warnMsg, warnID] = lastwarn;
                err.message = ['Warning: ' warnMsg];
                err.identifier = warnID;
            end
            
            % restore lastwarn.
            lastwarn(warn_msg, warn_id);
        end
    end
end