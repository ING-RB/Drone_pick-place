classdef TableViewModel < internal.matlab.legacyvariableeditor.ArrayViewModel
    %TABLEVIEWMODEL
    %   Table View Model

    % Copyright 2013-2024 The MathWorks, Inc.

    properties
        MetaData = [];
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
        function this = TableViewModel(dataModel, viewID)
            if nargin <= 1 
                viewID = '';
            end
            this@internal.matlab.legacyvariableeditor.ArrayViewModel(dataModel, viewID);
        end

        function [renderedData, renderedDims, startRow, endRow, startColumn, endColumn] = getRenderedData(...
                this, startRow, endRow, startColumn, endColumn)
            currentData = this.DataModel.Data;
            if ~isempty(currentData)
                [renderedData, renderedDims, metaData, startRow, endRow, startColumn, endColumn] = ...
                    this.formatDataBlock(startRow, endRow, startColumn, endColumn, currentData);
            else
                renderedDims = size(currentData);
                renderedData = cell(renderedDims);
                metaData = false(renderedDims);
            end
            this.MetaData = metaData;
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
            vals =  internal.matlab.datatoolsservices.FormatDataUtils.replaceNewLineWithWhiteSpace(r);
        end
                        
        function [renderedData, renderedDims, metaData, sRow, eRow, sCol, eCol] = formatDataBlock(this,startRow,endRow,startColumn,endColumn,currentData)
            renderedData = {};
            [sRow, eRow, sCol, eCol] = internal.matlab.datatoolsservices.FormatDataUtils.resolveRequestSizeWithObj(...
                startRow, endRow, startColumn, endColumn, size(currentData));
            startColumnIndexes = internal.matlab.legacyvariableeditor.TableViewModel.getColumnStartIndicies(currentData,sCol,eCol);

            nGroupColumns = max(1,startColumnIndexes(end)-startColumnIndexes(1));
            numRows = eRow-sRow+1;
            vals = cell(1,nGroupColumns);
            metaData = false(numRows, nGroupColumns);
            formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
            
            % Loop over actual columns indexes (not groupped)
            currentGrouppedColumn = 1;
            for column=max(1,sCol):min(size(currentData,2),eCol)
                colClass = class(currentData.(column));
                groupColStart = startColumnIndexes(column-sCol+1);
                groupColEnd = startColumnIndexes(column+1-sCol+1);
                % Loop over groupped columns
                for gcolumn=1:(groupColEnd-groupColStart)
                    sz = size(currentData.(column));                    
                    if numel(sz) > 2 % Treat nD data as its own data type.
                        sz = sz(2:end); % The first dimension will be converted into the rows of the table.
                        vals{currentGrouppedColumn} = {this.makeNDSummaryString(sz, eRow - sRow + 1, colClass)};
                        metaData(:, currentGrouppedColumn) = true; 
                    elseif any(strcmp(colClass, internal.matlab.variableeditor.MLUnsupportedDataModel.ForceUnsupported))
                        summary = internal.matlab.datatoolsservices.FormatDataUtils.getValueSummaryString(...
                            currentData{:, column}(sRow, gcolumn), []);
                        vals{currentGrouppedColumn} = {repmat({summary}, eRow-sRow+1, 1)};
                        metaData(:,currentGrouppedColumn) = true;
                    elseif isnumeric(currentData.(column))                        
                        % For numeric objects, convert to numeric before
                        % formatting (g2044078)
                        currentCol = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(currentData{:,column});
                        if (issparse(currentCol))
                            % Convert to str to get the string value of the
                            % sparse array and convert back to num.
                            % Indexing into sRow:eRow will not be accurate
                            % for char arrays
                            currentCol = str2num(num2str(currentCol));
                        end
                        r = evalc('disp(currentCol(sRow:eRow,gcolumn))');                        
                        vals{currentGrouppedColumn} = this.parseNumericColumn(r, currentCol(sRow:eRow,gcolumn));
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
                            data = currentData{:, column}(sRow:eRow, gcolumn);
                        else
                            data = currentData{sRow:eRow,column};
                        end
                        [vals{currentGrouppedColumn}, metaData(:,currentGrouppedColumn)] = this.parseCharColumn(data);
                   elseif isdatetime(currentData.(column)) || isduration(currentData.(column)) || iscalendarduration(currentData.(column))
                        datestrings = cellstr(currentData{:, column}(sRow:eRow, gcolumn));
                        vals{currentGrouppedColumn} = {this.formatDatetime(datestrings)};                    
                    elseif isstruct(currentData.(column)) || ...
                            (isobject(currentData.(column)) && ~iscategorical(currentData.(column))) ...
                            || isempty(meta.class.fromName(class(currentData.(column))))
                        vals{currentGrouppedColumn} = {repmat({['1' this.TIMES_SYMBOL '1 ' formatDataUtils.getClassString(currentData.(column), true)]}, eRow-sRow+1,1)};
                        metaData(:,currentGrouppedColumn) = true;
                    else
                        r=evalc('disp(currentData{:,column}(sRow:eRow,gcolumn))');
                        vals{currentGrouppedColumn} = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.parseCellColumn(r);
                        if iscell(currentData.(column))
                            currData = currentData{:,column}(sRow:eRow,gcolumn);
                             % For these types, ensure that we show them as
                            % metadata display correctly. (g2047290)
                            [isSummaryValue, summaryValuesToExpand] = internal.matlab.datatoolsservices.FormatDataUtils.isSummaryValueForCellType(currData);                          
                           
                            % We need to go through each cell and fix the
                            % disp value for non scalar values that fit our
                            % le MAX_DISPLAY_ELEMENTS elements and
                            % le MAX_DISPLAY_DIMENSIONS dimensions criteria
                            if (any(summaryValuesToExpand))
                                c = vals{currentGrouppedColumn}{:};
                                for row=sRow:eRow
                                    currentRow = row-sRow+1;
                                    if summaryValuesToExpand(currentRow)
                                        %the disp for structures consists
                                        %of a hyperlink so we should not
                                        %use it directly
                                        d = currentData{:,column}{row,gcolumn};
                                        if isstruct(d) || isobject(d)
                                            r = [num2str(size(d,1)) this.TIMES_SYMBOL num2str(size(d,2)) ' struct'];
                                        else
                                            r=evalc('disp(d)');
                                            isSummaryValue(currentRow) = false;
                                        end
                                        % Turn:  1 2
                                        %        3 4
                                        % Into: [1,2;3,4]
                                        %                                                                                                                        
                                        if ischar(d) 
                                            if endsWith(r, newline)
                                                r = r(1:length(r)-1);
                                            end
                                            c{currentRow} =  ['''' r ''''];
                                            isSummaryValue(currentRow) = false;
                                        elseif ~isstruct(d) && ~isobject(d)
                                            c{row-sRow+1} = ['[' strjoin(strsplit(strjoin(strtrim(strsplit(strtrim(r),'\n')),';')),',') ']'];
                                            isSummaryValue(currentRow) = false;
                                        end
                                    else
                                        c{currentRow} = char(internal.matlab.datatoolsservices.FormatDataUtils.correctDimensionSpec(c{currentRow}));
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
            if ~isempty(vals)
                renderedData=[vals{:}];
                if ~isempty(renderedData)
                    renderedData=[renderedData{:}];
                end
            end
            renderedDims = size(renderedData);
        end

        % isEditable
        function editable = isEditable(this, row, col)
            % The cell is not editable if it contains MetaData (like "10x10
            % double").
            editable = ~this.MetaData(row, col);
        end
        
        function varargout = getFormattedSelection(this, varargin)
            data = this.DataModel.Data;            
            selectedColumns = this.SelectedColumnIntervals;
            selectedRows = this.SelectedRowIntervals;
            dataModelName = this.DataModel.Name;

            if isempty(selectedRows) || isempty(selectedColumns)
                varargout{1} = '';
            else
                varargout{1} = internal.matlab.legacyvariableeditor.TableViewModel.getFormattedSelectionString(selectedRows, ...
                    selectedColumns, dataModelName, data);
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
    end
    
    methods(Static=true)
       function selectionString = getFormattedSelectionString(selectedRows, selectedColumns, dataModelName, data, dataSize)
            import internal.matlab.legacyvariableeditor.TableDataModel;
            if (nargin < 6)
                dataSize = size(data);
            end
            selectionRowString = '';
            selectionColString = '';
            if ~isempty(selectedRows) || ~isempty(selectedColumns)
                % selectedRows
                for i=1:size(selectedRows,1)
                    if i > 1
                        selectionRowString = [selectionRowString ',']; %#ok<AGROW>
                    end
                    
                    if (selectedRows(i,1) == selectedRows(i,2))                       
                        selectionRowString = [selectionRowString num2str(selectedRows(i,1))]; %#ok<AGROW>
                    else
                        % case when a range of subsequent fields are selected
                        selectionRowString = [selectionRowString num2str(selectedRows(i,1)) ':' num2str(selectedRows(i,2))]; %#ok<AGROW>
                    end
                end
                % If we have more than one set of selctions, we need to
                % enclose the selection string in '[' and ']'
                if size(selectedRows, 1) > 1 
                    selectionRowString = ['([' selectionRowString '])'];
                else
                    selectionRowString = ['(' selectionRowString ')'];
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
                        if size(groupedColumn, 2) > 1
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
                            if size(groupedColumn, 2) > 1
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

       function startColumnIndexes = getColumnStartIndicies(currentData, startColumn, endColumn)
           % Ensure that each column contains at least one column. (Entries
           % in startColumnIndexes must be strictly greater than the
           % preceding value.
           startColumnIndexes = cumsum([1 varfun(@(x) ...
                max(size(x,2)*ismatrix(x)*~ischar(x)*~isa(x,'dataset')*~isa(x,'table') + ...
                ischar(x)+isa(x,'dataset')+isa(x,'table'), 1), ...
                currentData(:,max(1,startColumn):min(size(currentData,2),endColumn)),'OutputFormat','uniform')]);
       end
    end
end
            

