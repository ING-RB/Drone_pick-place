classdef PeerDataUtils < handle
    %

    % Copyright 2017-2019 The MathWorks, Inc.
    
    properties(Constant)
        MAX_DISPLAY_ELEMENTS = 11;
        MAX_DISPLAY_DIMENSIONS = 2;
        CHAR_WIDTH = 7;		% Width of each character in the string
        HEADER_BUFFER = 10;	% The amount of room(leading and trailing space) the header should have after resizing to fit the header name
        TIMES_SYMBOL = matlab.internal.display.getDimensionSpecifier;
    end
    
    methods(Static)
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getArrayRenderedData(data)
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
		
		function [stringData] = getStringData(fullData, dataSubset, rows, cols, scalingFactor)
            if nargin < 5
                scalingFactor = strings(0,0);
            end
            
            if (isnumeric(dataSubset) || islogical(dataSubset)) && ismatrix(dataSubset) && ~isempty(dataSubset)
                subset = dataSubset(1:rows, 1:cols);                                
                if ~isempty(scalingFactor)
                    % if scaling factor exists pass the display APIs should
                    % be called with the fullData
                    [stringData, scalingFactor] = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, subset, true, true);
                    stringData = sprintf("\n\t1.0e+%02d *\n%s", log10(scalingFactor), stringData);
                else
                    % if no scaling factor exists the the display APIs
                    % should be called without using fullData for
                    % better performance
                    stringData = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, subset, true, false);
                end                                
            else
                stringData = evalc('disp(dataSubset(1:rows, 1:cols))');
            end
        end
        
        function [renderedData, renderedDims, metaData] = getTableRenderedData(currentData)
            import internal.matlab.legacyvariableeditor.peer.PeerDataUtils;

            if ~isempty(currentData)
                [renderedData, renderedDims, metaData] = ...
                    PeerDataUtils.formatDataBlock(1, size(currentData,1), 1, size(currentData,2), currentData);
            else
                renderedDims = size(currentData);
                renderedData = cell(renderedDims);
                metaData = false(renderedDims);
            end
        end
        
        function summarString = makeNDSummaryString(size, numRows, class)
            import internal.matlab.legacyvariableeditor.peer.PeerDataUtils;
            summaryString = '1';
            for sz = size                
                summaryString = [summaryString, PeerDataUtils.TIMES_SYMBOL, num2str(sz)]; %#ok<AGROW>
            end
            summaryString = [summaryString, ' ', class];
            summarString = repmat({summaryString}, numRows, 1);
        end

        function vals = parseNumericColumn(strColumnData, currentData)
            if isempty(regexp(strColumnData,'\s*[0-9]+\.[0-9e+-]*?\s\*', 'once'))
                textformat = ['%s', '%*[\n]'];
                vals = textscan(strColumnData,textformat,'Delimiter','');
            else
                % We need to parse row by row
                colVal = cell(size(currentData,1),1);
                for row=1:size(currentData,1)
                    colVal{row} = strtrim(evalc('disp(currentData(row))'));
                end
                vals = {colVal};
            end
        end
        
        function [vals, metaData] = parseCharColumn(currentData)  
            formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
            import internal.matlab.legacyvariableeditor.peer.PeerDataUtils;
            metaData = false(size(currentData,1),1);
            strData = string(currentData);
            overCharMax = (strlength(strData) > formatDataUtils.MAX_TEXT_DISPLAY_LENGTH);
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
                        sizeStr = strjoin(split(num2str(size(currentData(row,:)))), PeerDataUtils.TIMES_SYMBOL);
                        if iscellstr(currentData) %#ok<ISCLSTR>
                            sizeStr = strjoin(split(num2str(size(currentData{row,:}))), PeerDataUtils.TIMES_SYMBOL);
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
        
        function vals = parseCellColumn(strColumnData)
            textformat = ['%s', '%*[\n]'];
            vals = strtrim(textscan(strColumnData,textformat,'Delimiter',''));
            vals = strtrim(regexprep(vals{:}, '(^(({[)|[|{))|(((]})|]|})$)',''));
            vals = {vals(:)};
        end
        
        function vals = formatDatetime(strColumnData)
            vals = internal.matlab.datatoolsservices.FormatDataUtils.replaceNewLineWithWhiteSpace(strColumnData);
        end
        
        function [renderedData, renderedDims, metaData, sRow, eRow, sCol, eCol] = formatDataBlock(startRow,endRow,startColumn,endColumn,currentData)
            import internal.matlab.legacyvariableeditor.peer.PeerDataUtils;
            TIMES_SYMBOL = PeerDataUtils.TIMES_SYMBOL;
            renderedData = {};
            startColumnIndexes = internal.matlab.legacyvariableeditor.TableViewModel.getColumnStartIndicies(currentData,1,size(currentData,2));
            [sRow, eRow, sCol, eCol] = internal.matlab.datatoolsservices.FormatDataUtils.resolveRequestSizeWithObj(...
                startRow, endRow, startColumn, endColumn, size(currentData));

            nGroupColumns = max(1,startColumnIndexes(eCol+1)-startColumnIndexes(sCol));
            numRows = eRow-sRow+1;
            vals = cell(1,nGroupColumns);
            metaData = false(numRows, nGroupColumns);
            formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
            
            % Loop over actual columns indexes (not groupped)
            currentGrouppedColumn = 1;
            for column=max(1,sCol):min(size(currentData,2),eCol)
                colClass = class(currentData.(column));
                groupColStart = startColumnIndexes(column);
                groupColEnd = startColumnIndexes(column+1);
                % Loop over groupped columns
                for gcolumn=1:(groupColEnd-groupColStart)                    
                    sz = size(currentData.(column));                    
                    if numel(sz) > 2 % Treat nD data as its own data type.
                        sz = sz(2:end); % The first dimension will be converted into the rows of the table.
                        vals{currentGrouppedColumn} = {PeerDataUtils.makeNDSummaryString(sz, eRow - sRow + 1, colClass)};
                        metaData(:, currentGrouppedColumn) = true; 
                    elseif any(strcmp(colClass, internal.matlab.variableeditor.MLUnsupportedDataModel.ForceUnsupported))
                        summary = internal.matlab.datatoolsservices.FormatDataUtils.getValueSummaryString(...
                            currentData{:, column}(sRow, gcolumn), []);
                        vals{currentGrouppedColumn} = {repmat({summary}, eRow-sRow+1, 1)};
                        metaData(:,currentGrouppedColumn) = true;
                    elseif isnumeric(currentData.(column))
                        currentCol = currentData{:,column};
                        if (issparse(currentCol))
                            % Convert to str to get the string value of the
                            % sparse array and convert back to num.
                            % Indexing into sRow:eRow will not be accurate
                            % for char arrays
                            currentCol = str2num(num2str(currentCol));
                            r = evalc('disp(currentCol(sRow:eRow,gcolumn))');
                        else
                            r=evalc('disp(currentData{:,column}(sRow:eRow,gcolumn))');
                        end
                        vals{currentGrouppedColumn} = PeerDataUtils.parseNumericColumn(r, currentCol(sRow:eRow,gcolumn));
                    elseif istable(currentData.(column)) || isa(currentData.(column),'dataset')
                        % Nested tables show as 1 by the number of columns
                        % in the nested table, which must be the same for
                        % all rows of the table (so we can use repmat to
                        % create the data to display)
                        currSize = size(currentData.(column));
                        vals{currentGrouppedColumn} = {repmat(...
                            {['1' TIMES_SYMBOL num2str(currSize(2)) ' ' colClass]}, ...
                            eRow-sRow+1, 1)};
                        metaData(:,currentGrouppedColumn) = true;
                    elseif ischar(currentData.(column)) || iscategorical(currentData.(column)) ...
                            || iscellstr(currentData.(column)) ...
                            || formatDataUtils.checkIsString(currentData.(column)) %#ok<ISCLSTR>
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
                        [vals{currentGrouppedColumn}, metaData(:,currentGrouppedColumn)] = PeerDataUtils.parseCharColumn(data);
                   elseif isdatetime(currentData.(column)) || isduration(currentData.(column)) || iscalendarduration(currentData.(column))
                        datestrings = cellstr(currentData{:, column}(sRow:eRow, gcolumn));
                        vals{currentGrouppedColumn} = {PeerDataUtils.formatDatetime(datestrings)};                    
                    elseif isstruct(currentData.(column)) || ...
                            (isobject(currentData.(column)) && ~iscategorical(currentData.(column))) || ...
                             isempty(meta.class.fromName(colClass))
                        vals{currentGrouppedColumn} = {repmat({['1' TIMES_SYMBOL '1 ' formatDataUtils.getClassString(currentData.(column), true)]}, eRow-sRow+1,1)};
                        metaData(:,currentGrouppedColumn) = true;
                    else
                        r=evalc('disp(currentData{:,column}(sRow:eRow,gcolumn))');
                        vals{currentGrouppedColumn} = PeerDataUtils.parseCellColumn(r);
                        if iscell(currentData.(column))
                            currData = currentData{:,column}(sRow:eRow,gcolumn);
                            if internal.matlab.datatoolsservices.FormatDataUtils.checkIsString(currData{1}) || ischar(currData{1}) || isnumeric(currData{1}) || islogical(currData{1}) || isdatetime(currData{1}) ||...
                                    iscalendarduration(currData{1}) || isduration(currData{1})
                                isSummaryValue = cellfun(@(x)~(ischar(x) || (numel(x) < PeerDataUtils.MAX_DISPLAY_ELEMENTS && ndims(x) <= PeerDataUtils.MAX_DISPLAY_DIMENSIONS)), currData);
                            else
                                % if it is not a char , numeric or string then it is
                                % one of table, dataset,cell, struct, categorical, 
                                % object, nominal, ordinal data which are
                                % always displayed as metadata
                                isSummaryValue = ones(size(currData));
                            end
                            metaData(:,currentGrouppedColumn) = isSummaryValue;
                            % Check to see if any of the data is array data
                            % that needs to be expanded because it's within
                            % the display criteria
                            % Disp always shows arrays as MxN doule but we
                            % want to display smallish arrays like [1,2]
                            summaryValuesToExpand = cellfun(@(x) ischar(x)|| ( ~ischar(x) &&  ~isscalar(x) && (numel(x) < PeerDataUtils.MAX_DISPLAY_ELEMENTS && ndims(x) <= PeerDataUtils.MAX_DISPLAY_DIMENSIONS)) , currentData{:,column}(sRow:eRow,gcolumn));
                            % We need to go through each cell and fix the
                            % disp value for non scalar values that fit our
                            % le MAX_DISPLAY_ELEMENTS elements and
                            % le MAX_DISPLAY_DIMENSIONS dimensions criteria
                            if (any(summaryValuesToExpand))
                                c = vals{currentGrouppedColumn}{:};
                                for row=sRow:eRow
                                    if summaryValuesToExpand(row-sRow+1)
                                        %the disp for structures consists
                                        %of a hyperlink so we should not
                                        %use it directly
                                        d = currentData{:,column}{row,gcolumn};
                                        if isstruct(d) || isobject(d)
                                            r = [num2str(size(d,1)) TIMES_SYMBOL num2str(size(d,2)) ' struct'];
                                        else
                                            r=evalc('disp(d)');
                                        end
                                        % Turn:  1 2
                                        %        3 4
                                        % Into: [1,2;3,4]
                                        %                                                                                                                        
                                        if ischar(d) 
                                            c{row-sRow+1} =  ['''' strrep(strrep(r,sprintf('\n'),''), sprintf('\r'),'') ''''];
                                        elseif ~isstruct(d) && ~isobject(d)
                                            c{row-sRow+1} = ['[' strjoin(strsplit(strjoin(strtrim(strsplit(strtrim(r),'\n')),';')),',') ']'];
                                        end
                                    end
                                end
                                
                                
                                vals{currentGrouppedColumn} = {c};
                            end
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
        
        % nD data in a table is accessed using parentheses and an
        % appropriate number of colons.
        %        
        % For example, a 4-by-2-by-7 cell array would have a name of
        % <table>.<cellName>(<row>, :, :).
        %
        % A 4-by-2-by-7-by-3 struct array would have a name of 
        % <table>.<structArrayName>(<row>, :, :, :).
        function editorValue = getNDEditorValue(name, varName, row, sz)
            editorValue = sprintf('%s.%s(%d', name, varName, row);
            for idx = 2:numel(sz)
                editorValue = [editorValue, ',:']; %#ok<AGROW>
            end
            editorValue = [editorValue, ')'];
        end

        function [renderedData, renderedDims] = getTableRenderedDataForPeer(rawData, variableName)
            
            import internal.matlab.legacyvariableeditor.peer.PeerDataUtils;

            % TODO: Add long format data fetch
            [data, ~, metaData] = PeerDataUtils.getTableRenderedData(rawData);
            longData = data;

            isMetaData = metaData;
            renderedData = {};
            
            dataSize = size(rawData);

            % Gets the starting index of each column, if a column is
            % grouped the adjoining columns will not be listed
            startColumnIndexes = internal.matlab.legacyvariableeditor.TableViewModel.getColumnStartIndicies(rawData,1,size(rawData,2));

            previousFormat=get(0,'format');
            format('long');

            columnClasses = varfun(@class, rawData, 'OutputFormat', 'cell');
            isCellStrs = varfun(@(x)iscellstr(x),rawData, 'OutputFormat','Uniform');
            columnClasses(isCellStrs) = {'cellstr'};
            for col=1:(size(startColumnIndexes,2)-1)
                actualColumn = col;
                
                % Set escape values to false since it's not needed for numeric
                % strings, but capture the old value so that we can restore it
                columnClass = columnClasses{actualColumn};
                doEscapeValues = ~(internal.matlab.legacyvariableeditor.peer.PeerUtils.isNumericType(columnClass) ||...
                                strcmp(columnClass,'logical'));
            
                for row=1:dataSize(1)
                    rowValue = '[';
                    % Loop through the inner columns
                    for dataIndex=startColumnIndexes(col):startColumnIndexes(col+1)-1
                        if dataIndex>startColumnIndexes(col)
                            rowValue = [rowValue ','];
                        end
                        if metaData(row,dataIndex)
                            isMeta = '1';
                        else
                            isMeta = '0';
                        end
                        cellValue = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON(doEscapeValues,  struct('value', data{row,dataIndex},...
                            'isMetaData', isMeta));
                        rowValue = [rowValue cellValue];
                    end
                    rowValue = [rowValue ']'];
 
                    renderedData{row,col} = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON(doEscapeValues,...
                        struct('value', rowValue));
                end

            end

            format(previousFormat);

            renderedDims = size(renderedData);
        end
        
        function [renderedData, renderedDims, scalingFactorString] = getFormattedNumericData(fullData, dataSubset, usercontext, scalingFactorString)
            if nargin < 3
                usercontext = '';
                scalingFactorString = strings(0,0);
            elseif nargin < 4
                scalingFactorString = strings(0,0);
            end
            
            convertSubsetToComplex = false;
            if ~isempty(dataSubset)               
                
                vals = cell(size(dataSubset,2),1);               
                [fullData, dataSubset] = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.getNumericValue(fullData, dataSubset);
                if ~isempty(scalingFactorString)
                    % either scaling factor is greater than 1 or
                    % it needs to be computed
                    % if scaling factor is greater than 1 then disp data
                    % should be queried by calling the API with full data
                    % and data subset                    
                    [dispData, scalingFactor, convertSubsetToComplex] = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, dataSubset, false);
                    scalingFactorString = num2str(scalingFactor);
                else
                    % if scaling factor is empty then we default/assume
                    % that the data has no scaling factor (.i.e. scaling factor is 1)
                    dispData = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, dataSubset, false, false);
                end
                
                % if not live editor and scaling factor exists then compute
                % raw values
                % TODO: Fix widget registry so the view model does not know
                % about live editor
                if ~isempty(scalingFactorString) && ~internal.matlab.legacyvariableeditor.peer.PeerUtils.isLiveEditor(usercontext)
                    for column=1:size(dataSubset,2)
                        subset = dataSubset(:,column);
                        if convertSubsetToComplex == true
                            subset = complex(dataSubset(:,column));
                        end
                        r=evalc('disp(subset)');
                        vals{column} = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.parseNumericColumn(r, subset);
                    end
                    renderedData = [vals{:}];

                    if ~isempty(renderedData)
                        renderedData = [renderedData{:}];
                    end
                % if live editor
                else
                    renderedData = cellstr(dispData);
                end
                renderedDims = size(renderedData);
            else
                renderedDims = size(dataSubset);
                renderedData = cell(renderedDims);
            end
        end
        
         % Returns fullvalue and subsetValue as is. If numeric object,
        % returns numeric converted value;
        function [fullData, subsetData] = getNumericValue(fullData, subsetData)
            if isobject(subsetData)
                % Handle the case where the object is a numeric sublcass 
                if isa(subsetData,'single')
                    fullData = single(fullData);
                    subsetData = single(subsetData);
                else
                    fullData = double(fullData);
                    subsetData = double(subsetData);
                end
            end
        end
        
        function scalingFactorString = getScalingFactor(fullData)
            f = get(0,'format');
            if (isinteger(fullData) && isreal(fullData)) || islogical(fullData) || ~any(strcmp({'long','short'}, f))
                scalingFactorString = strings(0,0);
            else
                [~, scalingFactor] = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, fullData(1:1,1:1), true);
                if scalingFactor == 1
                    scalingFactorString = strings(0,0);
                else
                    scalingFactorString = string(scalingFactor);
                end
            end
        end
        
        function scalingFactor = getScalingFactorFromDataString(dataString)
            scalingFactor = regexp(dataString,'\s*[0-9]+\.[0-9e+-]*?\s\*', 'match');
        end
        
        function exponent = getScalingFactorExponent(scalingFactorString)
            exponent = 1;
            if ~isempty(scalingFactorString)
                exponent = log10(str2double(strtrim(strrep(scalingFactorString, '*', ''))));
            end
        end
        
        % function returns the data as an array or scalar string using disp
        % APIs
        % fullData: All the data in the data model
        % dataSubset: The subset of data which needs to be rendered
        % isScalarOutput: true if the display should be returned as a 1x1
        % scalar string, false if it should be returned as a string array
        % useFullData: true if the full data should also be passed to API
        % to compute the subset display. If scaling factor exists and we
        % need the scaled values for a data subset then this should be
        % true. If we want the raw values of the subset or no scaling
        % factor exists then this should be false         
        function [dispData, scalingFactor, convertSubsetToComplex] = getDisplayDataAsString(fullData, dataSubset, isScalarOutput, useFullData)
            % defaults
            if nargin < 3
                isScalarOutput = false;
                useFullData = true;
            elseif nargin < 4                
                useFullData = true;
            end
            
            [fullData, dataSubset] = internal.matlab.legacyvariableeditor.peer.PeerDataUtils.getNumericValue(fullData, dataSubset);

            % if full data is complex then querying for a subset might
            % return a non-complex value if that subset has all real
            % values. So convert subset to complex if data is of complex
            % type
            convertSubsetToComplex = false;
            if ~isempty(fullData) && ~isreal(fullData)
                convertSubsetToComplex = true;
                dataSubset = complex(dataSubset);
            end
                        
            if ~isempty(fullData) && useFullData
                [dispData, scalingFactor] =  matlab.internal.display.numericDisplay(fullData, dataSubset, 'ScalarOutput', isScalarOutput);
            else
                [dispData, scalingFactor] =  matlab.internal.display.numericDisplay(dataSubset, 'ScalarOutput', isScalarOutput);
             end
        end
        
        function precision = getDatetimePrecisionFromFormat(formatString)
            if contains(formatString, 's')
                precision = 'second';
            elseif contains(formatString, 'm')
                precision = 'minute';
            elseif (contains(formatString, 'h') || contains(formatString, 'H'))
                precision = 'hour';
            elseif (contains(formatString, 'D') || contains(formatString, 'd') || contains(formatString, 'e'))
                precision = 'day';
            elseif contains(formatString, 'W')
                precision = 'week';
            elseif contains(formatString, 'M')
                precision = 'month';
            elseif contains(formatString, 'Q')
                precision = 'quarter';
            else
                precision = 'year';
            end
        end
        
        % This function returns the time component of a datetime as a 
        % string, provided that the user's data format allows the time
        % values to be displayed.
        function t_string = getTimeStringFromDatetime(dt)
            dfmt = matlab.internal.datetime.filterTimeIdentifiers(dt.Format);
            if isempty(dfmt)
                t_string = string(dt);
            else
                [y,m,d] = ymd(dt);
                dt_date = datetime(y,m,d);
                dt_date.Format = dfmt;
                dt_string = string(dt);
                dt_date_string = string(dt_date);
                t_string = replace(dt_string, dt_date_string, '');
                t_string = strtrim(t_string);
            end
        end
        
        % This function gets the correct format for datetime filtering.
        % If the user's format does not contain Year, Month and Day for dates and
        % Hour, Minutes and Seconds for times, revert to MATLAB default formats.
        function fmt = getCorrectFormatForDatetimeFiltering(userfmt)
            fmt = userfmt;
            dateFormat = matlab.internal.datetime.filterTimeIdentifiers(userfmt);
            
            if (strcmp(dateFormat, userfmt))
                useDefaultFmt = ~((contains(userfmt, 'y') || contains(userfmt, 'u')) && contains(userfmt, 'M') && ...
                    (contains(userfmt, 'D') || contains(userfmt, 'd') || contains(userfmt, 'e')));
                defaultFmt = matlab.internal.datetime.defaultDateFormat();
            else
                useDefaultFmt = ~((contains(userfmt, 'y') || contains(userfmt, 'u')) && contains(userfmt, 'M') && ...
                    (contains(userfmt, 'D') || contains(userfmt, 'd') || contains(userfmt, 'e')) && ... 
                    (contains(userfmt, 'h') || contains(userfmt, 'H')) && contains(userfmt, 'm') && contains(userfmt, 's'));
                defaultFmt = matlab.internal.datetime.defaultFormat();
            end
            
            if (useDefaultFmt)
                fmt = defaultFmt;
            end
            
        end
        
        % This function gets the correct format for duration filtering.
        function fmt = getCorrectFormatForDurationFiltering(userfmt)
            fmt = userfmt;
            if (~contains(userfmt, ":"))
                fmt = "hh:mm:ss";
            end
        end
    end
end

% Replace new lines and carriage returns with white space in a cell
% array of strings.
function vals = replaceNewLineWithWhiteSpace(strColumnData)
    % First replace the new line with white space.
    vals = cellfun(@(dt) strrep(dt, char(10), ' '), strColumnData, 'UniformOutput', false);

    % Now replace the carriage return with white space.
    vals = cellfun(@(dt) strrep(dt, char(13), ' '), vals, 'UniformOutput', false);
end
