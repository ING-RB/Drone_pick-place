classdef DatasetViewModel < internal.matlab.variableeditor.TableViewModel
    %DATASETVIEWMODEL
    %   Dataset View Model
    
    % Copyright 2022 The MathWorks, Inc.
    
    % Public Abstract Methods
    methods(Access='public')
        % Helper function to retrieve start column indicies based on
        % datatype
        function startColumnIdxs = getColumnStartIdxHelper(~, currentData, startColumn, endColumn)
            startColumnIdxs = internal.matlab.variableeditor.DatasetViewModel.getColumnStartIndicies(currentData, startColumn, endColumn);
        end

        % Helper function to index data based on datatype
        function indexdata = indexDataHelper(~, currentdata, options)
            if isfield(options, 'gcolumn')
                if isfield(options, 'eRow')
                    tempData = currentdata(:, options.column).(1);
                    indexdata = tempData(options.sRow:options.eRow, options.gcolumn);
                elseif isfield(options, 'Row')
                    tempData = currentdata(:,options.column).(1);
                    indexdata = tempData{options.Row,options.gcolumn};
                else 
                    tempData = currentdata(:,options.column).(1);
                    indexdata = tempData(options.sRow,options.gcolumn);
                end
            else
                if isfield(options, 'sRow') && isfield(options, 'eRow')
                    indexdata = currentdata(options.sRow:options.eRow,options.column).(1);
                else
                    indexdata = currentdata(:,options.column).(1);
                end
            end
        end

        function formattedString = getFormattedSelectionStringHelper(~, selectedRows, selectedColumns, ...
                 dataModelName, data)
            formattedString = internal.matlab.variableeditor.DatasetViewModel.getFormattedSelectionString(selectedRows, ...
                selectedColumns, dataModelName, data);
        end
    end
     
    methods(Static=true)
        function selectionString = getFormattedSelectionString(selectedRows, selectedColumns, dataModelName, data, dataSize)
            import internal.matlab.variableeditor.DatasetDataModel;
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
                        idxExp = internal.matlab.datatoolsservices.FormatDataUtils.generateDotSubscriptingForDataset(data,selectedColumns(i,1),'',true);
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
                            idxExp = internal.matlab.datatoolsservices.FormatDataUtils.generateDotSubscriptingForDataset(data,j,'',true);
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
        
        function startColumnIndexes = getColumnStartIndicies(currentData, startColumn, endColumn)
            % Ensure that each column contains at least one column. (Entries
            % in startColumnIndexes must be strictly greater than the
            % preceding value.
            startColumnIndexes = internal.matlab.datatoolsservices.VariableUtils.getColumnStartIndicies(...
                currentData(:,max(1,startColumn):min(size(currentData,2),endColumn)));
        end
    end
end