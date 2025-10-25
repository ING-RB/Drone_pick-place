classdef RemoteTableSpannedViewModel < internal.matlab.variableeditor.peer.RemoteTableViewModel & ...
         internal.matlab.variableeditor.SpannedTableViewModel
    % RemoteTableViewModel Remote Table View Model

    % Copyright 2023-2024 The MathWorks, Inc.

    methods
        function this = RemoteTableSpannedViewModel(document, variable, viewID, userContext)
            arguments
                document
                variable
                viewID = ''
                userContext = ''
            end
            % Ensure that TableViewModel is initialized first, else
            % TableModelProperties set during initTableModelInformation
            % will get reset.
            this@internal.matlab.variableeditor.SpannedTableViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteTableViewModel(document,variable, viewID, userContext);
        end
         
         % TODO: Update when we turn on nested tables for VE
         function updateSelectionContext(this, data)
         end

        % Gets selection indices for the current view. From the current
        % selection, adjust column indices to account for nested and
        % grouped columns
        function s = getSelectionIndices(this)
            s = this.getSelection();
            if ~isempty(s{2})
                nestedTableInfo = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(this.DataModel.Data);
                hasNested = any(nestedTableInfo);
                hasGrouped = any(this.GroupedColumnCounts > 1);
                if hasNested || hasGrouped
                    if hasGrouped && hasNested
                        cummCount = (this.GroupedColumnCounts + nestedTableInfo) -1;             
                    elseif hasNested 
                        cummCount = nestedTableInfo;
                    else   
                        cummCount = this.GroupedColumnCounts;
                    end
                    s{2} = internal.matlab.variableeditor.TableViewModel.getColumnsFromSelectionString(s{2}, cummCount);
                end
            end
        end

         function [isUniform, data, selectedCols] = isUniformSelection(this, cols, data, varnames, selectedCols)
             arguments
                 this
                 cols
                 data
                 varnames
                 selectedCols = {}
             end
             nf = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(data);
             isUniform = true;
             if any(nf > 1)
                  for col = cols.'
                     st = col(1);
                     ed = col(2);
                     [actualStart, actualEnd, idx] = internal.matlab.variableeditor.SpannedTableViewModel.getNestedColumnRange(st, ed, nf);
                     if all(nf(actualStart:actualEnd) == 1)
                         selectedCols = [selectedCols, varnames(unique(actualStart: actualEnd))];
                     elseif nf(actualStart) > 1 && (actualStart == actualEnd)
                        % selection is on a nested table, recurse
                        nestedCol = data.(actualStart);
                        [isUniform, data, selectedCols] = this.isUniformSelection([idx idx+(ed-st)], nestedCol, nestedCol.Properties.VariableNames, selectedCols);
                     else
                        isUniform = false;
                        return;
                     end                     
                 end
             else
                 for col = cols.'
                     selectedCols = [selectedCols, varnames(unique(col(1): col(2)))];
                 end
             end
         end

        % TODO: See if we can club this with getDisplayData
        function headerNames = getHeadersForRange(this, startColumn, endColumn, data, gColCounts)
            arguments
                this
                startColumn
                endColumn
                data = this.DataModel.Data
                gColCounts = this.GroupedColumnCounts
            end
            headerNames = this.getHeadersForRangeHelper(startColumn, endColumn, data, gColCounts);
            missingInd = ismissing(headerNames);
            headerNames(missingInd) = "";
        end

       function headerNames = getHeadersForRangeHelper(this, startColumn, endColumn, data, gColCounts, level)
            arguments
                this
                startColumn
                endColumn
                data
                gColCounts
                level = 1
            end
            headerNames = strings(1, endColumn - startColumn + 1);
            nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(data);
            actualStartColumn = startColumn;
            actualEndColumn = endColumn;
            totalColumnsRequested = endColumn - startColumn + 1;
            if any(nestedTableIndices > 1)
                [actualStartColumn,actualEndColumn, currColIndex]=internal.matlab.variableeditor.SpannedTableViewModel.getNestedColumnRange(actualStartColumn,actualEndColumn,nestedTableIndices);
            elseif any(gColCounts>1)
                [actualStartColumn,actualEndColumn, currColIndex]=internal.matlab.variableeditor.SpannedTableViewModel.getNestedColumnRange(actualStartColumn,actualEndColumn,this.GroupedColumnCounts);
            end
            varNames = this.getHeaderNames(data);
            currDataIndex = 1;
             
            for col=1: (actualEndColumn-actualStartColumn+1)
                actualColumn = actualStartColumn+col-1;
                nestedCols = nestedTableIndices(actualColumn);
                % Is table
                if (nestedCols > 1)
                    curColumn = data{:,actualColumn};
                    rowNames = internal.matlab.variableeditor.SpannedTableViewModel.getRowDimNames(curColumn);
                    cIdx = currDataIndex;
                    nestedColsAvailable = nestedCols - currColIndex + 1; % Cols that can be fetched in current nesting
                    if ~isempty(rowNames) && currColIndex == 1
                        currDataIndex = currDataIndex + 1;
                        nestedColsAvailable = nestedColsAvailable - 1;
                    end
                    nestedEndColumn = min(totalColumnsRequested-currDataIndex+1, nestedColsAvailable);
                    nestedGColCounts = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(curColumn,1 , size(curColumn,2));
                    nestedHeaders = this.getHeadersForRangeHelper(currColIndex, currColIndex+nestedEndColumn-1, curColumn, diff(nestedGColCounts), level+1);
                    headerNames(1, cIdx) = varNames(actualColumn);                        
                    headerNames(2:2+height(nestedHeaders)-1, currDataIndex: currDataIndex+nestedEndColumn-1 ) = nestedHeaders;
                    if (cIdx < currDataIndex)
                        % Attach dimension name
                        dimName = curColumn.Properties.DimensionNames;
                        headerNames(2:2+height(nestedHeaders)-1, cIdx ) = dimName{1};
                    end
                    currDataIndex = currDataIndex + nestedEndColumn;
                    currColIndex = 1;
                elseif ~isempty(gColCounts) && gColCounts(actualColumn) > 1
                    colsToFill = min(totalColumnsRequested, this.GroupedColumnCounts(actualColumn)-currColIndex+1);
                    headerNames(:, currDataIndex: currDataIndex + colsToFill - 1) = string(currColIndex: currColIndex+colsToFill-1);
                    currDataIndex = currDataIndex + colsToFill;
                else
                    headerNames(1, currDataIndex) = varNames(actualColumn);
                    currDataIndex = currDataIndex + 1;
                end
            end
       end

       function editorValue = getEditorValueForCell(this, row, column)
           data = this.DataModel.Data;
           name = this.DataModel.Name;
           dataSize = size(data);

           nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(data);
           actualColumn = column;
           gColSize = 1;
           if ~isempty(this.GroupedColumnCounts)
               [gColSize, actualColumn, ~, dataIdx] = internal.matlab.variableeditor.SpannedTableViewModel.getColumnStartForRange(column, column, this.GroupedColumnCounts);               
           end
           if any(nestedTableIndices > 1)
               actualColumn = internal.matlab.variableeditor.SpannedTableViewModel.getNestedColumnRange(column, column, nestedTableIndices);
           end
            
           varNames = this.getVarNameHelper(data);
           varName = varNames{actualColumn};
           currData = data{row,actualColumn};
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
        % varData (variable data from a regular | nested table) for a particular columnIndex. 
        % varName (variable name of the column Index for a regular/nested table)
        % 
        function [varData, varName, data] = getVariableInfoForColumnIndex(this, columnIndex, varNames)
            parentIndicesMetaData = this.getColumnModelProperty(columnIndex, 'ParentIndex');
            parentIndicesMetaData = parentIndicesMetaData{1};
            data = this.DataModel.Data;
            % TODO: Extract this into a utility that can be shared by other
            % actions as well.
            if ~isempty(parentIndicesMetaData)
                dataIdx = this.getColumnModelProperty(columnIndex, 'ColumnIndex');
                varName = this.getColumnModelProperty(columnIndex, 'HeaderName');
                varName = varName{1};
                dataIdx = str2double(dataIdx{1});
                pIndex = parentIndicesMetaData(1);
                levels = strsplit(pIndex, '__');
                % Get all levels in a numeric array
                levelIdx = str2double(strsplit(levels(end), '_'));
                levelIdx = levelIdx(~ismissing(levelIdx));
                for i=1:length(levelIdx)
                    data = data.(levelIdx(i));
                end
                varData = data.(dataIdx);
            else
                % For tables containing grouped columns, dataIdx needs to be offset w.r.t view index. 
                % Use getHeaderNameFromIndex API to get the offset index.
                [~,dataIdx] = this.getHeaderInfoFromIndex(columnIndex);
                varName = varNames{dataIdx};
                varData = data.(dataIdx);
            end
        end
    end

    methods(Access='protected')

        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteTableSpannedViewModel';
        end

        function subColIterator = setColumnMetaData(this, startCol, endCol, data, parentNames, indexNames, uniqueParentID, currentColumn, totalColumnsRequested, groupedColumnCounts)
            arguments
                this
                startCol
                endCol
                data
                parentNames = string.empty
                indexNames = string.empty
                uniqueParentID = ''
                currentColumn = startCol
                totalColumnsRequested = endCol
                groupedColumnCounts = this.GroupedColumnCounts
            end
            % g1772972: is no longer an issue
            dataIdx = 1;
            actualStartColumn = startCol;
            actualEndColumn = endCol;
            widgetRegistry = internal.matlab.datatoolsservices.WidgetRegistry.getInstance();
            nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(data);

            hasGrouped = ~isempty(groupedColumnCounts);
            if ~hasGrouped
                groupedColumnCounts = ones(1, actualEndColumn-actualStartColumn+1);
            end
            hasNested = any(nestedTableIndices > 1);
            currColIndex = 1;
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
                [gCols, startColIdx, endColIdx, dataIdx] = internal.matlab.variableeditor.SpannedTableViewModel.getColumnStartForRange(startCol, endCol, cummCount, gcolCountsForIndexing);
                actualStartColumn = startColIdx;
                actualEndColumn = endColIdx;
                currColIndex = dataIdx;
            end
            if isempty(gCols)
                gCols = groupedColumnCounts;
            end

            % Loop over top level columns (Ungrouped)
            colIterator = 1;
            subColIterator = currentColumn;
            rowNames = internal.matlab.variableeditor.SpannedTableViewModel.getRowDimNames(data);

            if ~isempty(parentNames) && ~isempty(rowNames) && currColIndex == 1 
                dimName = data.Properties.DimensionNames;
                this.setColumnModelProperty(subColIterator, 'isRowHeaderName', true, false);
                this.setColumnModelProperty(subColIterator, 'class', class(rowNames), false);
                this.setColumnModelProperty(subColIterator,'ParentIndex', indexNames, false);
                this.setColumnModelProperty(subColIterator,'ParentNames', parentNames, false);
                this.setColumnModelProperty(subColIterator,'ColumnIndex', num2str(actualStartColumn), false);
                this.setColumnModelProperty(subColIterator,'HeaderName', dimName{1}, false);

                actualEndColumn = actualEndColumn - 1;
                subColIterator = subColIterator + 1;
            end
            varNames = this.getVarNameHelper(data);

            try
                for col=actualStartColumn:actualEndColumn
                    colValForValidation = data(:, col);
                    underlyingCol = data{:,col};
                    currentVarName = varNames{col};

                    if istabular(underlyingCol)                        
                        nestedColsAvailable = nestedTableIndices(col) - currColIndex + 1; 
                        nestedEndCol = min(totalColumnsRequested-subColIterator+1, nestedColsAvailable);
                        curLevel = [uniqueParentID '_' num2str(col)];
                        pid = currentVarName + "__" + curLevel;

                        gcols = [];
                        [~, gcolumnCount, origSize, ~] = internal.matlab.variableeditor.SpannedTableViewModel.getTableFlatSize(underlyingCol);
                        % Cache grouped column indices after computing once
                        if gcolumnCount > origSize(2)
                            gColStartIndices = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(underlyingCol,1,origSize(2));
                            gcols = diff(gColStartIndices);
                        end

                        this.setColumnMetaData(currColIndex, currColIndex+ nestedEndCol-1, underlyingCol, [currentVarName parentNames], [pid indexNames], curLevel, subColIterator, totalColumnsRequested, gcols);
                        subColIterator = subColIterator + nestedEndCol;
                        currColIndex = 1;
                    else
                      
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
                        if parentNames.length > 0
                            isFilterable = false;
                        end

                        for i = gColStart:gColEnd
                            % 1. Compute HeaderName
                            if this.UseTableColumnNamesForView
                                this.setColumnModelProperty(subColIterator,'HeaderName',currentVarName, false);
                            end

                            % 4. Set groupColumnSize for grouped columns
                            % For Grouped Columns, set Data Attributes so that they can
                            % be queried from the registry.
                            if (groupColumnSize > 1)
                                % DataAttributesForCol(end+1) = "GroupedColumn";
                                % this.setColumnModelProperty(colIdx, 'editable', false);
                                this.setColumnModelProperty(subColIterator,'GroupColumnSize', num2str(groupColumnSize), false);
                                % TODO: Might not be correct if we fetch from middle of
                                % grouped columns, fix this.
                                this.setColumnModelProperty(subColIterator,'ParentIndex', num2str(col), false);
                                this.setColumnModelProperty(subColIterator,'GroupColumnIndex', num2str(i), false);
                            else
                                % Turn off sorting and filtering for grouped columns
                                this.setColumnModelProperty(subColIterator,'IsSortable',isSortable, false);
                                this.setColumnModelProperty(subColIterator,'IsFilterable',isFilterable, false);
                            end

                            if (parentNames.length >= 1)
                                this.setColumnModelProperty(subColIterator,'ParentIndex', indexNames, false);
                                this.setColumnModelProperty(subColIterator,'ParentNames', parentNames, false);
                                this.setColumnModelProperty(subColIterator,'ColumnIndex', num2str(col), false);
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
                            % disp("Updating for col::" +  num2str(col));
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
                    end
                    colIterator = colIterator + 1;
                end
            catch e
            end
        end
    end
end
