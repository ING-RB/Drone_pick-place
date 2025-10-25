classdef SpannedTableViewModel < internal.matlab.variableeditor.TableViewModel
    %TABLEVIEWMODEL
    %   Table View Model
    
    % Copyright 2023-2024 The MathWorks, Inc

    properties (Access='protected')
        GroupCounts double = []
        isRowDim logical = [];
    end

     
    % Public Abstract Methods
    methods(Access='public')     
        

        % Helper function to retrieve start column indicies based on datatype
        function startColumnIdxs = getColumnStartIdxHelper(~, currentData, startColumn, endColumn)
            startColumnIdxs = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(currentData, startColumn, endColumn);
        end
        
        function [renderedData, renderedDims, metaData, editValues, sRow, eRow, sCol, eCol] = formatDataBlock(this,startRow,endRow,startColumn,endColumn,currentData, numDisplayFormat, groupedColumnCounts)
            arguments
                this;
                startRow double;
                endRow double;
                startColumn double;
                endColumn double;
                currentData;
                numDisplayFormat = this.DisplayFormatProvider.NumDisplayFormat;
                groupedColumnCounts = this.GroupedColumnCounts
            end
            renderedData = {};
            longDisplayFormat = this.DisplayFormatProvider.LongNumDisplayFormat; 
            isDifferentLongFormat = ~strcmp(numDisplayFormat, longDisplayFormat);
            
            [sRow, eRow, sCol, eCol] = internal.matlab.datatoolsservices.FormatDataUtils.resolveRequestSizeWithObj(...
                startRow, endRow, startColumn, endColumn, this.getSize());
            

            actualStartColumn = sCol;
            actualEndColumn = eCol;
            dataIdx = 1;
            nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(currentData);
            hasGrouped = ~isempty(groupedColumnCounts);
            if ~hasGrouped
                groupedColumnCounts = ones(1, actualEndColumn-actualStartColumn+1);
            end
            hasNested = any(nestedTableIndices > 1);
            gCols = [];
            if hasGrouped || hasNested
                if hasGrouped && hasNested
                    cummCount = (groupedColumnCounts + nestedTableIndices) -1;             
                elseif hasNested 
                    cummCount = nestedTableIndices;
                else   
                    cummCount = groupedColumnCounts;
                end
                gcolCountsForIndexing = [];
                if hasGrouped 
                    gcolCountsForIndexing = groupedColumnCounts;
                end
                [gCols, startColIdx, endColIdx, dataIdx] = internal.matlab.variableeditor.SpannedTableViewModel.getColumnStartForRange(startColumn, endColumn, cummCount, gcolCountsForIndexing);
                actualStartColumn = startColIdx;
                actualEndColumn = endColIdx;
                currentDataIndex = dataIdx;
            end

            if isempty(gCols)
                gCols = groupedColumnCounts;
            end
            
            nGroupColumns = max(1, endColumn-startColumn + 1);
            numRows = eRow-sRow+1;
            vals = cell(1,nGroupColumns);
            metaData = false(numRows, nGroupColumns);
            editValues = zeros(numRows, nGroupColumns);

            formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
            % Loop over actual columns indexes (not grouped)
            currentGrouppedColumn = 1;
            currentColumn = 1;
            for column=max(1,actualStartColumn):min(size(currentData,2),actualEndColumn)
                currColumn = currentData.(column);
                gColSize = gCols(currentColumn); % grouped column size

                sz = size(currColumn);
                % Nested tables usecase
                if istabular(currColumn)
                    nestedCols = nestedTableIndices(column);
                    nestedColsAvailable = nestedCols - currentDataIndex + 1; % Cols that can be fetched in current nesting
                    nestedEndCol = min(nGroupColumns-currentGrouppedColumn+1, nestedColsAvailable);
                    startCol = currentDataIndex;
                    endCol = currentDataIndex+nestedEndCol-1;
                    gcols = [];
                    [~, gcolumnCount, origSize, ~] = internal.matlab.variableeditor.SpannedTableViewModel.getTableFlatSize(currColumn);
                    if gcolumnCount > origSize(2)
                        gColStartIndices = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(currColumn,1,origSize(2));
                        gcols = diff(gColStartIndices);
                    end
                    [nestedRenderedData, nestedRenderedDims, nestedMetaData, nestedEditValues] = this.formatDataBlock(startRow,endRow,startCol,endCol,currColumn, numDisplayFormat, gcols);
                    rowNames = internal.matlab.variableeditor.SpannedTableViewModel.getRowDimNames(currColumn);
                    cCol = currentGrouppedColumn;
                    if currentDataIndex == 1 && ~isempty(rowNames) 
                        rowNamesStr = cellstr(rowNames(startRow:endRow));
                        if isdatetime(rowNames) || isduration(rowNames) || iscalendarduration(rowNames)
                            rowNamesStr = this.formatDatetime(rowNamesStr);
                        end
                        vals{cCol} = {rowNamesStr};
                        cCol = cCol + 1;
                    end
                    currentDataIndex = 1;
                    for i=1:nestedRenderedDims(2)
                        vals{cCol+i-1} = {nestedRenderedData(:,i)};
                    end
                    metaData(:,cCol:cCol+nestedRenderedDims(2)-1)= nestedMetaData;
                    editValues(:,cCol:cCol+nestedRenderedDims(2)-1)= nestedEditValues;
                    currentGrouppedColumn = currentGrouppedColumn + nestedEndCol;
                else
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
                        % disp("GroupedColumn::" + num2str(gcolumn));
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
                                vals{currentGrouppedColumn} = {cellstr(matlab.internal.display.numericDisplay(d, d, 'ScalarOutput', false, 'Format', numDisplayFormat, 'OmitScalingFactor', true))};
                                if isDifferentLongFormat
                                    editValues(:,currentGrouppedColumn) = d;
                                end
                            end
                        elseif islogical(currColumn)
                            currentCol = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                            % String constructor converts logicals to true/false
                            formattedLogicals = string(currentCol);
                            vals{currentGrouppedColumn} = {formattedLogicals};
                        elseif istable(currentData.(column)) || isa(currentData.(column),'dataset')
                            % Nested tables show as 1 by the number of columns
                            % in the nested table, which must be the same for
                            % all rows of the table (so we can use repmat to
                            % create the data to display)
                            currSize = size(currentData.(column));
                            vals{currentGrouppedColumn} = {repmat(...
                                {['1' this.TIMES_SYMBOL num2str(currSize(2)) ' ' colClass]}, ...
                                eRow-sRow+1, 1)};
                            metaData(:,currentGrouppedColumn) = true;
                        elseif ischar(currentData.(column)) || iscategorical(currentData.(column)) ...
                                || iscellstr(currentData.(column)) ...
                                || internal.matlab.datatoolsservices.FormatDataUtils.checkIsString(currentData.(column)) %#ok<ISCLSTR>
                            % char array columns are not allowed to be grouped.
                            % if you try grouping, you will be prompted to use
                            % cell arrays. Fetch correct batch of currentData
                            % by indexing from sRow to eRow.
                            if size(currentData.(column),2)>1 && ...
                                    (...
                                    isstring(currentData{sRow:eRow,column}) ...
                                    || iscategorical(currentData.(column)) ...
                                    || iscellstr(currentData.(column))...
                                    )
                                data = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                            else
                                data = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow));
                            end
                            [vals{currentGrouppedColumn}, metaData(:,currentGrouppedColumn)] = this.parseCharColumn(data);
                        elseif isdatetime(currentData.(column)) 
                            dt = this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn));
                            if isempty(this.DTFormats) || (column > length(this.DTFormats)) || ismissing(this.DTFormats(column))
                                this.DTFormats(column) = currentData.(column).Format;
                            end
                            if ~strcmp(dt.Format, this.DTFormats(column))
                                % Its possible when scrolling that the datetime format for the given page of data may be different
                                % than the datetime format used elsewhere (for example, dates with hours/minutes/seconds not all 
                                % zero will show with hh:mm:ss, while if they are all 0 may be shown without this).  When this 
                                % happens, stick with the longer format.
                                if strlength(dt.Format) > strlength(this.DTFormats(column))
                                    this.DTFormats(column) = dt.Format;
                                end
                                dt.Format = this.DTFormats(column);
                            end
                            datestrings = cellstr(dt);
                            vals{currentGrouppedColumn} = {this.formatDatetime(datestrings)};
                        elseif isduration(currentData.(column)) || iscalendarduration(currentData.(column))
                            datestrings = cellstr(this.indexDataHelper(currentData, struct('column', column, 'sRow', sRow, 'eRow', eRow, 'gcolumn', gcolumn)));
                            vals{currentGrouppedColumn} = {this.formatDatetime(datestrings)};
                        elseif isstruct(currentData.(column)) || ...
                                (isobject(currentData.(column)) && ~iscategorical(currentData.(column))) ...
                                || isempty(meta.class.fromName(class(currentData.(column))))
                            vals{currentGrouppedColumn} = {repmat({['1' this.TIMES_SYMBOL '1 ' formatDataUtils.getClassString(currentData.(column), true)]}, eRow-sRow+1,1)};
                            metaData(:,currentGrouppedColumn) = true;
                        else
                            if isa(currentData, 'dataset')
                                table_tmp = internal.matlab.datatoolsservices.VariableUtils.convertDatasetToTable(currentData); %#ok<NASGU,NASGU>
                                r = evalc('disp(table_tmp{:,column}(sRow:eRow,gcolumn))');
                            else
                                r = evalc('disp(currentData{:,column}(sRow:eRow,gcolumn))');
                            end
                            vals{currentGrouppedColumn} = internal.matlab.variableeditor.peer.PeerDataUtils.parseCellColumn(r);
                            if iscell(currentData.(column))
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
                                        currentCellVal = this.indexDataHelper(currentData, struct('column', column, 'Row', row, 'gcolumn', gcolumn));
                                        if isa(currentCellVal, "matlab.mixin.CustomCompactDisplayProvider")
                                            [formattedVal, isDimsAndClassName] = internal.matlab.datatoolsservices.FormatDataUtils.getCompactDisplayForData(currentCellVal, displayConfig);
                                            c{currentRow} = formattedVal;
                                            isSummaryValue(currentRow) = isDimsAndClassName; 
                                        elseif isa(currentCellVal, 'function_handle') && isscalar(currentCellVal)
                                            formattedVal = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(currentCellVal, numDisplayFormat);
                                            c{currentRow} = formattedVal;
                                            isSummaryValue(currentRow) = false;
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
                                            elseif isnumeric(d)
                                                if isempty(d)
                                                    c{currentRow} = '[]';
                                                else
                                                    c{currentRow} = internal.matlab.datatoolsservices.FormatDataUtils.getNumericNonScalarValueDisplay(d, numDisplayFormat);
                                                end
                                                isSummaryValue(currentRow) = false;
                                            elseif isa(d, 'matlab.mixin.internal.MatrixDisplay')
                                                dSize = size(d);
                                                className = class(d);
                                                if isstring(d)
                                                    strArray = internal.matlab.datatoolsservices.FormatDataUtils.strArrayParsing(d, dSize);
                                                    c{currentRow} = sprintf('["%s"]', strArray);
                                                elseif internal.matlab.datatoolsservices.FormatDataUtils.isExpandableScalar(className)
                                                    % using isExpandableScalar
                                                    % to check if the classname
                                                    % falls under the
                                                    % expandableArray classlist
                                                    % These can be non-scalar as well
                                                    expandableArray = internal.matlab.datatoolsservices.FormatDataUtils.expandableArrayParsing(d, dSize);
                                                    c{currentRow} = ['[' expandableArray ']'];
                                                else
                                                    c{currentRow} = ['[' strjoin(strsplit(strjoin(strtrim(strsplit(strtrim(r),'\n')),';')),',') ']'];
                                                end
                                                isSummaryValue(currentRow) = false;
                                            end
                                        elseif isSummaryValue(currentRow)
                                            c{currentRow} = internal.matlab.datatoolsservices.FormatDataUtils.getValueSummaryString(this.indexDataHelper(currentData, struct('column', column, 'Row', row, 'gcolumn', gcolumn)), '');
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

            end
            if ~isempty(vals)
                renderedData=[vals{:}];
                if ~isempty(renderedData)
                    renderedData=[renderedData{:}];
                end
            end
            renderedDims = size(renderedData);
            metaData = metaData(:,1:renderedDims(2));
            editValues = editValues(:,1:renderedDims(2));
        end

        % Returns the right header name for the given column index
        function [hName, actualColumnIndex] = getHeaderInfoFromIndex(this, columnIndex)
            arguments
                this
                columnIndex (1,1) double
            end
            variableNames = this.getHeaderNames();
            actualColumnIndex = columnIndex;
            nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(this.DataModel.Data);
            if any(nestedTableIndices > 1)
                [actualColumnIndex]=internal.matlab.variableeditor.SpannedTableViewModel.getNestedColumnRange(columnIndex,columnIndex,nestedTableIndices);
            elseif any(this.GroupedColumnCounts>1)
                [actualColumnIndex]=internal.matlab.variableeditor.SpannedTableViewModel.getNestedColumnRange(columnIndex,columnIndex,this.GroupedColumnCounts);
            end
            hName = variableNames{actualColumnIndex};
        end
    end
    
    methods(Access='protected')
        
        % Caches computed view size and grouped column indices if grouped
        % columns exist
        function setViewSize(this)
            [sz, gcolumnCount, origSize, totalGroupCounts] = internal.matlab.variableeditor.SpannedTableViewModel.getTableFlatSize(this.DataModel.Data);
            this.ViewSize = sz;
            % Cache grouped column indices after computing once
            if gcolumnCount > origSize(2)
                gColStartIndices = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(this.DataModel.Data,1,origSize(2));
                this.GroupedColumnCounts = diff(gColStartIndices);
            else
                this.GroupedColumnCounts = [];
            end
            % This is a cache that includes group counts + nested table counts
            if (any(totalGroupCounts > 1))
                this.GroupCounts = totalGroupCounts;
            end
        end
    end
    
    methods(Static=true)
        function selectionString = getFormattedSelectionString(selectedRows, selectedColumns, dataModelName, data, dataSize)
            import internal.matlab.variableeditor.TableDataModel;
            if (nargin < 6)
                dataSize = size(data);
            end
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
                        idxExp = matlab.internal.tabular.generateDotSubscripting(data,selectedColumns(i,1),'',true);
                        groupedColumn = eval(['data' idxExp]);
                        if size(groupedColumn, 2) > 1 && ~isempty(selectionRowString)
                            selectionRowString = [selectionRowString(1:length(selectionRowString)-1) ',:)'];
                            selectionColString = [selectionColString dataModelName idxExp selectionRowString]; %#ok<AGROW>
                            % For scalars or row vectors, directly index by
                            % variable name. (This works out for objects like curve fitting that do not allow row indexing.)
                        elseif dataSize(1) == 1
                            selectionColString = [selectionColString dataModelName idxExp]; %#ok<AGROW>
                        else
                            selectionColString = [selectionColString dataModelName idxExp selectionRowString]; %#ok<AGROW>
                        end
                    else
                        % case when a range of subsequent fields are selected
                        for j=(selectedColumns(i,1)):(selectedColumns(i,2))
                            if j > selectedColumns(i,1)
                                selectionColString = [selectionColString ';']; %#ok<AGROW>
                            end
                            % display string format in case of grouped column
                            idxExp = matlab.internal.tabular.generateDotSubscripting(data,j,'',true);
                            groupedColumn = eval(['data' idxExp]);
                            if size(groupedColumn, 2) > 1 && ~isempty(selectionRowString)
                                selectionRowString = [selectionRowString(1:length(selectionRowString)-1) ',:)'];
                                selectionColString = [selectionColString dataModelName idxExp selectionRowString]; %#ok<AGROW>
                                % For scalars or row vectors, directly index by
                                % variable name. (This works out for objects like curve fitting that do not allow row indexing.)
                            elseif dataSize(1) == 1
                                selectionColString = [selectionColString dataModelName idxExp]; %#ok<AGROW>
                            else
                                selectionColString = [selectionColString dataModelName idxExp selectionRowString]; %#ok<AGROW>
                            end
                        end
                    end
                end
            end
            selectionString = selectionColString;
        end

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

        function [gColRange, startColumnIndex, endColumnIndex, currentStartIndex] = getColumnStartForRange(startColumn, endColumn, cummColumnCounts, gcols)
            arguments
                startColumn double
                endColumn double
                cummColumnCounts double
                gcols double = []
            end
            [startColumnIndex, endColumnIndex, currentStartIndex] = internal.matlab.variableeditor.TableViewModel.getNestedColumnRange(startColumn, endColumn, cummColumnCounts);
            gColRange = [];
            if ~isempty(gcols)
                gColRange = gcols(startColumnIndex:endColumnIndex);
            end         
        end

        function [sz, gcolCount, origSize, totalGroupCounts] = getTableFlatSize(data)
            origSize = size(data);
            [columns, gcolCount, totalGroupCounts] = internal.matlab.variableeditor.SpannedTableViewModel.getTableFlatColumnCount(data);
            sz = [origSize(1), columns];
        end


        % Adds all grouped columns 
        function [colCount, gcolCount, groupCounts] = getTableFlatColumnCount(data, gcolCount)
            arguments
                data {mustBeA(data, ["table", "timetable"])}
                gcolCount = 0
            end
            function varSz = getVariableSize(var)
                if istabular(var)
                    [varSz, currGColCount] = internal.matlab.variableeditor.SpannedTableViewModel.getTableFlatColumnCount(var, 0);
                    % If grouped columns in nested table exist, add to
                    % overall grouped column count
                    % Account for chars
                    if (currGColCount > size(var, 2))
                        gcolCount = gcolCount + currGColCount;
                    else
                        gcolCount = gcolCount + 1;
                    end
                    rows = internal.matlab.variableeditor.SpannedTableViewModel.getRowDimNames(var);
                    if ~isempty(rows)
                        varSz = varSz + 1;
                    end
                else
                    % Accounting for grouped columns.
                    if ~ischar(var)
                        varSz = size(var, 2);
                    else
                        varSz = 1;
                    end
                    gcolCount = gcolCount + varSz;
                end
            end
            groupCounts = varfun(@getVariableSize, data, "OutputFormat", "uniform");
            colCount = sum(groupCounts);
        end

        function [tableVarCount] = findNestedTableInfo(data)
            arguments
                data
            end
            function count = getFlatVarCount(var, count)
                if istabular(var)      
                    tablSz = varfun(@(x)getFlatVarCount(x,0), var, "OutputFormat", "uniform");
                    count = count + sum(tablSz);
                    rows = internal.matlab.variableeditor.SpannedTableViewModel.getRowDimNames(var);
                    if ~isempty(rows)
                        count = count + 1;
                    end
                else
                    count = 1;
                end
            end
            tableVarCount = varfun(@(x)getFlatVarCount(x,0), data, "OutputFormat", "uniform");
        end

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
