classdef DefaultTabularMetaDataStore < internal.matlab.datatoolsservices.data.TabularMetaDataStore
    %DefaultTabularMetaDataStore

    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties
        CellModelProperties = [];
        TableModelProperties = [];
        ColumnModelProperties = [];
        RowModelProperties = [];
    end

    properties (Hidden, SetAccess=private)
        MaxModelRow = -inf;
        MaxModelColumn = -inf;
    end
    
    methods
        % Constructor
        function this = DefaultTabularMetaDataStore()
            this.TableModelProperties = struct;
            this.CellModelProperties = struct;
            this.ColumnModelProperties = struct;
            this.RowModelProperties = struct;
        end

        % getCellPropertyValue
        function value = getCellPropertyValue(this, row, col, property)
            value = this.getCellModelProperty(row, col, property);
            if isempty(value) || (iscell(value) && all(all(cellfun(@isempty,value))))
                value = this.getColumnModelProperty(col, property);
                if isempty(value) || (iscell(value) && all(all(cellfun(@isempty,value))))
                    value = this.getRowModelProperty(row, property);
                    if isempty(value) || (iscell(value) && all(all(cellfun(@isempty,value))))
                        value = this.getTableModelProperty(property);
                        if ~iscell(value)
                            value = {value};
                        end
                    end
                end
            end
        end

         % getCellModelProperties
        function varargout = getCellModelProperties(this, row, column, varargin)
            varargout{1} = this.getModelProperties('Cell', row, column, varargin{:});
        end

        % getCellModelProperty
        function varargout = getCellModelProperty(this, row, column, name)
            varargout{1} = this.getCellModelProperties(row, column, name);
        end
        
        % getTableModelProperties
        function varargout = getTableModelProperties(this, varargin)
            varargout{1} = this.getModelProperties('Table', 1, 1, varargin{:});
        end
        
        % getTableModelProperty
        function varargout = getTableModelProperty(this, name)
            % special case: single TableModelProperties value is taken out of cell
            varargout = this.getTableModelProperties(name);
        end

        % getColumnModelProperties
        function varargout = getColumnModelProperties(this, column, varargin)
            varargout{1} = this.getModelProperties('Column', 1, column, varargin{:});
        end

        % getColumnModelProperty
        function varargout = getColumnModelProperty(this, column, name)
            varargout{1} = this.getColumnModelProperties(column, name);
        end

        % resetColumnModelProperty
        function [valueUpdated, oldValue] = resetColumnModelProperty(this, column, name)
            modelProp = this.getColumnModelProperties(column, name);
            valueUpdated = [];
            oldValue = modelProp;
            if ~isempty(modelProp{1})
                [valueUpdated, oldValue] = this.setColumnModelProperty(column, name, '', false);
            end
        end

        function resetAllColumnModelProperties(this, column)
            for c = 1:length(column)
                refKey = "c_" + column(c);
                if isfield(this.ColumnModelProperties, refKey)
                    this.ColumnModelProperties = rmfield(this.ColumnModelProperties, refKey);
                end
            end
        end

        function hasProp = hasColumnModelProperty(this, column, name)
            refKey = "c_" + column;
            hasProp = false;
            if isfield(this.ColumnModelProperties, refKey)
                modelProp = this.ColumnModelProperties.(refKey);
                hasProp = isfield(modelProp, name);
            end
        end

        function hasProp = hasRowModelProperty(this, row, name)
            refKey = "r_" + row;
            hasProp = false;
            if isfield(this.RowModelProperties, refKey)
                modelProp = this.RowModelProperties.(refKey);
                hasProp = isfield(modelProp, name);
            end
        end
        
        function hasProp = hasCellModelProperty(this, row, column, name)
            refKey = "r_" + row + "_c_" + column;
            hasProp = false;
            if isfield(this.CellModelProperties, refKey)
                modelProp = this.CellModelProperties.(refKey);
                hasProp = isfield(modelProp, name);
            end
        end
        
        function hasProp = hasTableModelProperty(this, name)
            hasProp =  isfield(this.TableModelProperties, name);
        end
        
        function resetAllTableModelProperties(this)
            this.TableModelProperties = struct;
        end

        % getRowModelProperties
        function varargout = getRowModelProperties(this, row, varargin)
            varargout{1} = this.getModelProperties('Row', row, 1, varargin{:});
        end

        % getRowModelProperty
        function varargout = getRowModelProperty(this, row, name)
            varargout{1} = this.getRowModelProperties(row, name);
        end

        % setTableModelProperty
        function [valueUpdated, oldValue] = setTableModelProperty(this, key, value, varargin)
            [valueUpdated, oldValue] = this.setModelProperty('Table', 1, 1, key, value, varargin{:});
        end

        % setTableModelProperties
        function setTableModelProperties(this, varargin)
            this.setModelProperties('Table', 1, 1, varargin{:});
        end
        
         % setColumnModelProperty
        function [valueUpdated, oldValue]= setColumnModelProperty(this, column, key, value, varargin)
            [valueUpdated, oldValue] = this.setModelProperty('Column', 1, column, key, value, varargin{:});
        end

        % setColumnModelProperties
        function setColumnModelProperties(this, column, varargin)
            this.setModelProperties('Column', 1, column, varargin{:});
        end

        % setRowModelProperty
        function [valueUpdated, oldValue] = setRowModelProperty(this, row, key, value, varargin)
            [valueUpdated, oldValue] = this.setModelProperty('Row', row, 1, key, value, varargin{:});
        end

        % setRowModelProperties
        function setRowModelProperties(this, row, varargin)
            this.setModelProperties('Row', row, 1, varargin{:});
        end
        
        % setCellModelProperty
        function [valueUpdated, oldValue] = setCellModelProperty(this, row, column, key, value, varargin)
            [valueUpdated, oldValue] = this.setModelProperty('Cell', row, column, key, value, varargin{:});
        end
        
        % setCellModelProperties
        function setCellModelProperties(this, row, column, varargin)
            this.setModelProperties('Cell', row, column, varargin{:});
        end
        
        % getTabularTableMetaData
        function tableProperties = getTabularTableMetaData(this)
            % Default implementation using model properties
            tableProperties = this.TableModelProperties;
        end
        
        % getTabularColumnMetaData
        function columnProperties = getTabularColumnMetaData(this, column)
            % Default implementation using model properties
            refKey = "c_" + column;
            if isfield(this.ColumnModelProperties, refKey)
                columnProperties = this.ColumnModelProperties.(refKey);
            else
                columnProperties = struct();
            end
        end
        
        % getTabularRowMetaData
        function rowProperties = getTabularRowMetaData(this, row)
            % Default implementation using model properties
            refKey = "r_" + row;
            if isfield(this.RowModelProperties, refKey)
                rowProperties = this.RowModelProperties.(refKey);
            else
                rowProperties = struct();
            end
        end

        function cleanupStaleRowModelProperties(this, maxRow)
            if (maxRow < this.MaxModelRow)
                this.resetAllRowModelProperties(maxRow+1:this.MaxModelRow);
                this.MaxModelRow = maxRow;
            end
        end

        function cleanupStaleColunModelProperties(this, maxColumn)
            if (maxColumn < this.MaxModelColumn)
                this.resetAllColumnModelProperties(maxColumn+1:this.MaxModelColumn);
                this.MaxModelColumn = maxColumn;
            end
        end

        function cleanupStaleCellModelProperties(this, maxRow, maxColumn)
            if (maxRow < this.MaxModelRow) || (maxColumn < this.MaxModelColumn)
                this.resetAllCellModelProperties(maxRow+1:this.MaxModelRow, maxColumn+1:this.MaxModelColumn);
            end
        end

        function resetAllRowModelProperties(this, row)
            for r = 1:length(row)
                refKey = "r_" + row(r);
                if isfield(this.RowModelProperties, refKey)
                    this.RowModelProperties = rmfield(this.RowModelProperties, refKey);
                end
            end
        end

        % getTabularCellMetaData
        function cellProperties = getTabularCellMetaData(this, row, column)
            % Default implementation using model properties
            refKey = "r_" + row + "_c_" + column;
            if isfield(this.CellModelProperties, refKey)
                cellProperties = this.CellModelProperties.(refKey);
            else
                cellProperties = struct();
            end
        end

        function resetAllCellModelProperties(this, row, column)
            for r = 1:length(row)
                for c = 1:length(column)
                    refKey = "r_" + row(r) + "_c_" + column(c);
                    if isfield(this.CellModelProperties, refKey)
                        this.CellModelProperties = rmfield(this.CellModelProperties, refKey);
                    end
                end
            end
        end
    end
    
    methods (Access='protected')
        % getModelProperties
        function varargout = getModelProperties(this, modelType, rows, columns, varargin)
            if isempty(rows) || isempty(columns)
                varargout{1} = [];
                return;
            end
            
            map = cell(length(rows), length(columns));
            propRef = struct;
            for r = 1:length(rows)
                row = rows(r);
                for c = 1:length(columns)
                    column = columns(c);
                    switch modelType
                        case 'Table'
                            propRef = this.TableModelProperties;
                        case 'Column'
                            refKey = "c_" + column;
                            if isfield(this.ColumnModelProperties, refKey)
                                propRef = this.ColumnModelProperties.(refKey);
                            end
                        case 'Row'
                            refKey = "r_" + row;
                            if isfield(this.RowModelProperties, refKey)
                                propRef = this.RowModelProperties.(refKey);
                            end
                        case 'Cell'
                            refKey = "r_" + row + "_c_" + column;
                            if isfield(this.CellModelProperties, refKey)
                                propRef = this.CellModelProperties.(refKey);
                            end
                    end
                    map{r, c} = propRef;
                end
            end
            
            if isempty(row) || isempty(column)
                vals = [];
            else
                vals = cell(size(map,1),size(map,2),length(varargin));
                for i=1:length(varargin)
                    key = varargin{i};
                    for r = 1:size(map,1)
                        for c = 1:size(map,2)
                            m = map{r,c};
                            if ~isempty(m) && isfield(m, key)
                                vals{r,c,i} = m.(key);
                            else
                                vals{r,c,i} = '';
                            end
                        end
                    end
                end
            end
            
            % special case: for CellModelProperties, if all empty return []
            if isempty(vals) || (strcmp(modelType, 'Cell') && all(all(all(cellfun('isempty',vals)))))
                varargout{1} = [];
            elseif isstruct(propRef) && ndims(vals) < 3
                % permute KxMxN into correct dims for prop MxN and keys K:
                % struct: 1xK
                varargout{1} = vals';
            else
                % 1xN cell: KxN
                % MxN cell: KxMxN
                varargout{1} = squeeze(vals);
            end
        end

        function [valueUpdated, oldValue] = setModelProperty(this, modelType, rows, columns, key, value, fireUpdate)
            arguments
                this
                modelType
                rows
                columns
                key
                value
                fireUpdate (1,1) logical = true
            end

            multipleSets = false;
            valueUpdated = false;
            oldValue = [];
            
            if length(rows) > 1 || length(columns) > 1
                oldValue = cell(length(rows) * length(columns),1);
                multipleSets = true;
            elseif isempty(rows) || isempty(columns)
                return;
            end

            oldValIndex = 1;
            for r = 1:length(rows)
                row = rows(r);
                for c = 1:length(columns)
                    column = columns(c);
                    propRef = struct;
                    switch modelType
                        case 'Table'
                            propRef = this.TableModelProperties;
                        case 'Column'
                            refKey = "c_" + column;
                            if isfield(this.ColumnModelProperties, refKey)
                                propRef = this.ColumnModelProperties.(refKey);
                            end
                        case 'Row'
                            refKey = "r_" + row;
                            if isfield(this.RowModelProperties, refKey)
                                propRef = this.RowModelProperties.(refKey);
                            end
                        case 'Cell'
                            refKey = "r_" + row + "_c_" + column;
                            if isfield(this.CellModelProperties, refKey)
                                propRef = this.CellModelProperties.(refKey);
                            end
                    end
        
                    ov = [];
                    if isfield(propRef, key)
                        ov = propRef.(key);
                    end

                    if multipleSets
                        oldValue{oldValIndex} = ov;
                        oldValIndex = oldValIndex + 1; 
                    else
                        oldValue = ov;
                    end

                    valueUpdated = ~isequaln(ov, value);
                    if valueUpdated
                        propRef.(key) = value;

                        switch modelType
                            case 'Table'
                                this.TableModelProperties = propRef;
                            case 'Column'
                                refKey = "c_" + column;
                                this.ColumnModelProperties.(refKey) = propRef;
                            case 'Row'
                                refKey = "r_" + row;
                                this.RowModelProperties.(refKey) = propRef;
                            case 'Cell'
                                refKey = "r_" + row + "_c_" + column;
                                this.CellModelProperties.(refKey) = propRef;
                        end

                        this.MaxModelRow = max(this.MaxModelRow, row);
                        this.MaxModelColumn = max(this.MaxModelColumn, column);
                    end
                end
            end

            % Notify listeners of change
            if (fireUpdate)
                eventData = internal.matlab.variableeditor.ModelChangeEventData;
                eventData.Key = key;
                eventData.OldValue = oldValue;
                eventData.NewValue = value;
                switch modelType
                    case 'Cell'
                        eventData.Row = rows;
                        eventData.Column = columns;
                    case 'Row'
                        eventData.Row = rows;
                    case 'Column'
                        eventData.Column = columns;
                end
                this.notify([convertStringsToChars(modelType) 'MetaDataChanged'], eventData);
            end            
        end
        
        % setModelPropertyDifferentValues
        function [valueUpdated, oldValue] = setModelPropertyDifferentValues(this, modelType, row, column, key, value, fireUpdate)
            % newValue is MxN cell, M=length(dim1) N=length(dim2)
            % loop through to set different newValue values across ModelProps(dim1, dim2) for key
            % need to fill MxN oldValue for change event
            oldValue = cell(size(value));
            valueUpdated = false;
            for r_i = 1:length(row)
                for c_i = 1:length(column)
                    [innerUpdated, innerOldValue] = this.setModelProperty(modelType, row(r_i), column(c_i), key, value{r_i, c_i}, fireUpdate);
                    valueUpdated = innerUpdated || valueUpdated;
                    % Old value should be a scalar cell array
                    if ~iscell(innerOldValue) || ~isscalar(innerOldValue)
                        innerOldValue = {innerOldValue};
                    end
                    oldValue(r_i, c_i) = innerOldValue;
                end
            end
        end
        
        % setModelProperties - for indices MxN, M=length(dim1) N=length(dim2):
        % set same value across indices per property: varargin PV-pairs
        % set different values across indices per property: varargin {props, vals}
        %     props {p1, p2, ... pK}
        %     vals  {{MxN}1, {MxN}2, ... {MxN}K}
        function setModelProperties(this, modelType, rows, columns, varargin)
            if ~isempty(varargin) && iscell(varargin{1})
                % first varargin is a cell, so set different values across indices per property
                if ~(length(varargin) == 2 ...
                     && iscell(varargin{1}) && iscell(varargin{2}) ...
                     && length(varargin{1}) == length(varargin{2}) ...
                     && all(cellfun(@(x) iscell(x) && isequal(size(x), [length(rows) length(columns)]), varargin{2})))
                    % varargin must consist of props and vals, cell arrays of equal length
                    % props must consist of MxN cell arrays
                    error(message('MATLAB:codetools:variableeditor:PropertyValuePairsExpected'));
                end
                allKeys = varargin{1};
                newValues = varargin{2};
                setModelPropertyFunc = @this.setModelPropertyDifferentValues;
            elseif ~isempty(varargin) && isstruct(varargin{1})
                allKeys = fields(varargin{1});
                newValues = struct2cell(varargin{1});
                setModelPropertyFunc = @this.setModelProperty;                
            else
                % PV-pairs, so set same value across indices per property
                if mod(length(varargin), 2) ~= 0
                    error(message('MATLAB:codetools:variableeditor:PropertyValuePairsExpected'));
                end
                allKeys = varargin(1:2:end);
                newValues = varargin(2:2:end);
                setModelPropertyFunc = @this.setModelProperty;
            end

            % set each property with fireUpdate=false, then fire one 
            % cumulative change event at the end if any values were updated
            valueUpdated = false;
            updatedKeys = cell(size(allKeys));
            oldValues = cell(size(newValues));
            for i=1:length(allKeys)
                key = allKeys{i};
                [updated, oldValue] = setModelPropertyFunc(modelType, rows, columns, key, newValues{i}, false);
                if (updated)
                    % keep track of updated keys for change event
                    updatedKeys{i} = key;
                    oldValues{i} = oldValue;
                end
                valueUpdated = updated || valueUpdated;
            end

            % Notify listeners of change
            if valueUpdated
                eventData = internal.matlab.variableeditor.ModelChangeEventData;
                if strcmp(modelType, 'Table')
                    % special case for TableModelProperties
                    eventData.Key = '';
                    eventData.OldValue = '';
                    eventData.NewValue = '';
                else
                    % Use keys to find the non-empty because oldValue or
                    % newValue could be empty
                    nonEmpty = ~cellfun('isempty',updatedKeys);
                    eventData.Key = updatedKeys(nonEmpty);
                    eventData.OldValue = oldValues(nonEmpty);
                    eventData.NewValue = newValues(nonEmpty);
                    switch modelType
                        case 'Cell'
                            eventData.Row = rows;
                            eventData.Column = columns;
                        case {'Row', 'Column'}
                            eventData.(modelType) = columns;
                    end
                end
                this.notify([convertStringsToChars(modelType) 'MetaDataChanged'], eventData);
            end
        end
    end
end

