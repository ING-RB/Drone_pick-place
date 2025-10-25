classdef MWTableDataStore < internal.matlab.datatoolsservices.data.DefaultTabularMetaDataStore & ...
                            internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore & ...
                            matlab.ui.internal.controller.uitable.TableView 
    % UITable customized DataStore that extended from DataTools services
    % for pagination purpose.
    
    %   Copyright 2021 The MathWorks, Inc.
    
    properties (Access = 'private')
        Controller;
        SourceDataSize = [0, 0];        
        ViewDataStrategy;
        PrivateSortedRowOrder;
        SupportsMixedDatatypes;
        PrivateSourceColumnFormat = {};
        PreviousViewValue;
    end
    
    properties (SetAccess = 'private')        
        SourceDataType;
    end

    properties (Dependent, SetAccess = private)
        SourceColumnFormat
        SortedRowOrder;
        SourceData;
    end
    
    methods
        function storeValue = get.SourceData(obj)
            storeValue = obj.Controller.getSourceData();
        end
        
        function set.SourceData(~, ~)
            % no op for now - may be used for cell edit later.
            assert(false);
        end
        
        % Enforce that the SortedRowOrder is always a column vector
        function set.SortedRowOrder(obj, sortedOrder)
            if ~iscolumn(sortedOrder)
                sortedOrder = sortedOrder';
            end
            obj.PrivateSortedRowOrder = sortedOrder;
        end
        
        function sortedOrder = get.SortedRowOrder(obj)
            sortedOrder = obj.PrivateSortedRowOrder;
        end
        
        function columnFormat = get.SourceColumnFormat(obj)
        
            if numel(obj.PrivateSourceColumnFormat) >= size(obj.SourceData, 2)
                columnFormat = obj.PrivateSourceColumnFormat;
            else
                % Replace any missing column format values with ''
                columnFormat = repmat({''}, 1, size(obj.SourceData, 2));
                columnFormat(1:numel(obj.PrivateSourceColumnFormat)) = obj.PrivateSourceColumnFormat;
                obj.PrivateSourceColumnFormat = columnFormat;
            end
        end

        function set.SourceColumnFormat(obj, columnFormat)
            obj.PrivateSourceColumnFormat = columnFormat;
        end
        
    end
    
    
    methods 
        % constructor
        function obj = MWTableDataStore(UITableController)
            obj@internal.matlab.datatoolsservices.data.DefaultTabularMetaDataStore();
            obj@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore(EnableBreakpoints=true);
            obj.Controller = UITableController; 
            obj.ViewDataStrategy = matlab.ui.internal.controller.uitable.utils.TableArrayStrategy;
            obj.PreviousViewValue = struct();
        end
        
    end
    
    % Abstract methods from PeerTabularDataStore
    methods
        function [viewFormattedValue, dim] = getTabularDataRange(obj, startRow, endRow, startColumn, endColumn)
            [startRow, endRow, startColumn, endColumn] = obj.getAdjustedRange(startRow, endRow, startColumn, endColumn);
            
            if (endRow == 0 || endColumn == 0)
                viewFormattedValue = table();
                dim = 0;
            else 
                
                viewFormattedValue = obj.Controller.getFormattedDataRange(startRow, endRow, startColumn, endColumn, obj.SourceDataType);
                dim = [endRow-startRow+1, endColumn-startColumn+1];
            end
        end 
        
        % cell edit
        function setTabularDataValue(obj, displayRow, displayColumn, value)
            % for now, only consider editing single-column variable in Table.

            % disable stack trace printing as part of the warning
            warnMode = warning('backtrace', 'off');
            oc = onCleanup(@()warning(warnMode));
            obj.Controller.handleCellEditFromClient(displayRow, displayColumn, value);
        end
        
        function [s] = getTabularDataSize(obj)
            s = obj.SourceDataSize;
        end
        
        function cellProperties = getTabularCellMetaData(obj, row, column)
            % GETTABULARCELLMETADATA - Override method from TabularDataStore 
            % to provide cell meta data for view.  
            sourceRow = obj.Controller.getSourceRowFromDisplayRow(row);
            sourceColumn = obj.Controller.getSourceColumnFromDisplayColumn(column);

            % Add any style rules that need to be applied
            cellProperties = obj.addStyleField(struct(), 'cell', sourceRow, sourceColumn);

            % Specify 'Datatype' metadata property if column data is a
            % cell array and no ColumnFormat is specified.
            if ~isempty(obj.SupportsMixedDatatypes) && ...
                column <= length(obj.SupportsMixedDatatypes) && ...
                obj.SupportsMixedDatatypes(column) && ...
                (isempty(obj.SourceColumnFormat) || ...
                (column <= length(obj.SourceColumnFormat) && isempty(obj.SourceColumnFormat{sourceColumn})))
                
                cellProperties.Datatype = obj.ViewDataStrategy.getDataType(obj.SourceData, sourceRow, sourceColumn);

                % Handle categorical metadata
                categoricalMetadata = obj.ViewDataStrategy.getCategoricalMetadata(obj.SourceData, obj.SourceColumnFormat, sourceRow, sourceColumn);
                cellProperties = obj.appendFields(cellProperties, categoricalMetadata);
            end
        end
        
        function rowProperties = getTabularRowMetaData(obj, row)
            % GETTABULARROWMETADATA - Override method from TabularDataStore 
            % to provide row meta data for view.  
            
            % get source row number for the sorted view.
            sourceRow = obj.Controller.getSourceRowFromDisplayRow(row);
            
            % Add any style rules that need to be applied
            rowProperties = obj.addStyleField(struct(), 'row', sourceRow);
            
            rowProperties.RowName = obj.Controller.getRowNameForView(sourceRow);
            
            % Add RowStriping if necessary
            rowStripingAttribute = 'backgroundColor';
            if ~isfield(rowProperties, 'style') || ...
                    ~isfield(rowProperties.style, rowStripingAttribute)
                
                backgroundColor = obj.Controller.getBackgroundColor();           
                rowColor = obj.getBackgroundColorForRow(row, backgroundColor);
                hexColor = matlab.ui.internal.controller.uitable.StylesManager.rgb2hex(rowColor);   

                rowProperties.style.(rowStripingAttribute) = hexColor;
            end
            
        end
        
        function columnProperties = getTabularColumnMetaData(obj, column)
            % GETTABULARCOLUMNMETADATA - Override method from TabularDataStore 
            % to provide column meta data for view.
            
            % For most of our column metadata properties, we set them using the DefaultTabularMetaDataStore.setColumnModelProperties. 
            % Examples of this in 19b are 'Datatype', 'GroupColumnSize', 'ColumnFormat', 'Editable', etc...
            % The superclass assembles all of this information and provides it to the client. 
            % Therefore we need this info from the superclass and append the 'Style' field to it 
            % When we switch to fetching all column metadata on the fly within this method, then we can avoid calling the superclass.
            columnProperties = getTabularColumnMetaData@internal.matlab.datatoolsservices.data.DefaultTabularMetaDataStore(obj, column);

            if column <= size(obj.SourceData, 2)
                startRow = 1;
                endRow = 1;
                [columnProperties.FallbackMinimumWidthCellContent, ~] = getTabularDataRange(obj, startRow, endRow, column, column);
            end

            % Add any style rules that need to be applied
            sourceColumn = obj.Controller.getSourceColumnFromDisplayColumn(column);
            styleProperty = obj.addStyleField(struct(), 'column', sourceColumn);
            columnProperties = obj.appendFields(columnProperties, styleProperty);
        end
        
        function tableProperties = getTabularTableMetaData(obj)
            % GETTABULARTABLEMETADATA - Override method from TabularDataStore 
            % to provide table meta data for view.
            tableProperties = getTabularTableMetaData@internal.matlab.datatoolsservices.data.DefaultTabularMetaDataStore(obj);
            
            % Add any style rules that need to be applied
            styleProperty = obj.addStyleField(struct(), 'table');
                        
            % Need to merge existing style with any style rules
            % Style rules will take precedence
            if isfield(styleProperty, 'style') && isfield(tableProperties, 'style')
                tableProperties.style = obj.appendFields(tableProperties.style, styleProperty.style);
                tableProperties.StyleRank = styleProperty.StyleRank;
            elseif ~isempty(fields(styleProperty))
                tableProperties = obj.appendFields(tableProperties, styleProperty);
            end
                
            
        end
        
        function metadata = getMetadataDefaults(obj)
            % GETCOLUMNMETADATADEFAULTS - This metadta is collected when
            % the server is ready and used to initialize the metadata
            % store.  The primary use of this is to have accurate
            % ColumnWidth calculations on construction. No other metadata
            % is required right now for construction specifically.
            
            metadata = struct('columnMetadata', []);
            tableMetadata = struct('FallbackMinimumWidthCellContent', []);
            columnMetadata = struct();
            % Column Number
            sourceDataSize = size(obj.SourceData);
            % Store sample cell content so that columns can be
            % calculated on construction or when the data is not yet loaded
            % in the view
            startRow = 1;
            endRow = 1;            
            for idx = 1:sourceDataSize(2)
                columnMetadata(idx).ColumnNumber = idx;
                [columnMetadata(idx).FallbackMinimumWidthCellContent, ~] = getTabularDataRange(obj, startRow, endRow, idx, idx);

                % Capture Group ColumnSize
                if istable(obj.SourceData)
                    columnSize = obj.getColumnModelProperty(idx, 'GroupColumnSize'); 
                    columnMetadata(idx).GroupColumnSize = columnSize{1};
                end
            end
            
            % ColumWidth
            for idx = 1:sourceDataSize(2)
                columnWidth = obj.getColumnModelProperty(idx, 'ColumnWidth');
                columnMetadata(idx).ColumnWidth = columnWidth{1};
            end

            % ColumName
            for idx = 1:sourceDataSize(2)
                headerName = obj.getColumnModelProperty(idx, 'HeaderName');
                columnMetadata(idx).HeaderName = headerName{1};
            end   

            metadata.columnMetadata = columnMetadata;
        end
    end
    
    % Abstract methods from TableView.
    methods
        
        function size = getDataStoreSourceDataSize(obj)
            % GETDATASTORESOURCEDATASIZE - This is the data size associated
            % with the last data update processed by the datastore.
            size = obj.SourceDataSize;
        end

        function setViewGroupColumnSize(obj, data)
            if obj.ViewDataStrategy.supportsGroupColumnSize()
                setGroupColumnSize(obj, data);
            end
        end
        
        % for controller to update data in mw-table view.
        function updateViewData(obj)
            
            % Since column data types may have changed when the data is
            % set, update the column model's datatype so the appropriate
            % renderer/editor can be viewed
            
            data = obj.SourceData;

            previousStrategy = obj.ViewDataStrategy;
            
            % Update data strategy if required
            if ~ obj.ViewDataStrategy.supportsData(data)                                      
                obj.ViewDataStrategy = obj.getDataStrategy(data); 
            end
            
            if previousStrategy.supportsGroupColumnSize() || ...
                obj.ViewDataStrategy.supportsGroupColumnSize()
                %Set GroupColumnSize for multi column
                setGroupColumnSize(obj, data);
            end

            previousSortedRowOrder = obj.SortedRowOrder;
                
            % When data is updated from the model, sort order should not
            % change.  [Editing requires special workflow to control this.]
            resetSortOrder(obj, data);

            previousSupportsMixedDatatypes = obj.SupportsMixedDatatypes;
            previousDataType = obj.SourceDataType;
            
            setViewDataType(obj, data);
                    
            % Compare previous size with new size 
            newSize = size(obj.SourceData);
            oldSize = obj.SourceDataSize;
            sizeChanged = ~isequal(newSize, oldSize);
            
            % update SourceDataSize with new value
            obj.SourceDataSize = newSize;

            % Update ColumnFormat if level of support changes with data
            supportsColumnFormat = obj.ViewDataStrategy.dataSupportsColumnFormat();
            previousSupportsColumnFormat = previousStrategy.dataSupportsColumnFormat();
            if xor(supportsColumnFormat, previousSupportsColumnFormat)
               obj.setViewColumnFormat(obj.PrivateSourceColumnFormat);
            end

            % The metadata needs to be stored because clearing cell
            % metadata needs to happen AFTER the DataChange event is
            % emitted such that the right data size is used. See g1957637 
            metadataToClear = obj.getCellMetaDataRangeToClearForMixedDataTypes(previousSupportsMixedDatatypes);
            
            if previousStrategy.requiresAdditionalColumnMetadataWhenDataSet(previousDataType) || ...
                obj.ViewDataStrategy.requiresAdditionalColumnMetadataWhenDataSet(obj.SourceDataType) || ...
                newSize(2) ~= oldSize(2) ... the number of columns has changed
            
                % If applicable, set additional metadata
                setAdditionalColumnMetadata(obj, obj.SourceData, obj.SourceDataType, obj.SourceColumnFormat);
            
            end
            
            % Update view
            sendViewChangedEvent(obj, sizeChanged)
            
            % Trigger cell metadata update if specified
            if ~isempty(metadataToClear)
                obj.clearCellMetaData(metadataToClear{1}, metadataToClear{2});
            end

            if ~isequal(previousSortedRowOrder, obj.SortedRowOrder)
                obj.clearCellAndRowMetaData();
            end
        end
        
         % for controller to update data in mw-table view.
         function updateSingleViewData(obj, displayRow, displayCol, sourceRow, sourceCol)
            
            % Get the data from the model
            data = obj.SourceData;

            % Categorical will get updated if new category is added
            categoricalStruct = obj.ViewDataStrategy.getCategoricalMetadata(data, obj.SourceColumnFormat, sourceRow, sourceCol);
            
            % Create pv pairs from struct
            categoricalPVPairs = reshape([...
                fieldnames(categoricalStruct)'; ...
                struct2cell(categoricalStruct)'],...
                1, []);
            if ~isempty(categoricalPVPairs)
                obj.setColumnModelProperties(displayCol, categoricalPVPairs{:})
            end
            
            % A single cell's value is edited, so the size will not change
            sizeChanged = false;
            
            % If there is a cell edit, notify datastore to update mw-table
            % view of the single cell
            sendViewChangedEvent(obj, sizeChanged, displayRow, displayCol)
        end 
      
        % for controller to update data in mw-table view.
        function updateViewDataRange(obj, startDisplayRow, endDisplayRow, startDisplayColumn, endDisplayColumn)
            
            % A single cell's value is edited, so the size will not change
            sizeChanged = false;
            
            % If there is a cell edit, notify datastore to update mw-table
            % view of the single cell
            sendViewChangedEvent(obj, sizeChanged, startDisplayRow, endDisplayRow, startDisplayColumn, endDisplayColumn)
        end 
        
        function setViewColumnName(obj, names)
            
            % When the data is an empty column vector, the ColumnName
            % drives the view size, the side effects of changing the size
            % like the minimum width and the view update must be triggered.
            sz = obj.Controller.getModelDataSize();
            if sz(2) == 0
                updateViewData(obj);
            end
            
            % for now, always show labels.
            obj.setViewProperty('Table', 'ShowColumnHeaderLabels', true);
  
            setViewProperty(obj, 'Column', 'HeaderName', names);
        end
        
        function setViewColumnEditable(obj, editable)
            setViewProperty(obj, 'Column', 'Editable', editable); 
        end
        
        function setViewColumnFormat(obj, format)
            % ColumnFormat has no effect on table array data
            if (istable(obj.SourceData) && ~all(cellfun('isempty', format)))
                w = warning('backtrace', 'off');
                warning(message('MATLAB:uitable:ColumnFormatNotSupported'));
                warning(w);

                % Send the default empty ColumnFormat to the view
                format = cell(1, numel(format));
            end
            
            % Store previous column format for comparison later
            previousColumnFormat = obj.PrivateSourceColumnFormat;
            
            obj.PrivateSourceColumnFormat = format;
            
            % Set values to view
            setViewProperty(obj, 'Column', 'ColumnFormat', format);

            % If applicable, set additional metadata
            setAdditionalColumnMetadata(obj, obj.SourceData, obj.SourceDataType, format);
            
            % Update view
            sendViewChangedEvent(obj, true);

            previousSpecifiedColumnFormats = ~cellfun('isempty', previousColumnFormat);
            newSpecifiedColumnFormats = ~cellfun('isempty', format);
            
            % Trigger a CellMetaDataChanged event to update the 'datatype' 
            % metadata. 
            %
            % This workflow gets triggered in two scenarios:
            % 1. Previous column format is empty, new column format is non-empty (i.e. 'logical')
            % 2. Previous column format is non-empty, new column data is empty
            requiresMetaDataClearing = obj.xorForMixedLengthArrays(previousSpecifiedColumnFormats, newSpecifiedColumnFormats);

            if any(requiresMetaDataClearing)
                dataSize = size(obj.SourceData);
                displayRowsToClear = 1:dataSize(1);
                columnsToClear = find(requiresMetaDataClearing); % Only trigger event for columns that changed
                displayColumnsToClear = obj.Controller.getDisplayColumnFromSourceColumn(columnsToClear);    
                obj.clearCellMetaData(displayRowsToClear, displayColumnsToClear);
            end
        end
        
        function setViewColumnSortable(obj, sortable)
            % SETVIEWCOLUMNSORTABLE - sets the sortable property on the
            % view.  The assumption is made that the default value is
            % false, so any unmatched columns do not require manually being
            % set.  When the value is a scalar true, the true must be
            % expanded to affect all columns
            
            sourceData = obj.SourceData;
            % If sortable is scalar true, expand the values for each column
            if isequal(sortable, true)
                sortable = true(1, size(sourceData,2));
            end
            
            % Calculation only needs to be made for shorter specification,
            % when arrays are not the same size
            if numel(sortable) > numel(obj.SourceDataType)
                sortable = sortable(1:numel(obj.SourceDataType));
            end
            
            columnIndex = find(sortable);
            sortedAndSupported = sortable;
            sortedAndSupported(columnIndex) = obj.ViewDataStrategy.dataSupportsSorting(sourceData, columnIndex, obj.SourceDataType);
            
            if any(sortedAndSupported)
                % Update view if any columns are eligible for sorting
                setViewProperty(obj, 'Column', 'IsSortable', sortedAndSupported); 
            else
                % Set with no value in order to clear current state
                setViewProperty(obj, 'Column', 'IsSortable', false(1, size(sourceData,2)));
            end
        end

        function clearCellMetaData(obj, displayRow, dislayColumn)
            % CLEARCELLMETADATA - Notify that the cell metadata has changed
            if isnumeric(displayRow) && isnumeric(dislayColumn)
                eventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                eventData.Row = displayRow;
                eventData.Column = dislayColumn;
                obj.notify('CellMetaDataChanged', eventData);
            end
        end
        
        function clearRowMetaData(obj, displayRow)
            % CLEARROWMETADATA - Notify that the row metadata has changed
            if isnumeric(displayRow) && obj.SourceDataSize(1) > 0
                eventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                eventData.Row = displayRow;
                obj.notify('RowMetaDataChanged', eventData);
            end
        end
        
        function clearColumnMetaData(obj, displayColumn)
            % CLEARCOLUMNMETADATA - Notify that the column metadata has changed
            if isnumeric(displayColumn)
                eventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                eventData.Column = displayColumn;
                obj.notify('ColumnMetaDataChanged', eventData);
            end
        end
        
        function clearTableMetaData(obj)
            % CLEARTABLEMETADATA - Notify that the table metadata has changed
            obj.notify('TableMetaDataChanged');
        end
        
        function setViewTableStyle(obj, styleStruct)
            obj.setTableModelProperty('style', styleStruct);
        end
        function setViewColumnRearrangeable(obj, columnRearrangeable)
            obj.setTableModelProperty('columnRearrangeable', columnRearrangeable);
        end
        function setViewColumnWidth(obj, widths)
            obj.setViewProperty('Column', 'ColumnWidth', widths);
        end
      
        function [ChannelID] = getViewInfo(obj)
            ChannelID = obj.Channel;
        end

        function setViewDataType(obj, data)
            % SETVIEWDATATYPE - This is called when the
            % data changes
            
            datatype = obj.ViewDataStrategy.getDataType(data);
            obj.SupportsMixedDatatypes = strcmp(datatype, 'cell');
            
            % Update data type
            setViewProperty(obj, 'Column', 'Datatype', datatype);
            obj.SourceDataType = datatype;
        end
    end  
    
    methods
                
        function rowOrder = sortTable(obj, columnNumber, direction)
            % SORTTABLE - Operates on the source data to provide sorting of
            % one column
            %
            % columnNumber - expected to be a valid column number as it is
            % reflected in the raw data.  Since we do not have a way to
            % rearrange the columns in the view, the view column and raw
            % data column are always the same.
            %
            % direction - will be 'ascend', 'descend' or 'unsorted'. SORTROWS 
            % supports partial matching, but better not to assume that all 
            % methods will support it in the future.
            if strcmp(direction, "unsorted")
                resetSortOrder(obj, obj.SourceData);
            else
                % Assume sortrows supports the datatype: Numeric, datetime etc                
            	[~, obj.SortedRowOrder] = sortrows(obj.SourceData, columnNumber, direction);
            end
            
            % Expected to be a vertical column
            rowOrder = obj.SortedRowOrder;
            
            obj.clearCellMetaDataForMixedCells();
            obj.clearCellAndRowMetaData();
            
            % Size will not change due to sorting
            sizeChanged = false;
            
            sendViewChangedEvent(obj, sizeChanged);
        end
        
        function clearCellMetaDataForMixedCells(obj)
            % If any column is a mixed cell array, clear the cell metadata of that column
            % to update its 'datatype' metadata. This will refresh the renderers. 
            if any(obj.SupportsMixedDatatypes)
                dataSize = size(obj.SourceData);
                displayRowsToClear = 1:dataSize(1);
                columnsToClear = find(obj.SupportsMixedDatatypes);
                obj.clearCellMetaData(displayRowsToClear, columnsToClear);
            end
        end
        % convert model indices to view indices.
        function viewIndex = convertToViewIndex(obj, modelIndex, indexType)
            
            if isempty(modelIndex)
                viewIndex = [];
                return;
            end
            
            switch indexType
                case 'cell'
                    % input modelIndex is N-by-2 numeric array for cells.
                    cols = obj.Controller.getDisplayColumnFromSourceColumn(modelIndex(:, 2));
                    rows = obj.Controller.getDisplayRowFromSourceRow(modelIndex(:, 1));
                    viewIndex = [rows(:) cols(:)];
                case 'row'
                    % input modelIndex is 1-by-N numeric array for rows
                    viewIndex = obj.Controller.getDisplayRowFromSourceRow(modelIndex);
                case 'column'
                    % no conversion needed for now for column index.
                    viewIndex = obj.Controller.getDisplayColumnFromSourceColumn(modelIndex);
            end
        end
        
        % util method to reverse a sorted order.
        % 	- UnsortedModelIndices = SortedOrder(SortedViewIndices)
        %   - SortedViewIndices = ReverseSortedOrder(UnsortedModelIndices)
        function reverseOrder = reverseSortedOrder(obj, sortedOrder)
            unsort = 1:length(sortedOrder);
            reverseOrder(sortedOrder) = unsort;
        end
    end

    % util methods
    methods (Access = 'protected')
        
        function setViewProperty(obj, type, propertyName, values)
            
            % Convert values to cell array if not. 
            % @TODO setColumn/RowModelProperties should also accept array.
            if ~iscell(values)
                values = num2cell(values);
            end

            switch type
                case 'Table'
                    obj.setTableModelProperty(propertyName, values);
                    
                case 'Column'
                    columns = numel(values);
                    preColumns = size(obj.SourceData,2);
                    
                    % empty out trailing values from previous set.
                    columnsToUpdate = max(columns, preColumns);
                    rearrangedPaddedValue = repmat({''}, 1, columnsToUpdate);

                    % 1:end is the source indices, get the display indices
                    % in order to map values back to the rearranged order.
                    displayOrder = obj.Controller.getDisplayColumnFromSourceColumn(1:columns);
                    rearrangedPaddedValue(displayOrder) = values;

                    % If calculated view value is identical, do not bother
                    % to update the view
                    if ~isfield(obj.PreviousViewValue, propertyName) ||...
                            ~isequal(obj.PreviousViewValue.(propertyName), rearrangedPaddedValue)

                        obj.setColumnModelProperties(1:columnsToUpdate, {propertyName}, {rearrangedPaddedValue});
                        obj.PreviousViewValue.(propertyName) = rearrangedPaddedValue;
                    end
                    
                case 'Row'
                    rows = numel(values);
                    preRows = numel(obj.RowModelProperties);
                    
                    % empty out tailing values from previous set.
                    rowsToUpdate = max(rows, preRows);
                    rearrangedPaddedValue = repmat({''}, 1, rowsToUpdate);
                    rearrangedPaddedValue(1:numel(values)) = values;
                    
                    obj.setRowModelProperties(1:rowsToUpdate, {propertyName}, {rearrangedPaddedValue'});   
            end
        end          
        
        function sendViewChangedEvent(obj, sizeChanged, varargin)
            % SENDVIEWCHANGEDEVENT - This function sends an event that the
            % variable editor system is listening for.  
            % sizeChanged - true or false, one role this has is as a
            % performance optimization.
            % varargin (row, column) - used in cell editing
            % row - an integer representing the edited cell's row
            % column - an integer representing the edited cell's column
            % varargin (startRow, endRow, startColumn endColumn) - used in
            % clearing text related to rearrangeing columns
            % The variables correspond to the rectangular area that requies
            % an update.
               
            if nargin == 6
                % If this was called with 4 additional inputs, it signifies a 
                % range edit. Specify the single cell that changed.
                startRow = varargin{1};
                endRow = varargin{2};
                startColumn = varargin{3};
                endColumn = varargin{4};

            elseif nargin == 4
                % If this was called with a row and column, it signifies a 
                % single cell edit. Specify the single cell that changed.
                startRow = varargin{1};
                endRow = startRow;
                startColumn = varargin{2};
                endColumn = startColumn;
            else
                % Otherwise, manually specify that entire table has changed
                dataSize =  size(obj.SourceData);
                startRow = 1;
                endRow = dataSize(1);
                startColumn = 1;
                endColumn = dataSize(2);
            end

            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;           
            eventdata.StartRow = startRow;
            eventdata.EndRow = endRow;
            eventdata.StartColumn = startColumn;
            eventdata.EndColumn = endColumn;
            
            % Compare previous size with new size 
            eventdata.SizeChanged = sizeChanged;
  
            % update view
            obj.notify('DataChange', eventdata);
        end
        
        function setGroupColumnSize(obj, data)
            
            % Get group column size
            groupedColumnWidths = obj.ViewDataStrategy.getGroupColumnSize(data);
            
            % Update data type
            setViewProperty(obj, 'Column', 'GroupColumnSize', groupedColumnWidths);

        end
        
        function resetSortOrder(obj, data)
            % RESETSORTORDER - With no sorting, the sort order should be
            % [1;2;3;....end]
            obj.SortedRowOrder = 1:size(data, 1);
        end
        
        function metadataToClear = getCellMetaDataRangeToClearForMixedDataTypes(obj, previousSupportsMixedDatatypes)
        
            % get indices to clear metadata. Typically, the datatype
            % metadata is the most impactful because that can change
            % editors and renderers in the cells.
            %
            % This workflow gets triggered in two scenarios:
            % 1. Previous column data is 'cell', new column data is anything
            % 2. Previous column data is anything, new column data is 'cell'
            % Only need to consider the columns that exist in both data sets
            % 
            % This needs to happen after the new obj.SupportsMixedDatatypes
            % is assigned because getTabularCellMetaData will be triggered
            % and will need to know the new value of obj.SupportsMixedDatatypes
            
            metadataToClear = {};
            
            if ~isempty(previousSupportsMixedDatatypes)
                requiresMetaDataClearing = obj.orForMixedLengthArrays(previousSupportsMixedDatatypes, obj.SupportsMixedDatatypes);
                
                if any(requiresMetaDataClearing)
                    rowsToClear = 1:obj.SourceDataSize(1);
                    columnsToClear = find(requiresMetaDataClearing); % Only trigger event for columns that changed
                    metadataToClear = {rowsToClear, columnsToClear};
                end
            end
            
        end
    
        function setAdditionalColumnMetadata(obj, data, datatype, columnFormat)
          

            displayColumn = obj.Controller.getDisplayColumnFromSourceColumn(1:min(size(data, 2), length(datatype)));
            for column = 1:min(size(data, 2), length(datatype))
                % Some data types require additional information for the
                % view.  These are unlikely to be generic to the data type
                % and more likely to be specific to the column content.  

                categoricalStruct = obj.ViewDataStrategy.getCategoricalMetadata(data, columnFormat, column);
                % Create pv pairs from struct
                categoricalPVPairs = reshape([...
                    fieldnames(categoricalStruct)'; ...
                    struct2cell(categoricalStruct)'],...
                    1, []);
                if ~isempty(categoricalPVPairs)
                    obj.setColumnModelProperties(displayColumn(column), categoricalPVPairs{:})
                end
            end
        end

        function [startRow, endRow, startColumn, endColumn] = getCurrentRange(obj)
            [startRow, endRow, startColumn, endColumn] = obj.getAdjustedRange(obj.StartRow, obj.EndRow, obj.StartColumn, obj.EndColumn);
        end
        
        function rowColor = getBackgroundColorForRow(obj, row, backgroundColor)
            % GETBACKGROUNDCOLORFORROW - Computes the color that should be
            % specified for a given row
            % row - row number index (1-based)
            % backgroundColor - m-by-3 matrix of RGB triplets
            rowColor = '';            
            numColors = size(backgroundColor, 1);
            
            if(numColors > 0)
                % Get the index for the backgroundColor array
                colorIndex = mod(row - 1, numColors) + 1; 
                % 
                rowColor = [backgroundColor(colorIndex,1) ...
                            backgroundColor(colorIndex,2) ...
                            backgroundColor(colorIndex,3)];
            end
        end
        
        function metadataFields = addStyleField(obj, metadataFields, metadataType, varargin)
            % ADDSTYLEFIELD - Obtains any styles that have been computed
            % which should apply to the given metadata type. Then appends 
            % the styles to existing 'properties' struct and returns the
            % updated reference
            controller = obj.Controller;
            stylesManager = controller.StylesManager;
            if stylesManager.hasStylesTable()
                if strcmp(metadataType, 'cell')
                    metadataFields = obj.Controller.StylesManager.getStyleMetaData(metadataType, varargin{1}, varargin{2});
                elseif strcmp(metadataType, 'row')
                    metadataFields = obj.Controller.StylesManager.getStyleMetaData(metadataType, varargin{1});
                elseif strcmp(metadataType, 'column')
                    metadataFields = obj.Controller.StylesManager.getStyleMetaData(metadataType, varargin{1});
                elseif strcmp(metadataType, 'table')
                    metadataFields = obj.Controller.StylesManager.getStyleMetaData(metadataType);
                end
            end
        end

        function cellFilteredDataType = filterCellDataTypes(obj, maxSpecLength)
            % FILTERCELLDATATYPES - Returns a copy of obj.SourceDataType
            % and replaces all instances of 'cell' with a new datatype if
            % the cell array column has a uniform data type (all data in
            % the column is of the same type)
            % It assumes all cellstr columns are of type 'cellstr' in 
            % obj.SourceDataType, not 'cell'
            cellFilteredDataType = obj.SourceDataType;
            for column=1:maxSpecLength                
                if strcmp(obj.SourceDataType(column), 'cell')
                    try
                        cellData = cell2mat(obj.SourceData(:, column));
                        % Do not allow cell array of logical data to be
                        % sorted. Sortrows does not support this as of 19b.
                        % See g2035017
                        if ~islogical(cellData)
                            cellFilteredDataType{column} = class(cellData);
                        end
                    catch ME %#ok<NASGU>
                        % Don't update the datatype if unable to convert to
                        % matrix. It indicates a mixed cell column.
                    end
                end
            end 
        end
    end
    
    methods (Static, Access = private)        
        function strategy = getDataStrategy(data)
            % GETDATASTRATEGY - Returns strategy that supports the right
            % data.  
            
            import matlab.ui.internal.controller.uitable.utils.*
            if TableArrayStrategy.supportsData(data)
                strategy = TableArrayStrategy;
            elseif NumericArrayStrategy.supportsData(data)
                strategy = NumericArrayStrategy;
            elseif StringArrayStrategy.supportsData(data)
                strategy = StringArrayStrategy;
            elseif CellstrArrayStrategy.supportsData(data)
                strategy = CellstrArrayStrategy;
            elseif CellArrayStrategy.supportsData(data)
                strategy = CellArrayStrategy;
            elseif LogicalArrayStrategy.supportsData(data)
                strategy = LogicalArrayStrategy;
            else
                error('Strategy for %s data type not implemented', class(data));
            end                  
        end
        
        function orResult = orForMixedLengthArrays(arrayA, arrayB)
            % ORFORMIXEDLENGTHARRAYS - Computes logical OR between two arrays, 
            % only considering the length of the shortest array. 
            lengthA = length(arrayA);
            lengthB = length(arrayB);
            minLength = min(lengthA, lengthB);

            orResult = arrayA(1:minLength) | arrayB(1:minLength) ;
        end
        
        function xorResult = xorForMixedLengthArrays(arrayA, arrayB)
            % XORFORMIXEDLENGTHARRAYS - Computes logical XOR between two arrays, 
            % only considering the length of the shortest array. 
            lengthA = length(arrayA);
            lengthB = length(arrayB);
            minLength = min(lengthA, lengthB);

            xorResult = xor(arrayA(1:minLength), arrayB(1:minLength));
        end
        
        function targetStruct = appendFields(targetStruct, sourceStruct)
            % APPENDFIELDS - Adds fields from sourceStruct and appends them
            % to targetStruct
            fields = fieldnames(sourceStruct);
            for i=1:length(fields)
                targetStruct.(fields{i}) = sourceStruct.(fields{i});
            end
        end

        function containsAuto = columnWidthContainsAuto(columnWidth)
            containsAuto = false;
            if any(strcmp('auto', columnWidth))
                containsAuto = true;
            end
        end

        function containsFit = columnWidthContainsFit(columnWidth)
            containsFit = false;
            if any(strcmp('fit', columnWidth))
                containsFit = true;
            end
        end
    end

    methods (Access = private)
        function clearCellAndRowMetaData(obj)
            % If there are style rules specified, update the cell and row
            % metadata for the entire table
            if obj.Controller.StylesManager.hasStylesTable
                dataSize = size(obj.SourceData);
                displayRowsToClear = 1:dataSize(1);
                columnsToClear = 1:dataSize(2);
                obj.clearRowMetaData(displayRowsToClear);
                obj.clearCellMetaData(displayRowsToClear, columnsToClear);
            end
        end
    end
end