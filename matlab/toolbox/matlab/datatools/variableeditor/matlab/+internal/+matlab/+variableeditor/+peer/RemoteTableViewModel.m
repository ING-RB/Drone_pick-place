classdef RemoteTableViewModel < internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
         internal.matlab.variableeditor.TableViewModel
    % RemoteTableViewModel Remote Table View Model

    % Copyright 2019-2025 The MathWorks, Inc.
    properties
        % These properties used to indicate if the UI should use the table
        % meta data for VariableNames and RowNames to set those HeaderName
        % and RowNames in the UI.  If set to false the UI will not be
        % updated from the Table's meta data.
        UseTableRowNamesForView = true;
        UseTableColumnNamesForView = true;
    end

    properties(Transient)
        metaDataChangedListener;
    end

    properties(Access = protected)
        ColReorderWidth = 0;
    end

    methods
        function this = RemoteTableViewModel(document, variable, viewID, userContext)
            arguments
                document
                variable
                viewID = ''
                userContext = ''
            end
            % Ensure that TableViewModel is initialized first, else
            % TableModelProperties set during initTableModelInformation
            % will get reset.
            this@internal.matlab.variableeditor.TableViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(document,variable, 'viewID', viewID);
        end

        % Initialize thread safety to control requests executed on
        % background thread. If table has > 250000 entries cumulatively as
        % cells/strings/cats, set thread safety to false.
        function handled = initializeThreadSafety(this)
            handled = this.initializeThreadSafety@internal.matlab.variableeditor.peer.RemoteArrayViewModel();
            if (~handled)
                % If table has cells/strings having more than limit
                % supported by datastore for bgpool fetches, turn off
                % theading
                data = this.DataModel.Data;
                varClasses = data.Properties.VariableTypes;
                dataTypeCount = sum(ismember(varClasses, ["cell","string","categorical"]));
                if (dataTypeCount*height(data)) > this.STR_NUMEL_CUTOFF_FOR_BACKGROUND_FETCHES
                    % Set property on pubsubdatastore to notify client.
                    this.setThreadSafety(false);
                    handled = true;
                end
            end
        end

        % TableModel Updates that happens during view creation. Disable
        % listeners as this state will be sync'ed once viewport is set.
         function initTableModelInformation (this)
            this.TableModelChangeListener.Enabled = false;
            this.setTableModelProperties(...
                'ShowColumnHeaderNumbers', true,...
                'ShowColumnHeaderLabels', true,...
                'EditableColumnHeaderLabels', true,...
                'ShowIndexAndLabel', false, ...
                'HasRowNames', ~isempty(this.getRowNames()));
            this.TableModelChangeListener.Enabled = true;
         end
        
         function handleClientSelection(this, eventData)            
            this.handleClientSelection@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                    eventData);
            this.updateSelectionContext();            
         end
         
         function nameWidth = computeHeaderWidthUsingLabels(this, colName)
            nameWidth = internal.matlab.datatoolsservices.FormatDataUtils.computeHeaderWidthUsingLabels(colName);
            nameWidth = nameWidth + this.ColReorderWidth;
         end
         
         % Updates selection context for grouped/ungrouped context and for
         % selection subset if it is a numeric/char subset or cell
         % otherwise.
         function updateSelectionContext(this, data)
             arguments
                 this
                 data = this.DataModel.getCloneData
             end
             clientSelection = this.getSelectionIndices;           
             rows = clientSelection{1};
             cols = clientSelection{2};
             % Ensure that selection is not empty.
             if ~isempty(rows) && ~isempty(cols)
                 % Allow update only when all rows/consecutive columns are
                 % selected.
                 varnames = data.Properties.VariableNames;
                 selectedCols = {};
                 for col = cols.'
                     selectedCols = [selectedCols, varnames(unique(col(1): col(2)))];
                 end
                 % isGrouped = false;
                 % isUngrouped = false;
                 % if height(rows) == 1 && height(cols) == 1 && all(rows(:,1) == 1) && all(rows(:,2) == height(data))
                 %     selectedTable = data(:, selectedCols);
                 %     if ~isempty(selectedTable)
                 %         colCount = width(selectedTable);
                 %         if isscalar(unique(varfun(@class, selectedTable, 'outputFormat', 'cell'))) && colCount > 1
                 %             isGrouped = true;
                 %         elseif colCount == 1
                 %             colStartIndices = this.getColumnStartIndicies(selectedTable, 1, colCount);
                 %             if (colStartIndices(2) - colStartIndices(1)) > 1
                 %                 isUngrouped = true;
                 %             end
                 %         end
                 %     end
                 % end
                 % this.setProperty('GroupVariable', isGrouped);
                 % this.setProperty('UngroupVariable', isUngrouped);
                 this.updateSelectionSubset(rows, cols, selectedCols, data);
             end
         end

        % Gets selection indices for the current view. From the current
        % selection, adjust column indices to account for time column.
        % TODO: Fix this for nested table indices as well
        function s = getSelectionIndices(this)
            s = this.getSelection();
            if ~isempty(s{2}) && ~isempty(this.GroupedColumnCounts)
                s{2} = internal.matlab.variableeditor.TableViewModel.getColumnsFromSelectionString(s{2}, this.GroupedColumnCounts);
            end
        end

         function updateSelectionSubset(this, rows, ~, selectedCols, data)
             arguments
                 this
                 rows
                 ~ % cols
                 selectedCols
                 data = this.DataModel.Data
             end
             selectedTable = data(rows, selectedCols);
             numericSubset = selectedTable(:, vartype('numeric'));
             if isequal(size(numericSubset), size(selectedTable))
                 this.setProperty('SelectionSubset', 'numeric');
             else
                 stringSubset = selectedTable(:, vartype('string'));
                 if isequal(size(stringSubset), size(selectedTable))
                     this.setProperty('SelectionSubset', 'string');
                 else
                     charSubset = selectedTable(:, vartype('char'));
                     if isequal(size(charSubset), size(selectedTable))
                         this.setProperty('SelectionSubset', 'char');
                     else
                         this.setProperty('SelectionSubset', 'cell');
                     end
                 end
             end
         end
        
        function headerNames = getHeaderNames(this, data)
            arguments
                this %#ok<*INUSA>
                data = this.DataModel.Data
            end
            headerNames = data.Properties.VariableNames;
        end

        % TODO: See if we can club this with getDisplayData
        function headerNames = getHeadersForRange(this, startColumn, endColumn, data)
            arguments
                this
                startColumn
                endColumn
                data = this.DataModel.Data
            end
            varNames = this.getHeaderNames(data);
            totalCount = endColumn - startColumn + 1;
            if ~isempty(this.GroupedColumnCounts)
                [actualStartColumn,actualEndColumn, currColIndex]=internal.matlab.variableeditor.TableViewModel.getNestedColumnRange(startColumn,endColumn,this.GroupedColumnCounts);
                headerNames = string.empty;
                for i=actualStartColumn:actualEndColumn
                    curColCount = this.GroupedColumnCounts(i);
                    % For grouped columns consider the width of leaf columns (1,2,3...)
                    if curColCount > 1
                        colsToFill = min(totalCount, curColCount-currColIndex+1);
                        headerNames = [headerNames string(currColIndex:currColIndex+colsToFill-1)];
                    else
                        headerNames = [headerNames varNames(i)];
                    end
                end
                headerNames = headerNames(1:totalCount);
            else
                headerNames = string(varNames(startColumn: endColumn));
            end
        end

        function startIndicies = getColumnStartIndiciesHelper(~, rawData, startColumn, endColumn)
            startIndicies = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(rawData, startColumn, endColumn);
        end

        % Helper function to get command needed to retrieve variable names
        % based on datatype
        function varname = getVarNameHelper(~, rawData)
            varname = rawData.Properties.VariableNames;
        end

        % Helper function to get command needed to retrieve row names
        % based on datatype
        function rowname = getRowNameHelper(~, rawData)
            rowname = rawData.Properties.RowNames;
        end

        function assignmentString = generateVariableNameAssignmentStringHelper(~, rawData, subs, vname, tname)
            assignmentString = matlab.internal.tabular.generateVariableNameAssignmentString(rawData, subs, vname, tname);
        end

        % Helper function to get command string needed to retrieve variable names
        % based on datatype
        function propString = getVariableNameString(~)
            propString = "VariableNames";
        end

        % Helper function to get command string needed to update row names
        % based on datatype
        function cmdString = getRowUpdateString(~)
            cmdString = '%s.Properties.RowNames(%d) = "%s";';
        end

        % Get rendered data from TableViewModel and packages isMetaData and
        % EditValues for numeric data along with data.
        function [renderedData, renderedDims] = getRenderedData(this, startRow, endRow, ...
                startColumn, endColumn)
            [currentFormat, c] = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat(true);
            numDisplayFormat = this.DisplayFormatProvider.NumDisplayFormat;
            longFormat = this.DisplayFormatProvider.LongNumDisplayFormat;
            format(numDisplayFormat);

            naninfBreakpoint = internal.matlab.datatoolsservices.DebugUtils.disableNanInfBreakpoint();
            cl = onCleanup(@() internal.matlab.datatoolsservices.DebugUtils.reEnableNanInfBreakpoint(naninfBreakpoint));
            
            % Get the renderedData from TableViewModel(for display formats) and format into JSON.
            [data, dims, editValue, startRow, endRow, startColumn, endColumn] = this.getRenderedData@internal.matlab.variableeditor.TableViewModel(...
                startRow, endRow, startColumn, endColumn);
            if isempty(this.DataModel.Data)
                renderedData = [];
                renderedDims = [0 0];
                return;
            end

            renderedData = string(data);
            editValues = strings(dims);           
            if (any(any(editValue)))
                format(longFormat);
                for col=1:dims(2)
                    if any(editValue(:,col))
                        d = editValue(:,col);
                        parsedVal = {cellstr(matlab.internal.display.numericDisplay(d, d, 'ScalarOutput', false, 'Format', longFormat, 'OmitScalingFactor', true))};
                        editValues(:,col) = parsedVal{1};
                    end
                end               
            end
            
            numRows = endRow-startRow + 1;
            numColumns = endColumn - startColumn + 1;
            s = struct;
            for row=1:numRows
                for col=1:numColumns
                    isJSON = false;
                    val = renderedData(row,col);
                    s.value = val;
                    if editValue(row,col) ~= 0
                        s.editValue = editValues{row,col};
                        isJSON = true;
                    end
                    if this.MetaData(row,col)
                       s.isMetaData = true; 
                       isJSON = true;
                    end

                    if isJSON
                        renderedData(row,col) = jsonencode(s);
                    end
                    s = struct;
                end
            end
            renderedDims = size(renderedData);
        end

        % getData
        % Gets a block of data.
        % If optional input parameters are startRow, endRow, startCol,
        % endCol then only a block of data will be fetched otherwise all of
        % the data will be returned.
        function varargout = getData(this,varargin)
            % Superclass getData will return a table representation of the
            % data.
            t = this.getData@internal.matlab.variableeditor.ArrayViewModel(varargin{:});
            v = table2cell(t);
            varargout{1} = v;
        end

        % Calling into just getData for tables converts tables to
        % cellarray. Directly call into the dataModel's getData to get the
        % actual data
        function value = getDataForStringDisplay(this, varargin)
            value = this.DataModel.getData(varargin{:});
        end       

       function status = handlePropertySetFromClient(this, ~, ed)
            this.logDebug('PeerArrayView','handlePropertySet','');

            % Handles properties being set.  ed is the Event Data, and it
            % is expected that ed.EventData.key contains the property which
            % is being set.  Returns a status: empty string for success,
            % an error message otherwise.
            status = '';
            if isfield(ed.data,'source') && strcmp('server',ed.data.source)
                return;
            end

            if strcmpi(ed.data.key, 'ColumnModelProperty') || strcmpi(ed.data.key, 'RowModelProperty')
                property = this.getStructValue(ed.data.newValue,'property');
                value = this.getStructValue(ed.data.newValue,'value');

                % if the column header names are set by the user
                if strcmp(property,'HeaderName')
                    % Considering rowNum as 0 since this is column Name update
                    rowNum = 0;
                    columnNames = this.getVarNameHelper(this.DataModel.getCloneData);
                    % getColumnIndex returns the right column number (1-indexed) to generate header rename syntax
                    column = this.getColumnIndex(ed.data.newValue);

                    % if the header value is unchanged then do nothing
                    if isequal(columnNames{column}, value)
                        return;
                    end

                    try
                        % Check for max allowed length
                        if strlength(value) > namelengthmax
                            varName = internal.matlab.datatoolsservices.VariableUtils.getTruncatedIdentifier(value);
                            error(message("MATLAB:table:VariableNameLengthMax", varName, strlength(value), namelengthmax));
                        end

                        % if the column header name is not a duplicate
                        if ~any(ismember(columnNames, value))
                            % Execute table update command
                            cmd = [this.generateVariableNameAssignmentStringHelper(this.DataModel.Data, column, value, this.DataModel.Name) ';'];

                            if ischar(this.DataModel.Workspace)
                                % Requires a row/column, even though row
                                % will be unused.
                                this.executeSetTablePropertyCommand(cmd, 1, column);
                            else
                                this.DataModel.Workspace.evalin(cmd);
                            end
                            % When column is renamed, reset caches so RemoteArrayViewModel can re-compute widths
                            this.FittedColumnWidths(column) = 0;
                            this.resetColumnModelProperty(column, 'ColumnWidth');
                            % this call is necessary for undo stack to get
                            % updated
                            this.notifyOnVariableEdit(rowNum, column, columnNames{column}, value, {cmd});
                            return
                        else
                            % throw an error if the column header name is
                            % a duplicate
                            error(message('MATLAB:codetools:variableeditor:DuplicateColumnHeaderTables', value));
                        end
                    catch e
                        % if the column header name is a duplicate then the
                        % error thrown is caught here and published to the
                        % client
                        this.sendEvent('ErrorEditingColumnHeader', 'status', 'error', 'message', e.message, 'index',  column-1, 'source', 'server');
                    end
                % if the row header names are set by the user
                elseif strcmp(property, 'RowName')
                    % Considering columnNum as 0 since this is column Name update
                    columnNum = 0;
                    % Using cellstr for converting rowNames incase of
                    % timeTables where they have different formats.
                    rowNames = cellstr(this.getRowNameHelper(this.DataModel.Data));
                    row = this.getStructValue(ed.data.newValue,'row');

                    % if the header value is unchanged then do nothing
                 
                    if isequal(rowNames{row+1}, value)
                        return;
                    end                 

                    try
                        % if the row header name is not a duplicate
                        if ~ismember(rowNames, value)
                            % escape apostrophes ('"')
                            value = strrep(value,'"','""');

                            % Execute table update command
                            cmd = sprintf(this.getRowUpdateString(),...
                            this.DataModel.Name,...
                            row+1,...
                            value);
                            if ischar(this.DataModel.Workspace)
                                % Execute the command to set the header name
                                c = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
                                c.publishCode(this.DataModel.CodePublishingDataModelChannel, cmd);
                            else
                                this.DataModel.Workspace.evalin(cmd);
                            end
                            % this call is necessary for undo stack to get
                            % updated
                            this.notifyOnVariableEdit(row, columnNum, rowNames{row+1}, value, {cmd});

                            return
                        else
                            % if the row header name is a duplicate then
                            % throw an error message
                            error(message('MATLAB:codetools:variableeditor:DuplicateRowHeader', value));
                        end
                    catch e
                        % if the row header name is a duplicate then the
                        % error thrown is a caught and published to the
                        % client
                        this.sendEvent('ErrorDuplicateRowHeader', 'status', 'error', 'message', e.message, ...
                            'index',  this.getStructValue(ed.data.newValue,'row'), 'source', 'server');
                    end
                end
            elseif strcmp(ed.data.key, 'ColumnReorderable') && ed.data.newValue
                this.ColReorderWidth = internal.matlab.variableeditor.VEColumnConstants.COL_REORDER_WIDTH;               
            elseif strcmpi(ed.data.key, 'TableModelProperty')
                property = this.getStructValue(ed.data.newValue,'property');
                value = this.getStructValue(ed.data.newValue,'value');
                this.setTableModelProperty(property, value);
            end
            % Ensure that you deal with superclass propertySets only after
            % we have handled this at table level.
            this.handlePropertySetFromClient@internal.matlab.variableeditor.peer.RemoteArrayViewModel([], ed);
       end

       % In case of peer event from client on double click, compute
       % editorValue of cell to send back to client.
       function handleEventFromClient(this, ~, ed)
            this.handleEventFromClient@internal.matlab.variableeditor.peer.RemoteArrayViewModel([], ed);
            if strcmpi(ed.data.type, 'doubleClickedOnMetaDataServerEvent')
                eventData = ed.data.eventData;
                row = eventData.row + 1;
                column = eventData.column + 1;
                editorValue = this.getEditorValueForCell(row, column);
                event = struct('source', 'server', 'type', 'editorValueOnDoubleClick', 'row', eventData.row, ...
                    'column', eventData.column,  ...
                    'editorValue', editorValue);
                this.dispatchEventToClient(event);
            end
       end

       % Returns editorValue of a cell that was double clicked on.
       function editorValue = getEditorValueForCell(this, row, column)
           data = this.DataModel.Data;
           name = this.DataModel.Name;
           dataSize = size(data);
           actualColumn = column;
           gColSize = 1;
           if ~isempty(this.GroupedColumnCounts)
               [gColSize, actualColumn, ~, dataIdx] = internal.matlab.variableeditor.TableViewModel.getColumnStartForRange(column, column, this.GroupedColumnCounts);               
           end
            
           varNames = this.getVarNameHelper(data);
           varName = varNames{actualColumn};
           try
            currData = data{row,actualColumn};
           catch
               % For objs like curve fitting that cannot be indexed
               currData = data;
           end
           % For strings alone, metadata would be missing values, do not send editorValue across.
           if isa(currData, 'string')
                editorValue = '';
                return;
            end
           % Treat nD data as its own data type.
           if numel(size(data.(actualColumn))) > 2
               editorValue = this.getNDEditorValue(name, varName, row, size(data.(actualColumn)));
           % For scalars or row vectors, directly index by
           % variable name. (This works out for objects like curve fitting that do not allow row indexing.)
           elseif (dataSize(1) == 1)
               editorValue = sprintf('%s.(''%s'')', name, varName);
               % For objects that are of UDD type, set
               % editorValue for indexing appropriately.
           elseif isempty(meta.class.fromName(class(currData)))
               editorValue = sprintf('%s.(''%s'')(%d,%d)', name,varName,row,actualColumn);
          elseif iscell(data.(actualColumn))
              if gColSize == 1
                  editorValue = sprintf('%s.(''%s''){%d,:}', name,varName,row);
              else
                  editorValue = sprintf('%s.(''%s''){%d,%d}', name,varName,row,dataIdx);
              end
           elseif ~isa(currData,'dataset') && ~istabular(currData) && ...
                   ~isa(currData,'struct') && ~isnumeric(currData) && ...
                   ~isobject(currData)
               editorValue = sprintf('%s.(''%s''){%d,%d}', name,varName,row,1);
           elseif isa(currData,'struct') || ...
                   (isobject(currData) && ~istabular(currData))
               editorValue = sprintf('%s.(''%s'')(%d,%d)', name,varName,row,1);
               % If the column is of type cell, index with {} to edit the underlying cell contents.
           else
               editorValue = sprintf('%s.(''%s'')(%d,:)', name,varName,row);
           end
       end

        % API to fetch Variable Data for a particular column index from a nested table. 
        % varData (variable data from a regular | grouped table) for a particular columnIndex. 
        % varName (variable name of the column Index for a regular/nested table)
        function [varData, varName, data] = getVariableInfoForColumnIndex(this, columnIndex, varNames)
            data = this.DataModel.Data;
            [~,dataIdx] = this.getHeaderInfoFromIndex(columnIndex);
            varName = varNames{dataIdx};
            varData = data.(dataIdx);
        end
    end

    methods(Access='protected')
        function handleDataChangedOnDataModel(this, es ,ed)
            % Reset the date formats if the date columns have changed
            data = this.DataModel.getData;
            if isa(data, 'dataset')
                dtColIdx = datasetfun(@isdatetime, data);
            else
                dtColIdx = varfun(@isdatetime, data, "OutputFormat", "uniform");
            end
            currDTCols = ~ismissing(this.DTFormats);

            if ~isequal(dtColIdx, currDTCols)
                this.DTFormats = strings(0);
            end
            internal.matlab.datatoolsservices.logDebug("variableeditor::remoteTableViewModel", "handleDataChangedOnDataModel");
            oldSz = this.getSize();
            % If currentSize exists, get oldSize from here. It could be
            % possible that the columnMetaData update modified size before the
            % DataUpdate 
            if ~isempty(this.CurrentSize)
                oldSz = this.CurrentSize;
            end
            % Update view cache for both size and gcol indices. (This is
            % already updated by handleColumnMetaDataChangedOnDataModel,
            % but is not reliable if dataChanged without metaDataChange)
            this.setViewSize();

            % Once view size is recomputed, check if there was an actual size change. 
            % (Grouped cols and nested table size changes will not be marked correctly by the DataModel)
            newSz = this.getSize();
            if (oldSz(2) ~= newSz(2))
                ed.SizeChanged = true;
            end

            % When data changes and is in grouped column, refresh the
            % entire grouped column
            startCol = ed.StartColumn;
            if (~isempty(startCol) && startCol == ed.EndColumn && ~isempty(this.GroupedColumnCounts))
                gcolStartIndices = cumsum([1 this.GroupedColumnCounts]);
                ed.StartColumn = gcolStartIndices(startCol);
                ed.EndColumn = gcolStartIndices(startCol + 1) - 1;
            end
            % Reset currentSize at the end of every DataChange. We only
            % want to track CurrentSize updates before a dataChange.
            this.CurrentSize = [];
            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.peer.RemoteArrayViewModel(es, ed);
        end

        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteTableViewModel';
        end    
 
        % Gets the right column index to be used for header rename
        function [columnIndex] = getColumnIndex(this, columnHeaderInfo)
            % Value coming from client is 0 indexed, make this 1 indexed.
            columnIndex = this.getStructValue(columnHeaderInfo,'column') + 1;
            if ~isfield(columnHeaderInfo, 'groupedColumn')
                [~,columnIndex] = this.getHeaderInfoFromIndex(columnIndex);
            end
        end

        function handleMetaDataChanged(this, ~, ed)
            data = this.DataModel.Data;
            if strcmp(ed.Property, this.getVariableNameString())
                metaData = '';
                editedHeaderIndex = find(~cellfun(@strcmp, ed.OldValue, ed.NewValue));
                if isscalar(editedHeaderIndex)
                   [~, ~, metaData] = this.formatDataBlock(1,size(data,1),editedHeaderIndex,editedHeaderIndex,data);
                end
                % if the column contains any valueSummaries then the editor
                % for those cells needs to be updated. So a DataChange
                % event is forced
                if ~isempty(metaData) && any(any(metaData))
                    eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                    this.notify('DataChange',eventdata);
                else
                   this.updateMetaDataModels(this.ViewportStartRow, this.ViewportEndRow, this.ViewportStartColumn, this.ViewportEndColumn);
                end
            else
                this.updateMetaDataModels(this.ViewportStartRow, this.ViewportEndRow, this.ViewportStartColumn, this.ViewportEndColumn);
            end
            % fires a selection changed event in case the metadata changed
            % is selected
            this.setSelection(this.SelectedRowIntervals, this.SelectedColumnIntervals);
        end

        function isValid = validateInput(this,value,row,column)
            % The only valid input types are 1x1 doubles
            classType = this.getClassType(row,column);
            if internal.matlab.datatoolsservices.FormatDataUtils.isNumericType(classType)
                % (~isempty(value) && ismissing(value)) isempty is for the ''
                % use case
                isValid = (isnumeric(value) || (~isempty(value) && ismissing(value))) && size(value, 1) == 1 && size(value, 2) == 1;
            else
                switch classType
                    case 'char'
                        isValid = ischar(value) && size(value, 1) == 1;
                    case 'string'
                        isValid = internal.matlab.datatoolsservices.FormatDataUtils.checkIsString(value) && size(value, 1) == 1;
                    case 'logical'
                        isValid = (islogical(value) || isnumeric(value)) && size(value, 1) == 1 && size(value, 2) == 1;
                    case 'datetime'
                        % Since the client is sending characters we need to try to
                        % convert them to a valid datetime object. This requires
                        % getting a copy of the actual datetime data in the table and trying an
                        % assignment of the form data(row, column) = value. If the
                        % result is a datetime, then the value is valid. If an
                        % exception occurs, throw a datetime specific error instead
                        % of the error sent from handleClientSetData. (g1239590)
                        if isStringScalar(value)
                            try
                                dt = this.getData();
                                dt = dt{row, column};
                                dt(1) = value;
                                isValid = isdatetime(dt);
                            catch
                                error(message('MATLAB:datetime:InvalidFromVE'));
                            end
                        else
                            isValid = false;
                        end
                    otherwise
                        isValid = true;
                end
            end
        end

        function result = evaluateClientSetData(this, data, row, column, classType)
            arguments
                this
                data
                row
                column
                classType = this.getClassType(row,column)
            end
            % In case of numeric or logical columns, if the user types a single character
            % in single quotes, it is converted to its equivalent ascii value
            result = [];
            if internal.matlab.datatoolsservices.FormatDataUtils.isNumericType(classType) || isequal(classType, 'logical')
                if (isequal(length(data), 3) && isequal(data(1),data(3),''''))
                    result = double(data(2));
                end
            end
        end

        function varName = getVariableName(this, ~, column, data) 
            arguments
                this
                ~
                column
                data = this.DataModel.Data
            end
            varName = eval(sprintf('data.Properties.VariableNames{%d}',column));
        end

        % Fetches underlying classtype of the data
        % column is the actual column index (unflattened by nested or grouped)
        function classType = getClassType(this, ~, column, sz, data) 
            arguments
                this
                ~
                column
                sz = size(this.DataModel.Data)
                data = this.DataModel.Data
            end
            if column <= sz(2)
                classType = class(data.(column));
            else
                % Infinite grid
                classType = '';
            end
        end

        function replacementValue = getEmptyValueReplacement(this,row,column, classType)
            arguments
                this
                row
                column
                classType = this.getClassType(row,column)
            end
            if internal.matlab.datatoolsservices.FormatDataUtils.isNumericType(classType)
                replacementValue = '0';
            else
                switch classType
                    case 'logical'
                        replacementValue = '0';
                    case 'datetime'
                        replacementValue = 'NaT';
                    case 'duration'
                        replacementValue = 'NaN';
                    case 'calendarDuration'
                        replacementValue = 'NaN';
                    case 'string'
                        replacementValue = 'string('''')';
                    otherwise
                        replacementValue = '[]';
                end
            end
        end

        function updateColumnModelInformation(this, startCol, endCol, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startCol (1,1) double {mustBeNonnegative}
                endCol (1,1) double {mustBeNonnegative}
                fullColumns (1,:) double = startCol:endCol
            end
            this.ColumnModelChangeListener.Enabled = false;

            internal.matlab.datatoolsservices.logDebug("variableeditor::remoteTableViewModel", "updateColumnModelInformation(" + startCol + "," + endCol + ")");
            this.setColumnMetaData(startCol, endCol, this.DataModel.Data);
            this.ColumnModelChangeListener.Enabled = true;
            this.updateColumnModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startCol, endCol, fullColumns);
        end

        function subColIterator = setColumnMetaData(this, startCol, endCol, data, currentColumn)
            arguments
                this
                startCol
                endCol
                data
                currentColumn = startCol
            end
            % g1772972: is no longer an issue
            dataIdx = 1;
            actualStartColumn = startCol;
            actualEndColumn = endCol;
            widgetRegistry = internal.matlab.datatoolsservices.WidgetRegistry.getInstance();

            % TODO: make gcolindices work recursively with nested columns
            if ~isempty(this.GroupedColumnCounts)
                [gCols, colIdx, endColIdx, dataIdx] = internal.matlab.variableeditor.TableViewModel.getColumnStartForRange(startCol, endCol, this.GroupedColumnCounts);
                actualStartColumn = colIdx;
                actualEndColumn = endColIdx;
            else
                gCols = ones(1, actualEndColumn-actualStartColumn+1);
            end

            % Loop over top level columns (Ungrouped)
            colIterator = 1;
            subColIterator = currentColumn;
            varNames = this.getVarNameHelper(data);
            try
                for col=actualStartColumn:actualEndColumn
                    colValForValidation = data(:, col);
                    currentVarName = varNames{col};

                    % 1. Compute groupColumnSize
                    gColStart = 1;
                    gColEnd = gCols(colIterator);

                    if (dataIdx > 1)
                        gColStart = dataIdx;
                        dataIdx = 1;
                    end
                    gColEnd = min(endCol, gColEnd);
                    groupColumnSize = gCols(colIterator);

                    % 2. Compute isSortable
                    isSortable = internal.matlab.variableeditor.peer.PeerUtils.checkIsSortable(colValForValidation, false);
                    % 3. Compute isFilterable
                    isFilterable = internal.matlab.variableeditor.peer.PeerUtils.checkIsFilterable(colValForValidation, false);
                    for i = gColStart:gColEnd
                        % 1. Compute HeaderName
                        if this.UseTableColumnNamesForView
                            this.setColumnModelProperty(subColIterator,'HeaderName',currentVarName, false);
                        end

                        % 4. Set groupColumnSize for grouped columns
                        % For Grouped Columns, set Data Attributes so that they can
                        % be queried from the registry.
                        if (groupColumnSize > 1)
                            this.setColumnModelProperty(subColIterator,'GroupColumnSize', num2str(groupColumnSize), false);
                            this.setColumnModelProperty(subColIterator,'ParentIndex', num2str(col), false);
                            this.setColumnModelProperty(subColIterator,'GroupColumnIndex', num2str(i), false);
                            % reset isSortable and isFilterable flag in case this is a DataChange. These columns do not have header menus on client.
                            this.resetColumnModelProperty(subColIterator, 'IsSortable');
                            this.resetColumnModelProperty(subColIterator, 'IsFilterable');
                        else
                            % Turn off sorting and filtering for grouped columns
                            this.setColumnModelProperty(subColIterator,'IsSortable',isSortable, false);
                            this.setColumnModelProperty(subColIterator,'IsFilterable',isFilterable, false);

                            if this.hasColumnModelProperty(subColIterator, 'GroupColumnIndex')
                                this.resetColumnModelProperty(subColIterator, 'GroupColumnSize');
                                this.resetColumnModelProperty(subColIterator, 'ParentIndex');
                                this.resetColumnModelProperty(subColIterator, 'GroupColumnIndex');
                            end
                        end

                        % 5. Set datatype specific properties like categories / RemoveQuotedStrings / EditorConverter
                        classType = this.getClassType(':',col, size(data), data);
                        switch classType
                            case {'categorical' 'nominal' 'ordinal'}
                                % Get the list of categories and whether it is a
                                % protected categorical or not.  Treat categorical,
                                % nominal and ordinal all the same.
                                cats = categories(data.(this.getVariableName(':',col, data)));
                                % Limit the number of categories displayed, otherwise we
                                % hit OutOfMemory errors
                                cats(internal.matlab.datatoolsservices.FormatDataUtils.MAX_CATEGORICALS:end) = [];

                                % set column model properties with information for client
                                % isProtected is expected on the client as a double/logical
                                this.setColumnModelProperties(subColIterator,...
                                    'categories', cats,...
                                    'RemoveQuotedStrings',true,...
                                    'isProtected', isprotected(data.(this.getVariableName(':',col, data))));
                            case {'char'}
                                this.setColumnModelProperties(subColIterator, 'RemoveQuotedStrings', true);
                            case {'datetime'}
                                % Datetime columns require a converter
                                this.setColumnModelProperties(subColIterator, 'EditorConverter', 'datetimeConverter');
                            case {'duration', 'calendarDuration'}
                                % Ignore the first column since it is a
                                % time column
                                if ~isequal(subColIterator,1)
                                    this.setColumnModelProperties(subColIterator, 'editable', false);
                                end
                            otherwise
                                % Stale RemoveQuotedStrings prop can affect codegen,
                                % reset this property when DataChanges and this is no longer valid (g2842298)
                                % TODO: There could be other properties that need  clearing, re-design how
                                % metadata is set on client.
                                this.resetColumnModelProperty(subColIterator, 'RemoveQuotedStrings');
                                this.resetColumnModelProperty(subColIterator, 'categories');
                        end

                        % 6. Compute 'class' property from WidgetRegistry matches
                        val = data.(char(currentVarName));
                        className = class(val);
                        [widgets,~,matchedVariableClass] = widgetRegistry.getWidgets(class(this),className);
                        if (isobject(val) || isempty(meta.class.fromName(class(val)))) && isempty(matchedVariableClass)
                            className = 'object';
                            [widgets, ~, matchedVariableClass] = widgetRegistry.getWidgets(class(this), className);
                        end

                        % if className is different from matchedVariableClass then
                        % it means that the current data type is unsupported. In
                        % this case, the metadata of the unsupported object should
                        % be displayed in the table column.
                        if ~strcmp(className,matchedVariableClass)
                            widgets = widgetRegistry.getWidgets(class(this),'default');
                            className = matchedVariableClass;
                        end

                        % if the className is cell, check if cellstr and set
                        % specific className
                        if (iscellstr(val))
                            className = 'cellstr';
                        end

                        this.setColumnModelProperties(subColIterator,...
                            'class', className);
                        subColIterator = subColIterator + 1;
                    end
                    colIterator = colIterator + 1;
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::remoteTableViewModel", "Error in setColumnMetaData()");
            end
        end

        function updateRowModelInformation(this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end
            this.RowModelChangeListener.Enabled = false;
            currentData = this.DataModel.Data;
            
            if this.UseTableRowNamesForView
                rowNames = this.getRowNames(currentData);
                % This is set once in initTableModelInfo, update this if
                % rownames are no longer part of the dataset
  
                this.setTableModelProperty('HasRowNames', ~isempty(rowNames));
                % currentData could either be a regular table or
                % timetable.Using cellstr to handle both these types.
                rowName = cellstr(rowNames);
                % If endRow is 0, there are no rows in the viewport, do not
                % set RowModelProperties
                if (endRow > 0)
                    naninfBreakpoint = internal.matlab.datatoolsservices.DebugUtils.disableNanInfBreakpoint();
                    c = onCleanup(@() internal.matlab.datatoolsservices.DebugUtils.reEnableNanInfBreakpoint(naninfBreakpoint));

                    for row=startRow:endRow
                        % Set Header Name
                        if ~isempty(rowNames) && row<=size(rowNames,1) && ...
                                ~isempty(rowName{row})
                            this.setRowModelProperty(row,'RowName',rowName{row});
                        else
                            try
                                % For tables that do not have rowname, send NaNs
                                % such that the client only shows indices.
                                this.setRowModelProperty(row,'RowName', NaN, false);
                            catch e
                                internal.matlab.datatoolsservices.logDebug("variableeditor::remoteTableViewModel", "Error in updateRowModelInformation()");
                            end
                        end
                    end
                end
            end
            this.RowModelChangeListener.Enabled = true;
            this.updateRowModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startRow, endRow, fullRows);
        end

        function rowNames = getRowNames(this, data)
            arguments
                this
                data = this.DataModel.getData
            end
            props = data.Properties;
            if isprop(props, 'RowNames')
                % Tables with row names
                rowNames = props.RowNames;
            elseif isfield(props, 'ObsNames')
                % Datasets with observation names (Properties is a struct type)
                rowNames = props.ObsNames;
            else
                rowNames = {};
            end
        end

        % nD data in a table is accessed using parentheses and an
        % appropriate number of colons.
        %
        % For example, a 4-by-2-by-7 cell array would have a name of
        % <table>.<cellName>(<row>, :, :).
        %
        % A 4-by-2-by-7-by-3 struct array would have a name of
        % <table>.<structArrayName>(<row>, :, :, :).
        function editorValue = getNDEditorValue(~, name, varName, row, sz)
            editorValue = sprintf('%s.(''%s'')(%d', name, varName, row);
            for idx = 2:numel(sz)
                editorValue = [editorValue, ',:']; %#ok<AGROW>
            end
            editorValue = [editorValue, ')'];
        end

        function executeSetTablePropertyCommand(this, cmd, ~, ~)
            % Execute the command to set the header name
            c = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
            c.publishCode(this.DataModel.CodePublishingDataModelChannel, cmd);
        end

        % Handles Single Cell Data Edit from Client for a row|column.
        % 1. Calls into processIncomingDataSet that checks for valid
        % quotes/string escapes and empty value replacements.
        % 2. Evaluates formatted data in workspace of incoming data was not empty. 
        % 3. If value set is equal to current value, we return as NOOP. 
        % 4. Calls setTabularData to construct code for the edit operation and notify datamodel to publish code. 
        % 5. Notifies SingleCellEdit for ML listeners like UI Components.
        function handleClientSetData(this, eventData)
            rawData = this.getStructValue(eventData, 'data');
            row = this.getStructValue(eventData, 'row');
            column = this.getStructValue(eventData, 'column');
            throwIndexError = false;
            origValue = [];
            data = rawData;
            try
                if ~isempty(row)
                    if ischar(row)
                        row = str2double(row);
                    end
                    if ischar(column)
                        column = str2double(column);
                    end
                   
                   actualColumn = column;
                   columnIndex = 1;
                   if ~isempty(this.GroupedColumnCounts)
                       [~, actualColumn, ~, columnIndex] = internal.matlab.variableeditor.TableViewModel.getColumnStartForRange(column, column, this.GroupedColumnCounts);
                   end
        
                   % TODO: Fix this once nested table editing is supported in VE
                    sz = this.getSize();

                    if column > (sz(2) + 1)
                        throwIndexError = true;
                        column = sz(2) + 1;
                        actualColumn = width(this.DataModel.Data) + 1;
                    end

                    [data, origValue, result, isStr] = this.processIncomingDataSet(row, actualColumn, rawData, column);

                    if isempty(result) && ~isempty(rawData)
                        [result] = evalin(this.DataModel.Workspace, data);  % Test for a valid expression.
                    end
                    if ~this.validateInput(result,row,actualColumn)
                        error(message('MATLAB:codetools:variableeditor:InvalidInputType'));
                    end
                    currentValue = this.getData(row, row, actualColumn, actualColumn);
                    if iscell(currentValue) && ~isempty(currentValue)
                        currentValue = currentValue{:};
                        if (columnIndex > 1 && ~isempty(currentValue))
                            currentValue = currentValue(columnIndex);
                        end                        

                        % for categoricals that are same, short-circuit. 
                        % (The client does not check for cats, always
                        % dispatches an update)
                        classType = this.getClassType(row, actualColumn);
                        if strcmp(classType, 'categorical') && isequal(char(currentValue), result)
                            return;                            
                        end
                    end
                        
                    % disable warning for datetime isequal.
                    savedWarning = internal.matlab.variableeditor.peer.PeerUtils.disableWarning();

                    % Check for isEqual values only when origValue
                    % is not empty(Edit was within Finite Grid)
                    if ~isempty(origValue) && this.isEqualDataBeingSet(result, currentValue, row, actualColumn)
                            % Even though the data has not changed we will fire
                            % a data changed event to take care of the case
                            % that the user has typed in a value that was to be
                            % evaluated in order to clear the expression and
                            % replace it with the value (e.g. pi with 3.1416)
                            this.updateDataForRange(this, row, actualColumn);
                            return;
                    end
                    % enable warning
                    internal.matlab.variableeditor.peer.PeerUtils.resumeWarning(savedWarning);

                    dispValue = strtrim(evalc('disp(evalin(this.DataModel.Workspace, data))'));
                    setCommand = this.setTabularData(row, actualColumn, columnIndex, data, dispValue, result, origValue);
                    code = sprintf('%s%s', this.DataModel.Name, setCommand);
                    this.notifyOnVariableEdit(row, column, currentValue, result, {code});

                    % If this is an out of bounds edit, we will still
                    % successfully carry out the edit opeation to immediate
                    % right of the table width and throw an error message as well.
                    if throwIndexError
                        error(message('MATLAB:codetools:variableeditor:TableIndexOverflow'));
                    end
                else
                    error(message('MATLAB:codetools:variableeditor:invalidRow'));
                end
            catch e
                this.notifyOnEditError(e.message, row, column, origValue, data);
            end
        end

        % Sets data on the DataModel and dispatches StatusChange to the
        % client.
        function varargout = setTabularData(this, row, column, columnIndex, data, dispValue, evaluatedValue, origValue)
            varargout{1} = {};
             try
                msgOnError = this.getMsgOnError(row, column, 'dataChangeStatus');
                varargout{1} = this.setTableDataValue(row, column, columnIndex, data, dispValue, evaluatedValue, msgOnError);
                this.sendEvent('dataChangeStatus', ...
                    'status', 'success', ...
                    'message', '', ...
                    'row', row, ...
                    'column', column, ...
                    'newValue', data, ...
                    'origValue', origValue, ...
                    'source', 'server');
            catch e
                this.sendEvent('dataChangeStatus', ...
                    'status', 'error', ...
                    'message', e.message, ...
                    'row', row, ...
                    'column', column, ...
                    'newValue', data, ...
                    'origValue', origValue, ...
                    'source', 'server');
             end
        end
    end
end
