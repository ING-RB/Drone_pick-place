classdef TableViewModel < internal.matlab.variableeditor.ArrayViewModel
    %TABLEVIEWMODEL
    %   Table View Model
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties
        MetaData = [];

        % Store the datetime formats to use.
        DTFormats string = strings(0);
        % Store the duration formats to use.
        DurFormats string = strings(0);
        isDateTimeFormatActionUpdate = false;
    end

    properties(Access='protected')
        ViewSize = [0 0];
        CurrentSize double = [];
        GroupedColumnCounts = [];
    end
    
    properties (SetObservable=true, SetAccess='protected', Transient)
        ColumnMetaDataChangedListener;
        RowMetaDataChangedListener;
    end
    
    properties (Constant)
        % Removed these because ArrayViewModel is now inheriting from
        % FormatDataUtils and these constant are now visible here
        %         MAX_DISPLAY_ELEMENTS = 11;
        %         MAX_DISPLAY_DIMENSIONS = 2;
    end
     
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = TableViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
            this.initListeners();
            this.setViewSize();
        end
        
        function [renderedData, renderedDims, editValues, startRow, endRow, startColumn, endColumn] = getRenderedData(...
            this, startRow, endRow, startColumn, endColumn)
            currentData = this.DataModel.Data;
            if ~isempty(currentData)
                [renderedData, renderedDims, metaData, editValues, startRow, endRow, startColumn, endColumn] = ...
                    this.formatDataBlock(startRow, endRow, startColumn, endColumn, currentData);
            else
                renderedDims = size(currentData);
                renderedData = cell(renderedDims);
                metaData = false(renderedDims);
                editValues = zeros(renderedDims);
            end
            this.MetaData = metaData;
        end

        function varargout = setTableDataValue(this, row, column, columnIndex, value, dispValue, evaluatedValue, errorMsg)
            lhs = this.DataModel.getLHSGrouped(sprintf('%d,%d',row,column),columnIndex, length(dispValue), evaluatedValue);
            setCommand = sprintf('%s = %s;',lhs,this.DataModel.getRHS(value));
            this.DataModel.executeSetCommand(setCommand, errorMsg);
            varargout{1} = setCommand;
        end

        
        function [vals, metaData] = parseCharColumn(this, currentData)
            metaData = false(size(currentData,1),1);
            strData = string(currentData);
            overCharMax = (strlength(strData) > internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH);
            missingStrs = ismissing(strData) & isstring(currentData); %cellstr does what we want for char, categorical and cellstr
            if isstring(currentData)
                colVal = cellstr("""" + currentData + """");
            elseif iscellstr(currentData)
                colVal = cellstr('''' + strData + '''');
            else
                colVal = cellstr(currentData);
            end
            colVal = strrep(colVal, char(0), ' '); % Replace null characters
            mStr = strtrim(evalc('disp(string(missing))'));
            if any(overCharMax) || any(missingStrs)
                % For any char/categorical over the MAX string length
                % we make it a summary string
                classStr = class(currentData);
                if iscellstr(currentData) %#ok<ISCLSTR>
                    classStr = 'char';
                end
                for row=1:size(currentData,1)
                    if overCharMax(row)
                        sizeStr = strjoin(split(num2str(size(currentData(row,:)))), this.TIMES_SYMBOL);
                        if iscellstr(currentData) %#ok<ISCLSTR>
                            sizeStr = strjoin(split(num2str(size(currentData{row,:}))), this.TIMES_SYMBOL);
                        end
                        
                        colVal{row} = [sizeStr ' ' classStr];
                        metaData(row) = true;
                    elseif missingStrs(row)
                        colVal{row} = mStr;
                        metaData(row) = true;
                    end
                end
            end
            vals = {colVal};
        end
        
        function vals = formatDatetime(~, r)
            vals = internal.matlab.datatoolsservices.FormatDataUtils.replaceNewLineWithWhiteSpace(r);
        end

        function [renderedData, renderedDims, editValues] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims, ~, editValues] = this.formatDataBlock(startRow, endRow, startColumn,endColumn, this.DataModel.Data);
        end

        % Helper function to retrieve start column indicies based on datatype
        function startColumnIdxs = getColumnStartIdxHelper(~, currentData, startColumn, endColumn)
            startColumnIdxs = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(currentData, startColumn, endColumn);
        end

        % Helper function to index data based on datatype
        function indexdata = indexDataHelper(~, currentdata, options)
            if isfield(options, 'gcolumn')
                if isfield(options, 'eRow')
                    indexdata = currentdata{:, options.column}(options.sRow:options.eRow, options.gcolumn);
                elseif isfield(options, 'Row')
                    indexdata = currentdata{:, options.column}{options.Row, options.gcolumn};
                else
                    indexdata = currentdata{:, options.column}(options.sRow, options.gcolumn);
                end
            else
                if isfield(options, 'sRow') && isfield(options, 'eRow')
                    indexdata = currentdata{options.sRow:options.eRow,options.column};
                else
                    indexdata = currentdata{:,options.column};
                end
            end
        end

        % Returns the right header name and correct data index for the given column index
        function [hName, actualColumnIndex] = getHeaderInfoFromIndex(this, columnIndex)
            arguments
                this
                columnIndex (1,1) double
            end
            variableNames = this.getHeaderNames();
            actualColumnIndex = columnIndex;
            if any(this.GroupedColumnCounts>1)
                [actualColumnIndex]=internal.matlab.variableeditor.TableViewModel.getNestedColumnRange(columnIndex,columnIndex,this.GroupedColumnCounts);
            end
            hName = variableNames{actualColumnIndex};
        end
        
        function [renderedData, renderedDims, metaData, editValues, sRow, eRow, sCol, eCol] = formatDataBlock(this,startRow,endRow,startColumn,endColumn,currentData, numDisplayFormat)
            arguments
                this;
                startRow double;
                endRow double;
                startColumn double;
                endColumn double;
                currentData;
                numDisplayFormat = this.DisplayFormatProvider.NumDisplayFormat;
            end
            renderedData = {};
            longDisplayFormat = this.DisplayFormatProvider.LongNumDisplayFormat;
            isDifferentLongFormat = ~strcmp(numDisplayFormat, longDisplayFormat);

            [sRow, eRow, sCol, eCol] = internal.matlab.datatoolsservices.FormatDataUtils.resolveRequestSizeWithObj(...
                startRow, endRow, startColumn, endColumn, this.getSize());

            editValues = zeros(eRow-sRow+1, eCol-sCol+1);

            actualStartColumn = sCol;
            actualEndColumn = eCol;
            dataIdx = 1;
            if ~isempty(this.GroupedColumnCounts)
                [gCols, startColIdx, endColIdx, dataIdx] = internal.matlab.variableeditor.TableViewModel.getColumnStartForRange(startColumn, endColumn, this.GroupedColumnCounts);
                actualStartColumn = startColIdx;
                actualEndColumn = endColIdx;
            else
                gCols = ones(1, actualEndColumn-actualStartColumn+1);
            end


            nGroupColumns = max(1, endColumn-startColumn + 1);
            numRows = eRow-sRow+1;
            vals = cell(1,nGroupColumns);
            metaData = false(numRows, nGroupColumns);
            formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();

            % Loop over actual columns indexes (not grouped)
            currentGrouppedColumn = 1;
            currentColumn = 1;
            for column=max(1,actualStartColumn):min(size(currentData,2),actualEndColumn)
                currColumn = currentData.(column);
                gColSize = gCols(currentColumn); % grouped column size

                sz = size(currColumn);
                % Nested tables usecase
                colClass = class(currColumn);
                groupColStart = 1;
                if dataIdx > 1
                    groupColStart = dataIdx;
                    dataIdx = 1;
                end

                groupColEnd = nGroupColumns-currentGrouppedColumn+1;
                groupColEnd = min(groupColStart + groupColEnd - 1, gColSize);
                % Loop over groupped columns
                for gcolumn=groupColStart:groupColEnd
                    if numel(sz) > 2 % Treat nD data as its own data type.
                        sz = sz(2:end); % The first dimension will be converted into the rows of the table.
                        vals{currentGrouppedColumn} = {this.makeNDSummaryString(sz, eRow - sRow + 1, colClass)};
                        metaData(:, currentGrouppedColumn) = true;
                    elseif any(strcmp(colClass, internal.matlab.variableeditor.MLUnsupportedDataModel.ForceUnsupported))
                        summary = internal.matlab.datatoolsservices.FormatDataUtils.getValueSummaryString(...
                            this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'gcolumn', gcolumn)), []);
                        vals{currentGrouppedColumn} = {repmat({summary}, eRow-sRow+1, 1)};
                        metaData(:,currentGrouppedColumn) = true;
                    elseif isa(currColumn, "matlab.mixin.CustomCompactDisplayProvider")
                        % We need to get the plain text representation for
                        % entire column.
                        currentColVal = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                        displayConfig = matlab.display.DisplayConfiguration("Columnar");
                        [formattedVal, isDimsAndClassName] = internal.matlab.datatoolsservices.FormatDataUtils.getCompactDisplayForData(currentColVal, displayConfig);
                        vals{currentGrouppedColumn} = {formattedVal};
                        metaData(:,currentGrouppedColumn) = isDimsAndClassName;
                    elseif isnumeric(currColumn)
                        currentCol = this.indexDataHelper(currentData, struct('column', column));
                        % For numeric objects, convert to numeric before
                        % formatting (g2044078)
                        currentCol = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(currentCol);
                        if (issparse(currentCol))
                            % Convert to str to get the string value of the
                            % sparse array and convert back to num.
                            % Indexing into sRow:eRow will not be accurate
                            % for char arrays
                            currentCol = str2num(num2str(currentCol));
                        end
                        if sRow == 0
                            % handle empty table
                            vals{currentGrouppedColumn} = '';
                        else
                            d = currentCol(sRow:eRow,gcolumn);
                            vals{currentGrouppedColumn} = {cellstr(matlab.internal.display.numericDisplay(currentCol(:,gcolumn), d, 'ScalarOutput', false, 'Format', numDisplayFormat, 'OmitScalingFactor', true))};
                            if isDifferentLongFormat
                                editValues(:,currentGrouppedColumn) = d;
                            end
                        end
                    elseif islogical(currColumn)
                        currentCol = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                        % String constructor converts logicals to true/false
                        formattedLogicals = string(currentCol);
                        vals{currentGrouppedColumn} = {formattedLogicals};
                    elseif istabular(currColumn) || isa(currColumn,'dataset')
                        % Nested tables show as 1 by the number of columns
                        % in the nested table, which must be the same for
                        % all rows of the table (so we can use repmat to
                        % create the data to display)
                        currSize = size(currColumn);
                        vals{currentGrouppedColumn} = {repmat(...
                            {['1' this.TIMES_SYMBOL num2str(currSize(2)) ' ' colClass]}, ...
                            eRow-sRow+1, 1)};
                        metaData(:,currentGrouppedColumn) = true;
                    elseif iscellstr(currColumn) ...
                            || internal.matlab.datatoolsservices.FormatDataUtils.checkIsString(currColumn) || ... %#ok<ISCLSTR>
                            iscategorical(currColumn) || ischar(currColumn)
                        % char array columns are not allowed to be grouped.
                        % if you try grouping, you will be prompted to use
                        % cell arrays. Fetch correct batch of currentData
                        % by indexing from sRow to eRow.
                        if size(currColumn,2)>1 && ...
                                (...
                                isstring(currentData{sRow:eRow,column}) ...
                                || iscategorical(currColumn) ...
                                || iscellstr(currColumn)...
                                )
                            data = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                        else
                            data = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow));
                        end
                        [vals{currentGrouppedColumn}, metaData(:,currentGrouppedColumn)] = this.parseCharColumn(data);
                    elseif isdatetime(currColumn)
                        dt = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                        if isempty(this.DTFormats) || (column > length(this.DTFormats)) || ismissing(this.DTFormats(column))
                            this.DTFormats(column) = currColumn.Format;
                        end
                        if ~strcmp(dt.Format, this.DTFormats(column))
                            if this.isDateTimeFormatActionUpdate
                                this.DTFormats(column) = dt.Format;
                            else
                                % Its possible when scrolling that the datetime format for the given page of data may be different
                                % than the datetime format used elsewhere (for example, dates with hours/minutes/seconds not all 
                                % zero will show with hh:mm:ss, while if they are all 0 may be shown without this).  When this 
                                % happens, stick with the longer format
                                if strlength(dt.Format) > strlength(this.DTFormats(column))
                                     this.DTFormats(column) = dt.Format;
                                end
                                dt.Format = this.DTFormats(column);
                            end
                        end
                        datestrings = cellstr(dt);
                        vals{currentGrouppedColumn} = {this.formatDatetime(datestrings)};
                    elseif isduration(currColumn) || iscalendarduration(currColumn)
                        dur = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                        % Save the durationFormats for the appropriate
                        % columns
                        if isempty(this.DurFormats) || (column > length(this.DurFormats)) || ismissing(this.DurFormats(column))
                            this.DurFormats(column) = dur.Format;
                        end
                        
                        datestrings = cellstr(this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn)));
                        vals{currentGrouppedColumn} = {this.formatDatetime(datestrings)};
                    elseif isstruct(currColumn) || ...
                            (isobject(currColumn) && ~iscategorical(currColumn)) ...
                            || isempty(meta.class.fromName(class(currColumn)))
                        vals{currentGrouppedColumn} = {repmat({['1' this.TIMES_SYMBOL '1 ' formatDataUtils.getClassString(currColumn, true)]}, eRow-sRow+1,1)};
                        metaData(:,currentGrouppedColumn) = true;
                    else
                        if isa(currentData, 'dataset')
                            table_tmp = internal.matlab.datatoolsservices.VariableUtils.convertDatasetToTable(currentData); %#ok<NASGU,NASGU>
                            r = evalc('disp(table_tmp{:,column}(sRow:eRow,gcolumn))');
                        else
                            r = evalc('disp(currentData{:,column}(sRow:eRow,gcolumn))');
                        end
                        vals{currentGrouppedColumn} = internal.matlab.variableeditor.peer.PeerDataUtils.parseCellColumn(r);
                        if iscell(currColumn)
                            currData = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                            % For these types, ensure that we show them as
                            % metadata display correctly. (g2047290)
                            [isSummaryValue, summaryValuesToExpand] = internal.matlab.datatoolsservices.FormatDataUtils.isSummaryValueForCellType(currData);

                            % We need to go through each cell and fix the
                            % disp value for non scalar values that fit our
                            % le MAX_DISPLAY_ELEMENTS elements and
                            % le MAX_DISPLAY_DIMENSIONS dimensions criteria
                            if (any(summaryValuesToExpand) || any(isSummaryValue))
                                c = vals{currentGrouppedColumn}{:};
                                displayConfig = matlab.display.DisplayConfiguration;
                                for row=sRow:eRow
                                    currentRow = row-sRow+1;
                                    currentCellVal = currData{currentRow};
                                    if isa(currentCellVal, "matlab.mixin.CustomCompactDisplayProvider")
                                        [formattedVal, isDimsAndClassName] = internal.matlab.datatoolsservices.FormatDataUtils.getCompactDisplayForData(currentCellVal, displayConfig);
                                        c{currentRow} = formattedVal;
                                        isSummaryValue(currentRow) = isDimsAndClassName;
                                    elseif isa(currentCellVal, 'function_handle') && isscalar(currentCellVal)
                                        formattedVal = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(currentCellVal, numDisplayFormat);
                                        c{currentRow} = formattedVal;
                                        isSummaryValue(currentRow) = false;
                                    elseif isscalar(currentCellVal) && internal.matlab.datatoolsservices.FormatDataUtils.isExpandableScalar(class(currentCellVal))
                                        % These data types even if scalar
                                        % should open in a new tab for
                                        % editing so should appear with
                                        % hyperlink look g3174987
                                        isSummaryValue(currentRow) = true;
                                    elseif summaryValuesToExpand(currentRow)
                                        %the disp for structures consists
                                        %of a hyperlink so we should not
                                        %use it directly
                                        d = currentCellVal;
                                        % Turn:  1 2
                                        %        3 4
                                        % Into: [1,2;3,4]
                                        %
                                        r=evalc('disp(d)');
                                        if ischar(d)
                                            if endsWith(r, newline)
                                                r = r(1:length(r)-1);
                                            end
                                            c{currentRow} =  ['''' r ''''];
                                            isSummaryValue(currentRow) = false;
                                        elseif isnumeric(d) && ~isobject(d)
                                            if isempty(d)
                                                c{currentRow} = '[]';
                                            else
                                                c{currentRow} = internal.matlab.datatoolsservices.FormatDataUtils.getNumericNonScalarValueDisplay(d, numDisplayFormat);
                                            end
                                            isSummaryValue(currentRow) = false;
                                        elseif isa(d, 'matlab.mixin.internal.MatrixDisplay')
                                            dSize = size(d);
                                            className = class(d);
                                            isExpandableScalar = internal.matlab.datatoolsservices.FormatDataUtils.isExpandableScalar(className);
                                            if isstring(d)
                                                strArray = internal.matlab.datatoolsservices.FormatDataUtils.strArrayParsing(d, dSize);
                                                c{currentRow} = sprintf('["%s"]', strArray);
                                            elseif isExpandableScalar
                                                % using isExpandableScalar
                                                % to check if the classname
                                                % falls under the
                                                % expandableArray classlist
                                                % These can be non-scalar
                                                % as well
                                                expandableArray = internal.matlab.datatoolsservices.FormatDataUtils.expandableArrayParsing(d, dSize);
                                                c{currentRow} = ['[' expandableArray ']'];
                                            else
                                                c{currentRow} = ['[' strjoin(strsplit(strjoin(strtrim(strsplit(strtrim(r),'\n')),';')),',') ']'];
                                            end
                                            % For arrays of these
                                            % expandable scalars they
                                            % should be tagged as meta
                                            % data so users can double
                                            % click to drill in and edit
                                            % individual values g3174987
                                            isSummaryValue(currentRow) = isExpandableScalar;
                                        else
                                            c{currentRow} = internal.matlab.datatoolsservices.FormatDataUtils.correctDimensionSpec(c{currentRow});
                                        end
                                    elseif isSummaryValue(currentRow)
                                        c{currentRow} = internal.matlab.datatoolsservices.FormatDataUtils.getValueSummaryString(currentCellVal, '');
                                    end
                                end
                                vals{currentGrouppedColumn} = {c};
                            end
                            metaData(:,currentGrouppedColumn) = isSummaryValue;
                        end
                    end
                    currentGrouppedColumn = currentGrouppedColumn +1;
                end
                currentColumn = currentColumn + 1;
            end

            if this.isDateTimeFormatActionUpdate
                % Setting this plugin flag to false since the plugin
                % action update should have ended
                this.isDateTimeFormatActionUpdate = false;
            end
            if ~isempty(vals)
                renderedData=[vals{:}];
                if ~isempty(renderedData)
                    renderedData=[renderedData{:}];
                end
            end
            renderedDims = size(renderedData);
            metaData = metaData(:,1:renderedDims(2));
        end
        
        % isEditable
        function editable = isEditable(this, row, col)
            % The cell is not editable if it contains MetaData (like "10x10
            % double").
            editable = ~this.MetaData(row, col);
        end

        function formattedString = getFormattedSelectionStringHelper(this, selectedRows, selectedColumns, ...
                 dataModelName, data)
            sz = this.getSize();
            formattedString = internal.matlab.variableeditor.TableViewModel.getFormattedSelectionString(selectedRows, ...
                selectedColumns, dataModelName, data, sz, min(sz(2), this.SelectedColumnIntervals), this.GroupedColumnCounts);
        end
        
        function varargout = getFormattedSelection(this, varargin)
            data = this.DataModel.Data;
            sz = this.getTabularDataSize();
            % If Selection extends to beyond table indices, access upto
            % table boundary size.
            selectedRows = this.SelectedRowIntervals;
            selectedColumns = this.SelectedColumnIntervals;
            if ~isempty(this.GroupedColumnCounts)
                selectedColumns = internal.matlab.variableeditor.TableViewModel.getColumnsFromSelectionString(this.SelectedColumnIntervals, this.GroupedColumnCounts);
            end

           % For empty tables, set empty SelectedRows and SelectedColumns as there is nothing to be formatted. 
            if isempty(data)
                selectedRows = [];
                selectedColumns = [];
            else
                selectedColumns = min(sz(2), selectedColumns);
                selectedRows = min(sz(1), selectedRows);
            end
            dataModelName = this.DataModel.Name;
            
            if isempty(selectedRows) || isempty(selectedColumns)
                varargout{1} = '';
            else
                varargout{1} = this.getFormattedSelectionStringHelper(selectedRows, ...
                    selectedColumns, dataModelName, data);
            end
        end

        % The ViewSize is computed once initially and whenever data
        % changes. This size includes flat column count (grouped column
        % indices and nested table indices in the future)
        function sz = getSize(this)
            sz = this.ViewSize;
        end

        function gcols = getGroupedColumnCounts(this)
            gcols = this.GroupedColumnCounts;
        end
        
        % Cleanup any listeners that were attached at constructor time
        function delete(this)
            if ~isempty(this.ColumnMetaDataChangedListener)
                delete(this.ColumnMetaDataChangedListener);
                this.ColumnMetaDataChangedListener = [];
            end
            if ~isempty(this.RowMetaDataChangedListener)
                delete(this.RowMetaDataChangedListener);
                this.RowMetaDataChangedListener = [];
            end
        end
    end
    
    methods(Access='protected')

        % Create a summary string for nD data consistent with what is
        % displayed when disp(<table>) is evaluated at the command line.
        %
        % For example, 2-by-3-by-4-by-5 datetime data would have a summary
        % value of 1x3x4x5 datetime in two rows.
        function summarString = makeNDSummaryString(this, size, numRows, class)
            summaryString = '1';
            for sz = size
                summaryString = [summaryString, this.TIMES_SYMBOL, num2str(sz)]; %#ok<AGROW>
            end
            summaryString = [summaryString, ' ', class];
            summarString = repmat({summaryString}, numRows, 1);
        end
        
        % Add listeners on DataModel and re-dispatch on ViewModel (With a
        % mixed in MetaDataStore)
        function initListeners(this)
            this.ColumnMetaDataChangedListener = event.listener(this.DataModel,'ColumnMetaDataChanged',@(es,ed) this.handleColumnMetaDataChangedOnDataModel(ed));
            this.RowMetaDataChangedListener = event.listener(this.DataModel,'RowMetaDataChanged',@(es,ed) this.handleRowMetaDataChangedOnDataModel(ed));
        end
        
        function handleRowMetaDataChangedOnDataModel(this, ed)
            this.notify('RowMetaDataChanged', ed);
        end

        % When DataModel detects column metadata change, reset viewsize
        function handleColumnMetaDataChangedOnDataModel(this, ed)
            % When column metadata changes as a result of size change, update viewsize and compute ed.Column if []. 
            % To refresh entire viewport, we want to compute Column on the updated size.
            this.setViewSize();
            if isempty(ed.Column)
                sz = this.getSize();
                ed.Column = [min(1, sz(2)), sz(2)];
            elseif ~isempty(this.GroupedColumnCounts)
                % Get View Indices to refresh the correct column range on
                % client.
                ed.Column = this.getViewIndexFromDataIndex(ed.Column, this.GroupedColumnCounts);
            end
            this.notify('ColumnMetaDataChanged', ed);
        end
        
        % Caches computed view size and grouped column indices if grouped columns exist.
        function setViewSize(this)
            % Cache current ViewSize before any updates
            this.CurrentSize = this.ViewSize;
            
            this.ViewSize = size(this.DataModel.Data);           
            
            % Cache grouped column indices after computing once
            gColStartIndices = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(this.DataModel.Data,1,this.ViewSize(2));
            this.GroupedColumnCounts = diff(gColStartIndices);
            gcolIndices = this.GroupedColumnCounts > 1;
            if (any(this.GroupedColumnCounts > 1))
                this.ViewSize(2) = this.ViewSize(2) + sum(this.GroupedColumnCounts(gcolIndices) - 1);
            else
                this.GroupedColumnCounts = []; 
            end
        end
    end
    
    methods(Static=true)
        function selectionString = getFormattedSelectionString(selectedRows, selectedColumns, dataModelName, data, dataSize, selectedViewColumns, gcolCounts)
            arguments
                selectedRows
                selectedColumns
                dataModelName
                data
                dataSize = size(data)
                selectedViewColumns = selectedColumns
                gcolCounts = []
            end
            import internal.matlab.variableeditor.TableDataModel;
            selectionRowString = '';
            selectionColString = '';
            if ~isempty(selectedRows) || ~isempty(selectedColumns)
                % selectedRows
                for i=1:size(selectedRows,1)
                    startRow = selectedRows(i,1);
                    endRow = selectedRows(i,2);
                    % For column selections with entire row selected(i.e a
                    % single selected rows range), selectionRowString is not computed.
                    if (endRow-startRow+1) == dataSize(1)
                        selectionRowString = '';
                    else
                        if i > 1
                            selectionRowString = [selectionRowString ',']; %#ok<AGROW>
                        end
                        if (startRow == endRow)
                            selectionRowString = [selectionRowString num2str(startRow)]; %#ok<AGROW>
                        else
                            % case when a range of subsequent fields are selected
                            selectionRowString = [selectionRowString num2str(startRow) ':' num2str(endRow)]; %#ok<AGROW>
                        end
                    end
                end
                % If we have more than one set of selctions, we need to
                % enclose the selection string in '[' and ']'
                if ~isempty(selectionRowString)
                    if size(selectedRows, 1) > 1
                        selectionRowString = ['([' selectionRowString '])'];
                    else
                        selectionRowString = ['(' selectionRowString ')'];
                    end
                end
                % selected Columns
                for i=1:size(selectedColumns,1)
                    if i > 1
                        selectionColString = [selectionColString ';']; %#ok<AGROW>
                    end
                    % case when individual disjoint fields are selected
                    if (selectedColumns(i,1) == selectedColumns(i,2))
                        % display string format in case of grouped column
                        currColumn = selectedColumns(i,1);
                        idxExp = matlab.internal.tabular.generateDotSubscripting(data,currColumn,'',true);
                        if ~isempty(gcolCounts) && gcolCounts(currColumn) > 1
                            colSubstr = internal.matlab.variableeditor.TableViewModel.getColumnSubstringForGroupedCol(selectedViewColumns(i,1),selectedViewColumns(i,2), currColumn, gcolCounts);
                            if ~isempty(selectionRowString)
                                rowString = [selectionRowString(1:length(selectionRowString)-1) ',' colSubstr ')'];
                                selectionColString = [selectionColString dataModelName idxExp rowString]; %#ok<AGROW>
                            elseif ~isequal(colSubstr, ':')
                                selectionColString = [selectionColString dataModelName idxExp ['(:,' colSubstr ')']]; %#ok<AGROW>                    
                            else
                                selectionColString = [selectionColString dataModelName idxExp selectionRowString]; %#ok<AGROW>
                            end                          
                            % For scalars or row vectors, directly index by
                            % variable name. (This works out for objects like curve fitting that do not allow row indexing.)
                        elseif dataSize(1) == 1
                            selectionColString = [selectionColString dataModelName idxExp]; %#ok<AGROW>
                        else
                            selectionColString = [selectionColString dataModelName idxExp selectionRowString]; %#ok<AGROW>
                        end
                    else
                        % case when a range of subsequent fields are selected
                        k=1;
                        viewColRange = [selectedViewColumns(i,1) selectedViewColumns(i,2)];
                        for j=(selectedColumns(i,1)):(selectedColumns(i,2))
                            if j > selectedColumns(i,1)
                                selectionColString = [selectionColString ';']; %#ok<AGROW>
                            end
                            % display string format in case of grouped column
                            idxExp = matlab.internal.tabular.generateDotSubscripting(data,j,'',true);
                            if ~isempty(gcolCounts) && gcolCounts(j) > 1
                                colSubstr = internal.matlab.variableeditor.TableViewModel.getColumnSubstringForGroupedCol(viewColRange(1), viewColRange(2), j, gcolCounts);
                                if ~isempty(selectionRowString)
                                    rowString = [selectionRowString(1:length(selectionRowString)-1) ',' colSubstr ')'];
                                    selectionColString = [selectionColString dataModelName idxExp rowString]; %#ok<AGROW>
                                elseif ~isequal(colSubstr, ':')
                                    selectionColString = [selectionColString dataModelName idxExp ['(:,' colSubstr ')']]; %#ok<AGROW>                    
                                else
                                    selectionColString = [selectionColString dataModelName idxExp selectionRowString]; %#ok<AGROW>
                                end
                                % For scalars or row vectors, directly index by
                                % variable name. (This works out for objects like curve fitting that do not allow row indexing.)
                            elseif dataSize(1) == 1
                                selectionColString = [selectionColString dataModelName idxExp]; %#ok<AGROW>
                            else
                                selectionColString = [selectionColString dataModelName idxExp selectionRowString]; %#ok<AGROW>
                            end
                            k=k+1;
                        end
                    end
                end
            end
            selectionString = selectionColString;
        end

        % From a view level selection (that can span multiple columns),
        % returns the column string for the current grouped column (dataIdx)
        function colSubstring = getColumnSubstringForGroupedCol(viewColStart, viewColEnd, dataIdx, gcolCounts)
            viewIndicesInCol = internal.matlab.variableeditor.TableViewModel.getViewIndexFromDataIndex(dataIdx, gcolCounts);
            currgcolSelection = intersect(viewColStart:viewColEnd, viewIndicesInCol);
            numCols = length(currgcolSelection);
            [~,~,offsetIdx] = internal.matlab.variableeditor.TableViewModel.getNestedColumnRange(currgcolSelection(1),currgcolSelection(end), gcolCounts);
            % case: all sub-columns within the grouped column are selected
            if (numCols == gcolCounts(dataIdx))
                colSubstring = ':';
            % case: only a single sub-column is selected
            elseif numCols == 1
                colSubstring = mat2str(offsetIdx);
            else
            % case: selection spans multiple sub-columns
                colSubstring = [mat2str(offsetIdx(1)) ':' mat2str(offsetIdx(1)+numCols-1)];
            end
        end

        % This returns the current column selection adjusted for grouped columns
        % For e.g if we have a table with 2 grouped columns, flatColumnCounts must be [2 2].
        % For selection [1 4], selectedIndices = [2 2]
        function selectedIndices = getColumnsFromSelectionString(selection, flatColumnCounts)
            selectedIndices = selection;
            for i=1:height(selection)
                colRange = selection(i,:);
                [colStart, colEnd] = internal.matlab.variableeditor.TableViewModel.getNestedColumnRange(colRange(1), colRange(2), flatColumnCounts);
                if ~isempty(colStart) && ~isempty(colEnd)
                    selectedIndices(i,:) = [colStart colEnd];
                else
                    selectedIndices(i,:) = [];
                end
            end
        end

        % This returns the current expanded column selection to be sent to
        % the view with given dataindices. 
        % if columnCounts = [1 5 1], dataIndices = [2 3], viewIndices = [2 3 4 5 6 7]
        function viewIndices = getViewIndexFromDataIndex(dataIndices, columnCounts)
            offsetIdx = cumsum(columnCounts);
            viewIndices = offsetIdx(dataIndices);
            nestedCounts = columnCounts(dataIndices);
            for i=find(nestedCounts>1)
                expansion = (viewIndices(i)-nestedCounts(i)+1):viewIndices(i);
                viewIndices = unique([viewIndices expansion]);
            end
        end
        
        % Computes GroupedColumn StartIndices for the table. This is
        % computed once and cached. For e.g if currentData =
        % table(rand(5)), startColumnIndexes = [1 6]
        function startColumnIndexes = getColumnStartIndicies(currentData, startColumn, endColumn)
            % Ensure that each column contains at least one column. (Entries
            % in startColumnIndexes must be strictly greater than the
            % preceding value.
            startColumnIndexes = internal.matlab.datatoolsservices.VariableUtils.getColumnStartIndicies(...
            	currentData(:,max(1,startColumn):min(size(currentData,2),endColumn)));
        end

        % Given startColumn,endColumn and nestedTableIndices(flat column count of each variable), this API returs the abolsute column. 
        % If nestedTableIndices = [5 5 5], and startColumn = 7, endColumn = 9, API returns:
        % [actualStartColumn = 2, actualEndColumn = 2, currentStartIndex = 2 (second sub-column within the current column)] 
        function [actualStartColumn, actualEndColumn, currentStartIndex] = getNestedColumnRange(startColumn, endColumn, nestedTableIndices)
            sumIndices = cumsum(nestedTableIndices);
            actualStartColumn = find(sumIndices >= startColumn, 1, 'first');
            actualEndColumn = find(sumIndices >= endColumn, 1, 'first');
            start = 1;
            currentStartIndex = 1;
            if (nestedTableIndices(actualStartColumn) > 1)
                if (actualStartColumn > 1)
                    start = sumIndices(actualStartColumn - 1);
                    if startColumn > start + 1
                        currentStartIndex = startColumn - start;
                    end
                else
                    currentStartIndex = startColumn;
                end
            end
        end
        
        % Given startColumn,endColumn and gColIndices(number of gcolumns in each column), this API returs the abolsute column. 
        % If gColIndices = [5 1 4], and startColumn = 6, endColumn = 9, API returns:
        % [gColRange = [1 4], startColumnIndex = 2, endColumnIndex = 3, currentStartIndex = 1 (beginning of second column)] 
        function [gColRange, startColumnIndex, endColumnIndex, currentStartIndex] = getColumnStartForRange(startColumn, endColumn, gcols)
            [startColumnIndex, endColumnIndex, currentStartIndex] = internal.matlab.variableeditor.TableViewModel.getNestedColumnRange(startColumn, endColumn, gcols);
            gColRange = gcols(startColumnIndex:endColumnIndex);
        end
        
        % For the given data, returns the row dimension names (RowNames | RowTimes)
        function rows = getRowDimNames(data)
            rows = [];
            if isa(data, "table")
                rows = data.Properties.RowNames;
            elseif isa(data, "timetable")
                rows = data.Properties.RowTimes;
            end
        end
    end
end
