classdef ArrayViewModel < internal.matlab.legacyvariableeditor.ViewModel & internal.matlab.legacyvariableeditor.BlockSelectionModel & internal.matlab.datatoolsservices.FormatDataUtils
    %ARRAYVIEWMODEL
    %   Abstract Array View Model

    % Copyright 2013-2014 The MathWorks, Inc.

    properties
        CellModelProperties = [];
        TableModelProperties = [];
        ColumnModelProperties = [];
        RowModelProperties = [];
    end
    
    events
        CellModelChanged;
        TableModelChanged;
        ColumnModelChanged;
        RowModelChanged;
    end

    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = ArrayViewModel(dataModel, viewID)
            this@internal.matlab.legacyvariableeditor.ViewModel(dataModel);
            if nargin >= 2
                this.viewID = viewID;
            end
            this.TableModelProperties = struct();
        end
        
        % isSelectable
        function selectable = isSelectable(~)
            selectable = true;
        end
        
        % isEditable
        function editable = isEditable(varargin)
            editable = true;
        end

        % getData
        function varargout = getData(this,varargin)
            varargout{1} = this.DataModel.getData(varargin{:});
        end

        % setData
        function varargout = setData(this,varargin)
            varargout{1} = this.DataModel.setData(varargin{:});
        end

        % getSize
        function s = getSize(this)
            s=this.DataModel.getSize();
        end

        % updateData
        function data = updateData(this, varargin)
            data = this.DataModel.updateData(varargin{:});
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
        
        % getRowModelProperties
        function varargout = getRowModelProperties(this, row, varargin)
            varargout{1} = this.getModelProperties('Row', 1, row, varargin{:});
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
            if ~isempty(column)
                [valueUpdated, oldValue] = this.setModelProperty('Column', 1, column, key, value, varargin{:});
            end
        end

        % setColumnModelProperties
        function setColumnModelProperties(this, column, varargin)
            if ~isempty(column)
                this.setModelProperties('Column', 1, column, varargin{:});
            end
        end

        % setRowModelProperty
        function [valueUpdated, oldValue] = setRowModelProperty(this, row, key, value, varargin)
            if ~isempty(row)
                [valueUpdated, oldValue] = this.setModelProperty('Row', 1, row, key, value, varargin{:});
            end
        end

        % setRowModelProperties
        function setRowModelProperties(this, row, varargin)
            if ~isempty(row)
                this.setModelProperties('Row', 1, row, varargin{:});
            end
        end
        
        % setCellModelProperty
        function [valueUpdated, oldValue] = setCellModelProperty(this, row, column, key, value, varargin)
            if ~isempty(row) && ~isempty(column)
                [valueUpdated, oldValue] = this.setModelProperty('Cell', row, column, key, value, varargin{:});
            end
        end
        
        % setCellModelProperties
        function setCellModelProperties(this, row, column, varargin)
            if ~isempty(row) && ~isempty(column)
                this.setModelProperties('Cell', row, column, varargin{:});
            end
        end
        
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            data = this.getData(startRow,endRow,startColumn,endColumn);

            vals = cell(size(data,2),1);
            for column=1:size(data,2)
                r=evalc('disp(data(:,column))');
                if ~isempty(r)
                    textformat = ['%s', '%*[\n]'];
                    vals{column}=strtrim(textscan(r,textformat,'Delimiter',''));
                end
            end
            renderedData=[vals{:}];

            if ~isempty(renderedData)
                renderedData=[renderedData{:}];
            end

            renderedDims = size(renderedData);
        end
    end
    
    methods (Access='protected')
        % getModelProperties
        function varargout = getModelProperties(this, modelType, dim1, dim2, varargin)
            prop = [convertStringsToChars(modelType) 'ModelProperties'];
            propRef = this.(prop);
            if isstruct(propRef)
                map = {propRef};
            else
                % Grow the properties array if necessary
                % use max([dim 1]) in case dim index is empty
                if size(propRef, 1) < max([dim1 1]) || ...
                    size(propRef, 2) < max([dim2 1])
                    this.(prop){max([dim1 1]), max([dim2 1])} = struct();
                    map = this.(prop)(dim1, dim2);
                else
                    map = propRef(dim1, dim2);
                end
            end

            if isempty(dim1) || isempty(dim2)
                vals = [];
            else
                vals = cell(length(varargin),size(map,1),size(map,2));
                for i=1:length(varargin)
                    key = varargin{i};
                    for r = 1:size(map,1)
                        for c = 1:size(map,2)
                            m = map{r,c};
                            if ~isempty(m) && isfield(m, key)
                                vals{i,r,c} = m.(key);
                            else
                                vals{i,r,c} = '';
                            end
                        end
                    end
                end
            end
            
            % special case: for CellModelProperties, if all empty return []
            if isempty(vals) || (strcmp(modelType, 'Cell') && all(all(all(cellfun('isempty',vals)))))
                varargout{1} = [];
            elseif isstruct(propRef)
                % permute KxMxN into correct dims for prop MxN and keys K:
                % struct: 1xK
                varargout{1} = vals.';
            else
                % 1xN cell: KxN
                % MxN cell: KxMxN
                varargout{1} = squeeze(vals);
            end
        end
        
        % setModelProperty
        function [valueUpdated, oldValue] = setModelProperty(this, modelType, dim1, dim2, key, value, fireUpdate)
            prop = [convertStringsToChars(modelType) 'ModelProperties'];
            if nargin < 7
                fireUpdate = true;
            end
            
            % Get old value
            oldValue = this.getModelProperties(modelType, dim1, dim2, key);

            % Check to see if the old and new values are equal
            % special case: for ColumnModelProperties, fireUpdate forces update
            valueUpdated = isempty(oldValue) || any(any(cellfun(@(x)~isequal(x,value),oldValue))) || (strcmp(modelType, 'Column') && fireUpdate);
            if valueUpdated
                % Set the new value
                if isstruct(this.(prop))
                    this.(prop).(key) = value;
                    oldValue = oldValue{1};
                elseif size(dim1, 2) == 1 && size(dim2, 2) == 1
                    this.(prop){dim1, dim2}.(key) = value;
                else
                    map = this.(prop)(dim1, dim2);
                    for r = 1:length(dim1)
                        for c = 1:length(dim2)
                            if isempty(map{r, c})
                                map{r, c} = struct();
                            end
                            map{r, c}.(key) = value;
                        end
                    end
                    this.(prop)(dim1, dim2) = map;
                end

                % Notify listeners of change
                if (fireUpdate)
                    eventData = internal.matlab.legacyvariableeditor.ModelChangeEventData;
                    eventData.Key = key;
                    eventData.OldValue = oldValue;
                    eventData.NewValue = value;
                    switch modelType
                        case 'Cell'
                            eventData.Row = dim1;
                            eventData.Column = dim2;
                        case {'Row', 'Column'}
                            eventData.(modelType) = dim2;
                    end
                    this.notify([convertStringsToChars(modelType) 'ModelChanged'], eventData);
                end
            elseif isstruct(this.(prop))
                oldValue = oldValue{1};
            end
        end
        
        % setModelPropertyDifferentValues
        function [valueUpdated, oldValue] = setModelPropertyDifferentValues(this, modelType, dim1, dim2, key, value, fireUpdate)
            % newValue is MxN cell, M=length(dim1) N=length(dim2)
            % loop through to set different newValue values across ModelProps(dim1, dim2) for key
            % need to fill MxN oldValue for change event
            oldValue = cell(size(value));
            valueUpdated = false;
            for r_i = 1:length(dim1)
                for c_i = 1:length(dim2)
                    [innerUpdated, innerOldValue] = this.setModelProperty(modelType, dim1(r_i), dim2(c_i), key, value{r_i, c_i}, fireUpdate);
                    valueUpdated = innerUpdated || valueUpdated;
                    if ~iscell(innerOldValue) % Table returns single oldValue
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
        function setModelProperties(this, modelType, dim1, dim2, varargin)
            if ~isempty(varargin) && iscell(varargin{1})
                % first varargin is a cell, so set different values across indices per property
                if ~(length(varargin) == 2 ...
                     && iscell(varargin{1}) && iscell(varargin{2}) ...
                     && length(varargin{1}) == length(varargin{2}) ...
                     && all(cellfun(@(x) iscell(x) && isequal(size(x), [length(dim1) length(dim2)]), varargin{2})))
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
                [updated, oldValue] = setModelPropertyFunc(modelType, dim1, dim2, key, newValues{i}, false);
                if (updated)
                    % keep track of updated keys for change event
                    updatedKeys{i} = key;
                    oldValues{i} = oldValue;
                end
                valueUpdated = updated || valueUpdated;
            end

            % Notify listeners of change
            if valueUpdated
                eventData = internal.matlab.legacyvariableeditor.ModelChangeEventData;
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
                            eventData.Row = dim1;
                            eventData.Column = dim2;
                        case {'Row', 'Column'}
                            eventData.(modelType) = dim2;
                    end
                end
                this.notify([convertStringsToChars(modelType) 'ModelChanged'], eventData);
            end
        end      
    end   
end
