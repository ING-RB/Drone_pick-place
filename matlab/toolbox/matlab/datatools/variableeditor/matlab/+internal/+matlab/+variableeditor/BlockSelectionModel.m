classdef BlockSelectionModel <  internal.matlab.variableeditor.SelectionModel
    % An abstract class defining the methods for a Variable Selection Model
    %

    % Copyright 2013-2024 The MathWorks, Inc.

    properties (Abstract=true, SetObservable=true, SetAccess='protected', GetAccess='public')
        DataModel
    end

    methods (Abstract)
        objSize = getSize(this);
    end

    % Public Abstract Methods
    methods(Access='public')
        % getSelection
        function varargout = getSelection(this,varargin)
            Selection{1} = this.SelectedRowIntervals;
            Selection{2} = this.SelectedColumnIntervals;

            varargout{1} = Selection;
        end

        % setSelection
        function varargout = setSelection(this,selectedRows,selectedColumns,selectionSource,selectionArgs)
            arguments
                this
                selectedRows
                selectedColumns
                selectionSource = 'server'% This is an optional parameter to indicate the source of the selection change.
                selectionArgs.selectedFields = []
                selectionArgs.updateFocus (1,1) logical = true
            end
            this.SelectedRowIntervals = selectedRows;
            this.SelectedColumnIntervals = selectedColumns;
            Selection{1} = this.SelectedRowIntervals;
            Selection{2} = this.SelectedColumnIntervals;

            varargout{1} = Selection;
            % If the source is not brushing selection, fire SelectionChanged. 
            % If brushing selection, there are a lot of events firing for brushing, 
            % do not update other states like Action state or plots state.
            % TODO: Do this for client selections as well and make this generic.
            if nargin <= 3 || nargin>3 && ~strcmp(selectionSource, 'serverBrushing')
                this.fireSelectionChanged();
            end

        end

        function varargout = getFormattedSelection(this)
            selectionString = '';
            data = this.DataModel.Data;
            varName = this.DataModel.Name;
            slice = '';
            if isprop(this.DataModel, 'Slice')
                slice = this.DataModel.Slice;
                sliceDimIndices = find(slice == ":");
            end

    		% for char arrays the data can be empty. Also holds for infinite grids.
            if ~isempty(data) && ~isempty(this.SelectedRowIntervals) && ~isempty(this.SelectedColumnIntervals)
                dataSize = this.getSize;

                selectedRows = min(dataSize(1), this.SelectedRowIntervals);
                selectedColumns = min(dataSize(2), this.SelectedColumnIntervals);

                rowSelectionString = this.getSelectionString('', dataSize(1,1), selectedRows);
                colSelectionString = this.getSelectionString('', dataSize(1,2), selectedColumns);

                if ~isempty(slice)
                    if ~isequal(sliceDimIndices,[1, 2])
                        numRows = dataSize(1,1);
                        numCols = dataSize(1,2);
                        if ~ismember(rowSelectionString, {':','end'})
                            eval(sprintf('numRows = length(%s);', strrep(rowSelectionString, 'end', num2str(numRows))));
                        end
                        if ~ismember(colSelectionString, {':','end'})
                            eval(sprintf('numCols = length(%s);', strrep(colSelectionString, 'end', num2str(numCols))));
                        end
                        if ~startsWith(rowSelectionString, '[') && ~ismember(rowSelectionString, {':','end'})
                            rowSelectionString = ['[' rowSelectionString ']'];
                        end
                        if ~startsWith(colSelectionString, '[') && ~ismember(rowSelectionString, {':','end'})
                            colSelectionString = ['[' colSelectionString ']'];
                        end
                        % When not indexing the first two dimensions you'll
                        % get a mxnx1 and need squeeze to get rid of the x1
                        % dimenion
                        formatString = 'squeeze(%s(' + strjoin(slice,',').replace(':','%s') + '))';
                        selectionString = char(sprintf(formatString, varName, rowSelectionString, colSelectionString));
                    else
                        formatString = '%s(' + strjoin(slice,',').replace(':','%s') + ')';
                        selectionString = char(sprintf(formatString, varName, rowSelectionString, colSelectionString));
                    end
                else
                    selectionString = sprintf('%s(%s,%s)', varName, rowSelectionString, colSelectionString);
                end
            end

            varargout{1} = selectionString;
        end

        function varargout = getDataType(this,varargin)
            varargout{1} = this.DataModel.ClassType;
        end

        function selectionString = getSelectionString(~, selectionString, dataSize, selectedEntries)
            if ~isempty(selectedEntries)
                if size(selectedEntries,1) > 1
                    selectionString = [selectionString '['];
                end
                for i=1:size(selectedEntries,1)
                    if i>1
                        selectionString = [selectionString ',']; %#ok<AGROW>
                    end
                    % case when a single row/col is selected
                    selectionString = [selectionString internal.matlab.variableeditor.BlockSelectionModel.localCreateSubindex(selectedEntries(i,:),dataSize)]; %#ok<AGROW>
                end
                if size(selectedEntries,1) > 1
                    selectionString = [selectionString ']'];
                end
            end
        end
    end

    methods(Static=true)
        function subindexString = localCreateSubindex(selectedInterval,count)
            if selectedInterval(1)==selectedInterval(2) % Since row/column selection
                if selectedInterval(2)<count
                    subindexString = num2str(selectedInterval(2));
                else
                    subindexString = 'end'; % Since row/column selection at the end
                end
            elseif selectedInterval(1)==1 && selectedInterval(2)==count % All rows/columns
                subindexString = ':';
            elseif selectedInterval(2)==count % rows/columns up to the end
                subindexString = sprintf('%d:end',selectedInterval(1));
            else
                subindexString = sprintf('%d:%d',selectedInterval(1),selectedInterval(2));
            end
        end

        % Gets rowRange and colRange string for the given BlockSelection
        % range.
        % for E.g {[1,2]},{[2,3]} will return rowRange as '1:2' colRange as
        % '2:3' TODO: Update to add ':' and 'end' constructs for full selection ranges.
        function [rowRange, colRange] = getSelectionRange(selection, sz)
            arguments
                selection 
                sz = [0, 0]
            end
            import internal.matlab.variableeditor.BlockSelectionModel;
            sRows = selection{1};
            sCols = selection{2};
            allRows = ~isempty(sRows) && height(sRows) == 1 && sRows(1) == 1 && sRows(2) >= sz(1);
            allCols = ~isempty(sCols) && height(sCols) == 1 && sCols(1) == 1 && sCols(2) >= sz(2);
            if allRows
                rowRange = ':';
            else
                rowRange = BlockSelectionModel.getRangeStr(selection{1});
            end
            if allCols
                colRange = ':';
            else
                % Columns can be un-reconciled as the client maintains
                % selection order. Reconcile before converting to
                % selection range strings
                colSelection = selection{2};
                if ~isempty(colSelection)
                    colSelection = BlockSelectionModel.reconcileSelection(colSelection);
                end
                colRange = BlockSelectionModel.getRangeStr(colSelection);
            end
        end

        % For given selection ranges, this fn reconciles overlapping ranges
        % into one consolidated range.
        function ranges = reconcileSelection(selection)
            colSelection = sortrows(selection);         
            ranges = colSelection(1,:);
            h = height(colSelection);
            if (h > 1)
                prevRange = ranges(1,:);
                d = diff(colSelection);
                for idx=2:h
                    curRange = colSelection(idx,:);
                    if (isequal(d(idx-1,:),[1 1]))
                        prevRange(end) = curRange(end);
                        ranges(end,:) = prevRange;
                    else
                        ranges = [ranges;curRange];
                        prevRange = curRange;
                    end
                end
            end
        end

        % Gets the range str, for range vectors, this returns
        % '[r1,r2],[r3,r4]'
        function range = getRangeStr(selection)
            arguments
                selection
            end
            range = '';
            if ~isempty(selection)
                hasBraces = size(selection, 1) > 1;
                if hasBraces
                    sameIdx = selection(:,1) == selection(:,2);
                    diffIdx = ~sameIdx;
                    diffData = selection(diffIdx,:);
                    sameData = selection(sameIdx);
                    rangeDiff = string.empty;
                    rangeSame = string.empty;
                    if ~isempty(diffData)
                        rangeDiff = compose("%d:%d",diffData);
                    end
                    if ~isempty(sameData)
                        rangeSame = string(sameData);
                    end
                    range = string.empty(length(selection),0);
                    range(sameIdx) = rangeSame;
                    range(diffIdx) = rangeDiff;
                    range = char(strjoin(range, ","));
                    range = ['[' range ']'];
                elseif length(selection) > 1 && isequal(selection(1),selection(2))
                    range = num2str(selection(1));
                else
                    range = char(selection(1) + ":" + selection(2));
                end
            end
        end

        function intervals = getSelectionIntervals(var, selectionString, dimension, varSize)
            % Convert selectionString into an nx2 array of intervals where n is the
            % number of distinct intervals and the first column is start positions and
            % the second end positions.
            if nargin < 4
                varSize = size(var);
            end
            if strcmp('rows',dimension)
                ind = 1:varSize(1);
            else
                if ischar(var) % char arrays are always displayed in an nx1 array (g872913)
                    ind = 1;
                else
                    ind = 1:varSize(2);
                end
            end

            if ~strcmp(':', selectionString)
                eval(['ind = ind([' selectionString ']);']);
            end

            % Fast short circuit for contiguous intervals
            if ind(end)-ind(1)+1==length(ind)
                intervals = [ind(1) ind(end)];
                return
            end
            intervals = [ind(diff([-1 ind])>=2)' ind(diff([ind inf])>=2)'];
        end

        % Returns inverted selection intervals for Block Selection. For
        % E.g. With selectionIntervals [1,3;8,12], invertedIntervals for
        % 100 rows would be [4 7;13 100]
        function invertedIntervals = getInvertedSelectionIntervals(selectionIntervals, data, dimension, dimSize, varSize)
            selectionIndices = [];
            for i=1:height(selectionIntervals)
                r = selectionIntervals(i,:);
                selectionIndices = unique([selectionIndices r(1):r(2)]);
            end
            idxDiff = setdiff(1:dimSize, selectionIndices);
            if isempty(idxDiff)
                idxDiff = 1:dimSize;
            end
            invertedIntervals = internal.matlab.variableeditor.BlockSelectionModel.getSelectionIntervals(data, char(strjoin(string(idxDiff), ',')), dimension, varSize);
        end
    end

    properties
        SelectedRowIntervals;
        SelectedColumnIntervals;
    end

end %classdef
