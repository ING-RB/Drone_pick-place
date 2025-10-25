classdef RemoteDatasetViewModel < internal.matlab.variableeditor.peer.RemoteTableViewModel & ...
        internal.matlab.variableeditor.DatasetViewModel
    % RemoteDatasetViewModel Remote Dataset View Model

    % Copyright 2024 The MathWorks, Inc.

    methods
        function this = RemoteDatasetViewModel(document, variable, viewID, userContext)
            if nargin < 3 
                userContext = '';
                viewID = '';
            elseif nargin < 4
                userContext = '';
            end
            % Ensure that DatasetViewModel is initialized first, else
            % TableModelProperties set during initTableModelInformation
            % will get reset.
            this@internal.matlab.variableeditor.DatasetViewModel(variable.DataModel, viewID);
            this = this@internal.matlab.variableeditor.peer.RemoteTableViewModel(document,variable, viewID, userContext);
        end

        % Override default impl to turn off thread safety for datasets
        % (NOTE: These are legacy views in VE)
        function handled = initializeThreadSafety(this)
            this.setThreadSafety(false);
            handled= true;
        end

         function initTableModelInformation (this)
            this.setTableModelProperties(...
                'editable', false,...
                'EditableColumnHeaderLabels', false);               
         end
         
         % Updates selection context for grouped/ungrouped context and for
         % selection subset if it is a numeric/char subset or cell
         % otherwise.
         function updateSelectionContext(this)
             clientSelection = this.getSelection;           
             rows = clientSelection{1};
             cols = clientSelection{2};
             % Ensure that selection is not empty.
             if ~isempty(rows) && ~isempty(cols)
                 data = this.DataModel.Data;
                 varnames = data.Properties.VarNames;
                 isGrouped = false;
                 isUngrouped = false;
                 % Allow update only when all rows/consecutive columns are
                 % selected.
                 if height(rows) == 1 && height(cols) == 1 && all(rows(:,1) == 1) && all(rows(:,2) == height(data)) 
                     selectedTable = data(:, unique(cols(1):cols(2)));
                     if ~isempty(selectedTable)
                         colCount = width(selectedTable);
                         if isscalar(unique(datasetfun(@class, selectedTable, 'UniformOutput', false))) && colCount > 1
                             isGrouped = true;
                         elseif colCount == 1
                             colStartIndices = this.getColumnStartIndicies(selectedTable, 1, colCount);
                             if (colStartIndices(2) - colStartIndices(1)) > 1
                                 isUngrouped = true;
                             end
                         end
                     end
                 end
                 this.setProperty('GroupVariable', isGrouped);
                 this.setProperty('UngroupVariable', isUngrouped);
                 
                 selectedCols = {};
                 for col = cols.'
                     selectedCols = [selectedCols, varnames(unique(col(1): col(2)))];
                 end
                 selectedTable = data(rows, selectedCols);
                 numericCols = datasetfun(@isnumeric, selectedTable, 'UniformOutput', true);
                 if isequal(size(selectedTable, 2), sum(numericCols))
                     this.setProperty('SelectionSubset', 'numeric');
                 else
                     stringCols = datasetfun(@isstring, selectedTable, 'UniformOutput', true);
                     if isequal(size(selectedTable, 2), sum(stringCols))
                         this.setProperty('SelectionSubset', 'string');
                     else
                         charCols = datasetfun(@ischar, selectedTable, 'UniformOutput', true);
                         if isequal(size(selectedTable, 2), sum(charCols))
                             this.setProperty('SelectionSubset', 'char');
                         else
                             this.setProperty('SelectionSubset', 'cell');
                         end
                     end
                 end
             end           
         end
        
        function headerNames = getHeaderNames(this, data)
            arguments
                this
                data = this.DataModel.Data
            end
            headerNames = data.Properties.VarNames;
        end

        function startIndicies = getColumnStartIndiciesHelper(~, rawData, startColumn, endColumn)
            startIndicies = internal.matlab.variableeditor.DatasetViewModel.getColumnStartIndicies(rawData, startColumn, endColumn);
        end

        % Helper function to get command needed to retrieve variable names
        % based on datatype
        function varname = getVarNameHelper(~, data)
            varname = data.Properties.VarNames;
        end

        % Helper function to get command needed to retrieve row names
        % based on datatype
        function rowname = getRowNameHelper(~, data)
            rowname = data.Properties.ObsNames;
        end

        function assignmentString = generateVariableNameAssignmentStringHelper(~, rawData, subs, vname, tname)
            assignmentString = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentStringDataset(rawData, subs, vname, tname);
        end

        % Helper function to get command string needed to retrieve variable names
        % based on datatype
        function propString = getVariableNameString(~)
            propString = "VarNames";
        end

        % Helper function to get command string needed to update row names
        % based on datatype
        function cmdString = getRowUpdateString(~)
            cmdString = '%s.Properties.ObsNames{%d} = "%s";';
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
            v = dataset2cell(t);
            if ~isempty(t.Properties.ObsNames)
                v = v(:,2:end);
            end
            if ~isempty(t.Properties.VarNames)
                v = v(2:end, :);
            end
            varargout{1} = v;
        end
    end

    methods(Access='protected')
        
        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteDatasetViewModel';
        end    

        function varName = getVariableName(this, ~, column, data) %#ok<INUSL>
            arguments
                this
                ~
                column
                data = this.DataModel.Data
            end
            varName = eval(sprintf('data.Properties.VarNames{%d}',column));
        end

    end
end
