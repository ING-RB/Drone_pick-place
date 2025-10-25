classdef RemoteStructureArrayViewModel < internal.matlab.variableeditor.peer.RemoteArrayViewModel & internal.matlab.variableeditor.StructureArrayViewModel
    %REMOTESTRUCTUREARRAYVIEWMODEL Remote Model Structure Array View Model for vector structures
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    methods
        function this = RemoteStructureArrayViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.StructureArrayViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                document, variable, 'viewID', viewID);
        end
        
        % Override RemoteArrayViewModel's information
        function initTableModelInformation (this)
            this.setTableModelProperties(...                
                'ShowColumnHeaderLabels', true,...
                'ShowColumnHeaderNumbers', false,...
                'ShowHeaderIcons',true,...
                'CornerSpacerTitle', getString(message(...
                    'MATLAB:codetools:variableeditor:Fields')), ...
                'EditableColumnHeaders', true, ...
                'EditableColumnHeaderLabels', true);
        end

        % Returns a string row vector with column headers for the range
        % startCol:endCol
        function headerNames = getHeadersForRange(this, startCol, endCol)
            data= this.DataModel.Data;
            headerNames = string(fields(data));
            headerNames = headerNames(startCol:endCol)';           
        end
             
        function [renderedData, renderedDims] = getRenderedData(this, startRow, endRow, ...
                startColumn, endColumn)
            [currentFormat, c] = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat(true); 
            format(this.DisplayFormatProvider.NumDisplayFormat);
            data = this.getRenderedData@internal.matlab.variableeditor.StructureArrayViewModel(...
                startRow, endRow, startColumn, endColumn);
            rawData = this.DataModel.Data;
            cellData = this.DataModel.DataAsCell;
            isMetaData = this.MetaData; 
            format(this.DisplayFormatProvider.LongNumDisplayFormat);
            [renderedData, renderedDims] = internal.matlab.variableeditor.peer.RemoteStructureArrayViewModel.getJSONForStructureArrayData( ...
                data, rawData, cellData, isMetaData, startRow, startColumn,  this.DataModel.Name, this.DisplayFormatProvider);
        end
        
        % NOTE: this is for headername editing. Leaving this as is for now,
        % we want to make this a plugin that can be toggled on.
        function status = handlePropertySetFromClient(this, es, ed)
            status = '';
            
            this.logDebug('RemoteArrayView','handlePropertySet','');
            % Handles properties being set.  ed is the Event Data, and it
            % is expected that ed.data.key contains the property which
            % is being set.  Returns a status: empty string for success,
            % an error message otherwise.
            if ~isfield(ed, 'data')
                return;
            end
            
            if isfield(ed.data,'source') && strcmp('server',ed.data.source)
                return;
            end

            if strcmpi(ed.data.key, 'ColumnModelProperty')
                column = this.getStructValue(ed.data.newValue,'column');
                property = this.getStructValue(ed.data.newValue,'property');
                value = this.getStructValue(ed.data.newValue,'value');
                
                currentData = this.DataModel.Data;
                dataFields = fields(currentData);
                numCols = length(dataFields);
                oldValue = dataFields(column+1);
                name = this.DataModel.Name;
                if strcmp(property,'HeaderName') && (~isequal(oldValue{1}, value))
                    
                    % if the header value is unchanged then do nothing
                    if isequal(dataFields{column+1}, value)        
                        return;
                    end
                    
                    try
                         % if the column header name is not a duplicate
                        if ~any(ismember(dataFields, value))                             
                            % Execute structure array update command
                            cmd = sprintf('[%s.%s] = %s.%s; %s = orderfields(%s, [1:%d, %d, %d:%d]); %s = rmfield(%s, "%s");',...
                                name,...
                                value,...
                                name, ...
                                oldValue{1},...
                                name, ...
                                name, ...
                                column, ...
                                numCols + 1, ...
                                column + 1, ...
                                numCols, ...
                                name, ...
                                name, ...
                                oldValue{1});
                            if ischar(this.DataModel.Workspace)
                                % Requires a row/column, even though row
                                % will be unused.
                                this.executeSetFieldsCommand(cmd, 1, column);
                            else
                                this.DataModel.Workspace.evalin(cmd);
                            end
                            return
                        else
                            % throw an error if the column header name is
                            % a duplicate
                            error(getString(message('MATLAB:codetools:variableeditor:DuplicateColumnHeaderStructs', value)));
                        end
                    catch e
                         % if the column header name is a duplicate then the
                        % error thrown is caught here and published to the
                        % client
                        this.sendEvent('ErrorEditingColumnHeader', 'status', 'error', 'message', e.message, 'index',  this.getStructValue(ed.data.newValue,'column'), 'source', 'server');
                        return;
                    end                    
                end
            end
            % Ensure that you deal with superclass propertySets only after
            % we have handled this at structArray level. Some cases could
            % error and we do not want the metadata to update.
            this.handlePropertySetFromClient@internal.matlab.variableeditor.peer.RemoteArrayViewModel(es, ed);
        end
    end
    
    methods(Static)
        function [renderedData, renderedDims] = getJSONForStructureArrayData(data, rawData, rawDataAsCell, MetaData, startRow, startColumn, variableName, DisplayFormatProvider)
            arguments
                data;
                rawData;
                rawDataAsCell cell;
                MetaData;
                startRow double;
                startColumn double;
                variableName = '';
                DisplayFormatProvider internal.matlab.variableeditor.NumberDisplayFormatProvider = internal.matlab.variableeditor.NumberDisplayFormatProvider
            end
            isMetaData = MetaData;
            sRow = max(1,startRow);            
            sCol = max(startColumn,1);           
            colStrsIndex = 1;
            renderedData = cell(size(data)); 
            field = fields(rawData);
            for col = 1:size(renderedData,2)                
                rowStrsIndex = 1;
                for row = 1:size(renderedData,1)                
                    editorValue = '';                    
                    rawDataAtIndex = rawDataAsCell{row+sRow-1,col+sCol-1};
                    if (isMetaData(row,col) || ...
                            ischar(rawDataAtIndex) && size(rawDataAtIndex,1) > 1) && ~isempty(variableName)
                        editorValue = sprintf('%s(%d).%s', variableName, row+sRow-1,char(field(col+sCol-1)));
                    end
                    
                    % only numerics need to have an editvalue which is in
                    % long format
                    % other data types have their edit value same as data
                    % value
                     
                    isNumericCell = isnumeric(rawDataAtIndex);
                    % For numeric objects, convert to numeric before
                    % formatting (g2044078) 
                    if isNumericCell && isobject(rawDataAtIndex)
                        rawDataAtIndex = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(rawDataAtIndex);
                        rawDataAsCell{row+sRow-1,col+sCol-1} = rawDataAtIndex;
                    end

                    if ~isMetaData(row,col)
                        longData = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(rawDataAtIndex, DisplayFormatProvider.LongNumDisplayFormat);
                    else
                        % This does not take the toJSON path. Adding this logic in formatDataUtils affects other
                        % scalar structs as well.  % Escape \ and " , Handle \n
                        % and \t for strings alone
                        data{row,col} = internal.matlab.variableeditor.peer.PeerUtils.formatGetJSONforCell(rawDataAtIndex, data{row,col});                                                    
                        longData = data{row,col};
                    end
                    
                    jsonData =  struct('value',data{row,col},...
                        'editValue',longData,...                        
                        'isMetaData',isMetaData(row,col));
                    if ~isempty(editorValue)
                        jsonData.editorValue = editorValue;
                    end
                    jsonData = internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, jsonData);

                    renderedData{row,col} = jsonData;
                    rowStrsIndex = rowStrsIndex + 1;
                end
                colStrsIndex = colStrsIndex + 1;
            end
            renderedDims = size(renderedData);
        end 
    end
    
    methods(Access = 'protected') 
        function updateCellModelInformation(this, startRow, endRow, startCol, endCol, fullRows, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                startCol (1,1) double {mustBeNonnegative}
                endCol (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
                fullColumns (1,:) double = startCol:endCol
            end
            this.CellModelChangeListener.Enabled = false;
            this.ColumnModelChangeListener.Enabled = false;            
            
            currentData = this.DataModel.getData;
            currentDataAsCell = this.DataModel.DataAsCell;
            structureArrayFieldNames = fields(currentData);           
            
            for col=endCol:-1:startCol
                % Check if all the entries in the column are of the same
                % date type. columnClassName will be 'mixed' if this is not a homogeneous column
                [~, columnClassName] = this.uniformTypeData(currentDataAsCell(:,col));                
                this.setColumnModelProperties(col, 'icon', columnClassName, 'HeaderName', structureArrayFieldNames{col});
                for row = endRow:-1:startRow
                    data = currentDataAsCell{row, col};
                    className = this.getLookupClassName(class(this), data);
                    isDurationType = any(strcmp(className, ["duration", "calendarDuration"]));
                    isCatType = any(strcmp(className, ["categorical","nominal","ordinal"]));

                    % Each cell in the column has different data type so set model properties on the cell
                    % For categoricals, compute categories per cell as individual fields can have their own categories
                    if strcmp(columnClassName,'mixed') || isCatType
                        this.setCellModelProperties(row, col,...                            
                            'class', className);
                        if isDurationType
                            this.setCellModelProperties(row, col,...                            
                                'editable', false);
                        elseif isCatType
                            cats = categories(data);
                            % Limit the number of categories displayed, otherwise we hit OutOfMemory errors
                            cats(internal.matlab.datatoolsservices.FormatDataUtils.MAX_CATEGORICALS:end) = [];
                            this.setCellModelProperties(row, col,...                    
                                'categories', cats, 'isProtected', isprotected(data), 'RemoveQuotedStrings', true);
                        end
                    else
                        % NOTE: set className/icon so that we get the
                        % matchedClassName updates. Since the col has
                        % uniform data, colClassName and className must be
                        % the same.
                        iconClass = className;
                        if any(strcmp(columnClassName, ["distributed", "codistributed", "gpuArray", "dlarray"]))
                            % For gpuArrays/distributed and co-distributed, we want to display the
                            % in-memory datatype icons on client, send class as columnClassName and icon with underlyingType.
                            iconClass = columnClassName + "_" + this.getVariableSecondaryInfo(data);
                        end
                        this.setColumnModelProperties(col, 'class', className, 'icon', iconClass);
                        if isDurationType
                            this.setColumnModelProperties(col, 'editable', false);
                        end
                        % Clear any stale cell metadata that could exist in this column.
                        this.resetAllCellModelProperties(row, col);
                        break;
                    end
                end
            end
            this.CellModelChangeListener.Enabled = true;
            this.ColumnModelChangeListener.Enabled = true;            
            
            this.updateCellModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startRow, endRow, startCol, endCol, fullRows, fullColumns);
            % g3343340: Immediately send column metadata to the frontend, rather than having the message be throttled and debounced first
            % (the latter way of sending the message is done through "updateCellModelInformation()").
            %
            % With a delayed message, the frontend could not choose correct column renderers by the time it received data, and
            % so users would temporarily see the data come in as raw JSON.
            % With an immediate message, we see the correct renderers (at a cost of slightly increased loading time of the data).
            this.sendColumnMetaData(startCol, endCol);
        end
        
        function classType = getClassType(varargin)
            % Return container class type (struct), not the individual
            % field from the specified struct.  Decisions made on the class
            % type returned here only depend on the container type.
            classType = 'struct';
        end
        
        function executeSetFieldsCommand(this, cmd, ~, ~)
            % Execute the command to set the header name
            c = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
            c.publishCode(this.DataModel.CodePublishingDataModelChannel, cmd, '');
        end
        
        % Calling into _dtcallback in order to execute the client set
        % command in the right 'caller' workspace. In order to be able to
        % access the right view, hash the view with a unique ID
        % (parentID+childID).
        % NOTE: Call into builtin only when the workspace is of type
        % 'char'. For custom workspaces, retain the synchronous execution.
        function handleClientSetData(this, eventData)
            s = this.getTabularDataSize;
            if eventData.column > s(2)+1
                this.sendEvent('dataChangeStatus', ...
                    'status', 'error', ...
                    'message', getString(message('MATLAB:codetools:variableeditor:StructArrayIndexOverflow')), ...
                    'row', eventData.row, ...
                    'column', eventData.column, ...
                    'newValue', eventData.data, ...
                    'source', 'server');
            else
                this.handleClientSetData@internal.matlab.variableeditor.peer.RemoteArrayViewModel(eventData);
            end
        end

        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data)
            [data, origValue, evalResult, isStr] = this.processIncomingDataSet@internal.matlab.variableeditor.peer.RemoteArrayViewModel(row, column, data);
             sz = this.getSize();
             if row <= sz(1) && column <= sz(2) 
                 if isa(this.DataModel.DataAsCell{row, column}, 'datetime')
                    data = ['''' data ''''];
                 end
             end
        end

        function handleDataModelCellMetaDataChanged(this, es, ed)
            this.logDebug('RemoteStructureArrayViewModel','handleDataModelCellMetaDataChanged','');
            s = this.getTabularDataSize;
            startRow = this.ViewportStartRow;
            if isempty(startRow)
                startRow = 1;
            end
            endRow = this.ViewportEndRow;
            if isempty(endRow)
                endRow = 1;
            end
            endRow = min(endRow,s(1));
            startCol = this.ViewportStartColumn;
            if isempty(startCol)
                startCol = 1;
            end
            endCol = this.ViewportEndColumn;
            if isempty(endCol)
                endCol = 1;
            end
            endCol = min(endCol, s(2));
            this.updateCellModelInformation(startRow, endRow, startCol, endCol, 1:s(1), 1:s(2));
            this.handleDataModelCellMetaDataChanged@internal.matlab.variableeditor.StructureArrayViewModel(es, ed);
        end

        function handleDataModelColumnMetaDataChanged(this, es, ed)
            this.logDebug('RemoteStructureArrayViewModel','handleDataModelColumnMetaDataChanged','');
            s = this.getTabularDataSize;
            startCol = this.ViewportStartColumn;
            if isempty(startCol)
                startCol = 1;
            end
            endCol = this.ViewportEndColumn;
            if isempty(endCol)
                endCol = 1;
            end
            this.updateColumnModelInformation(startCol, endCol);
            this.handleDataModelColumnMetaDataChanged@internal.matlab.variableeditor.StructureArrayViewModel(es, ed);
        end
    end
end
