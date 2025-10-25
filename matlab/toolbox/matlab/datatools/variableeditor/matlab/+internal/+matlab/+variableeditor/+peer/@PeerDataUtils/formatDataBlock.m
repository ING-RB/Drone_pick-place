% Formats a data block

% Copyright 2017-2024 The MathWorks, Inc.

function [renderedData, renderedDims, metaData] = formatDataBlock(startRow, endRow, startColumn, endColumn, currentData, nestedTableIndices, gColIndices, fullDTFormats)
    arguments
        startRow
        endRow
        startColumn
        endColumn
        currentData
        nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(currentData)
        gColIndices = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(currentData,1,endColumn)
        fullDTFormats = strings(1,endColumn); 
    end
    import internal.matlab.variableeditor.peer.PeerDataUtils;
    TIMES_SYMBOL = internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL;
    renderedData = {};
    actualStartColumn = startColumn;
    actualEndColumn = endColumn;
    nGroupColumns = max(1,endColumn-startColumn+1);
    numRows = endRow-startRow+1;
    vals = cell(1,nGroupColumns);
    metaData = false(numRows, nGroupColumns);
    if numRows < 1
        renderedDims = [0 0];
        return;
    end
    formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
    gcolCounts = diff(gColIndices);
    hasGrouped = any(gcolCounts > 1);
    hasNested = any(nestedTableIndices > 1);
    if hasGrouped || hasNested
        if hasGrouped && hasNested
            cummCount = (gcolCounts + nestedTableIndices) -1;
        elseif hasNested
            cummCount = nestedTableIndices;
        else
            cummCount = gcolCounts;
        end
        [~, startColIdx, endColIdx, ~] = internal.matlab.variableeditor.SpannedTableViewModel.getColumnStartForRange(startColumn, endColumn, cummCount, gcolCounts);
        actualStartColumn = startColIdx;
        actualEndColumn = endColIdx;
    end
    startColumnIndexes = gColIndices;

    % Loop over actual columns indexes (not grouped or nested)
    currentGrouppedColumn = 1;
    for column=max(1,actualStartColumn):min(size(currentData,2),actualEndColumn)
        currColumn = currentData.(column);
        if istabular(currColumn)
            nestedEndCol = min(nGroupColumns-currentGrouppedColumn+1, nestedTableIndices(column)); % Cols that can be fetched in current nesting

            [nestedRenderedData, nestedRenderedDims, nestedMetaData] = internal.matlab.variableeditor.peer.PeerDataUtils.formatDataBlock(startRow,endRow,1,nestedEndCol,currColumn);
            rowNames = internal.matlab.variableeditor.SpannedTableViewModel.getRowDimNames(currColumn);
            cCol = currentGrouppedColumn;
            nestedMetaData = nestedMetaData(:,1:nestedRenderedDims(2));
            if ~isempty(rowNames)
                vals{cCol} = {cellstr(rowNames(startRow:endRow))};
                cCol = cCol + 1;
            end
            for i=1:nestedRenderedDims(2)
                vals{cCol+i-1} = {nestedRenderedData(:,i)};
            end
            metaData(:,cCol:cCol+nestedRenderedDims(2)-1)= nestedMetaData;
            currentGrouppedColumn = currentGrouppedColumn + nestedEndCol;
        else
            colClass = class(currColumn);
            groupColStart = startColumnIndexes(column);
            groupColEnd = startColumnIndexes(column+1);
            % Loop over grouped columns
            for gcolumn=1:(groupColEnd-groupColStart)
                sz = size(currColumn);
                if numel(sz) > 2 % Treat nD data as its own data type.
                    sz = sz(2:end); % The first dimension will be converted into the rows of the table.
                    vals{currentGrouppedColumn} = {PeerDataUtils.makeNDSummaryString(sz, endRow - startRow + 1, colClass)};
                    metaData(:, currentGrouppedColumn) = true;
                elseif any(strcmp(colClass, internal.matlab.variableeditor.MLUnsupportedDataModel.ForceUnsupported))
                    summary = internal.matlab.datatoolsservices.FormatDataUtils.getValueSummaryString(...
                        currentData{:, column}(startRow, gcolumn), []);
                    vals{currentGrouppedColumn} = {repmat({summary}, endRow-startRow+1, 1)};
                    metaData(:,currentGrouppedColumn) = true;
                elseif isa(currentData.(column), "matlab.mixin.CustomCompactDisplayProvider")
                    % We need to get the plain text representation for entire
                    % column.
                    currentColVal = currentData{:, column}(startRow:endRow, gcolumn);
                    displayConfig = matlab.display.DisplayConfiguration("Columnar");
                    [formattedVal, isDimsAndClassName] = internal.matlab.datatoolsservices.FormatDataUtils.getCompactDisplayForData(currentColVal, displayConfig);
                    vals{currentGrouppedColumn} = {formattedVal};
                    metaData(:,currentGrouppedColumn) = isDimsAndClassName;
                elseif isnumeric(currentData.(column))
                    currentCol = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(currentData{:,column});
                    if (issparse(currentCol))
                        % Convert to str to get the string value of the sparse
                        % array and convert back to num. Indexing into sRow:eRow
                        % will not be accurate for char arrays
                        currentCol = str2num(num2str(currentCol)); %#ok<ST2NM>
                    end

                    if startRow == 0
                        % handle empty table
                        vals{currentGrouppedColumn} = '';
                    else
                        d = currentCol(startRow:endRow,gcolumn);
                        vals{currentGrouppedColumn} = {cellstr(matlab.internal.display.numericDisplay(currentCol(:,gcolumn), d, 'ScalarOutput', false, 'OmitScalingFactor', true))};
                    end
                elseif islogical(currColumn)
                    currentCol = currentData{:, column}(startRow:endRow, gcolumn);
                    % String constructor converts logicals to true/false
                    formattedLogicals = string(currentCol);
                    vals{currentGrouppedColumn} = {formattedLogicals};
                elseif istable(currentData.(column)) || isa(currentData.(column),'dataset')
                    % Nested tables show as 1 by the number of columns in the
                    % nested table, which must be the same for all rows of the
                    % table (so we can use repmat to create the data to display)
                    currSize = size(currentData.(column));
                    vals{currentGrouppedColumn} = {repmat(...
                        {['1' TIMES_SYMBOL num2str(currSize(2)) ' ' colClass]}, ...
                        endRow-startRow+1, 1)};
                    metaData(:,currentGrouppedColumn) = true;
                elseif ischar(currentData.(column)) || iscategorical(currentData.(column)) ...
                        || iscellstr(currentData.(column)) ...
                        || formatDataUtils.checkIsString(currentData.(column)) %#ok<ISCLSTR>
                    % char array columns are not allowed to be grouped. if you
                    % try grouping, you will be prompted to use cell arrays.
                    % Fetch correct batch of currentData by indexing from sRow
                    % to eRow.
                    if size(currentData.(column),2)>1 && ...
                            (...
                            isstring(currentData{startRow:endRow,column}) ...
                            || iscategorical(currentData.(column)) ...
                            || iscellstr(currentData.(column))...
                            )
                        data = currentData{:, column}(startRow:endRow, gcolumn);
                    else
                        data = currentData{startRow:endRow,column};
                    end
                    [vals{currentGrouppedColumn}, metaData(:,currentGrouppedColumn)] = PeerDataUtils.parseCharColumn(data);
                elseif isdatetime(currentData.(column)) || isduration(currentData.(column)) || iscalendarduration(currentData.(column))
                    currData = currentData{:, column}(startRow:endRow, gcolumn);
                    dtFormat = fullDTFormats(column);
                    if ~strcmp(currData.Format, dtFormat)
                        % Its possible when scrolling that the datetime format for the given page of data may be different
                        % than the datetime format used elsewhere (for example, dates with hours/minutes/seconds not all 
                        % zero will show with hh:mm:ss, while if they are all 0 may be shown without this).  When this 
                        % happens, stick with the longer format.
                        if strlength(currData.Format) > strlength(dtFormat)
                            dtFormat = currData.Format;
                        end
                        currData.Format = dtFormat;
                    end
                    datestrings = cellstr(currData);
                    vals{currentGrouppedColumn} = {PeerDataUtils.formatDatetime(datestrings)};
                elseif isstruct(currentData.(column)) || ...
                        (isobject(currentData.(column)) && ~iscategorical(currentData.(column))) || ...
                        isempty(meta.class.fromName(colClass))
                    vals{currentGrouppedColumn} = {repmat({['1' TIMES_SYMBOL '1 ' formatDataUtils.getClassString(currentData.(column), true)]}, endRow-startRow+1,1)};
                    metaData(:,currentGrouppedColumn) = true;
                else
                    r=evalc('disp(currentData{:,column}(startRow:endRow,gcolumn))');
                    vals{currentGrouppedColumn} = PeerDataUtils.parseCellColumn(r);
                    if iscell(currentData.(column))
                        currData = currentData{:,column}(startRow:endRow,gcolumn);
                        % For these types, ensure that we show them as metadata
                        % display correctly. (g2047290)
                        [isSummaryValue, summaryValuesToExpand] = internal.matlab.datatoolsservices.FormatDataUtils.isSummaryValueForCellType(currData);
                        % We need to go through each cell and fix the disp value
                        % for non scalar values that fit our le
                        % MAX_DISPLAY_ELEMENTS elements and le
                        % MAX_DISPLAY_DIMENSIONS dimensions criteria
                        if (any(summaryValuesToExpand) || any(isSummaryValue))
                            c = vals{currentGrouppedColumn}{:};
                            displayConfig = matlab.display.DisplayConfiguration;
                            for row=startRow:endRow
                                currentRow = row-startRow+1;
                                currentCellVal = currentData{:,column}{row,gcolumn};
                                if isa(currentCellVal, "matlab.mixin.CustomCompactDisplayProvider")
                                    [formattedVal, isDimsAndClassName] = internal.matlab.datatoolsservices.FormatDataUtils.getCompactDisplayForData(currentCellVal, displayConfig);
                                    c{currentRow} = formattedVal;
                                    isSummaryValue(currentRow) = isDimsAndClassName;
                                elseif isa(currentCellVal, 'function_handle') && isscalar(currentCellVal)
                                        formattedVal = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(currentCellVal);
                                        c{currentRow} = formattedVal;
                                        isSummaryValue(currentRow) = true;
                                elseif summaryValuesToExpand(currentRow)
                                    d = currentCellVal;
                                    r = evalc('disp(d)');
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
                                            c{currentRow} = internal.matlab.datatoolsservices.FormatDataUtils.getNumericNonScalarValueDisplay(d);
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
                                            % These can be non-scalar
                                            % as well
                                            expandableArray = internal.matlab.datatoolsservices.FormatDataUtils.expandableArrayParsing(d, dSize);
                                            c{currentRow} = ['[' expandableArray ']'];
                                        else
                                            c{currentRow} = ['[' strjoin(strsplit(strjoin(strtrim(strsplit(strtrim(r),'\n')),';')),',') ']'];
                                        end
                                        isSummaryValue(currentRow) = false;
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
        end
    end
    if ~isempty(vals)
        renderedData=[vals{:}];
        if ~isempty(renderedData)
            renderedData=[renderedData{:}];
        end
    end
    renderedDims = size(renderedData);
end
