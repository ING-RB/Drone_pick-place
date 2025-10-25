classdef StructureArrayViewModel < internal.matlab.variableeditor.ArrayViewModel
    %STRUCTUREARRAYVIEWMODEL
    %   Structure Array View Model

    % Copyright 2015-2024 The MathWorks, Inc.
    
    properties
        MetaData = [];
        UniformDataTypeColumn = [];
    end 
    
    properties (SetObservable=true, SetAccess='protected', Transient)
        CellMetaDataChangedListener;
        ColumnMetaDataChangedListener;
    end
   
    
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = StructureArrayViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
            this.initListeners();
        end
        
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            [renderedData, renderedDims, this.MetaData] = this.getDisplayData(startRow, endRow,startColumn, endColumn);
        end 
        
        function [renderedData, renderedDims, metaData] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            currentData = this.DataModel.getData();
            [renderedData, renderedDims, metaData] = internal.matlab.variableeditor.StructureArrayViewModel.getParsedStructArrayData(...
                currentData, this.DataModel.DataAsCell, startRow, endRow, startColumn, endColumn, this.DisplayFormatProvider.NumDisplayFormat);
            this.MetaData = metaData;
        end                
        
        % The view model's getSize should always return the size of the 
        % structure array when converted to a cell array 
        % TOREMOVE : called from gridEditorHandler
        function s = getSize(this)
            data = this.DataModel.getData;
            % mx1 struct array
            if (size(data,2) == 1)
                s = [size(data,1) length(fields(data))];
            % 1xm struct array, 0x0 struct array
            else
                s = [size(data,2) length(fields(data))];
            end
        end
        
        % The view model's getData should return the data  
        % converted to a cell array 
        % TOREMOVE :  called from handleClientSetData
        function varargout = getData(this,varargin)
            % the input arguments consist of startRow, startCol, endRow,
            % endCol
            structData = this.DataModel.getData(varargin{:});
            dataAsCell = this.DataModel.DataAsCell;
            % when the data is converted to a cell, it is a row vector. We
            % need to index into this using the column number.
            if varargin{3} <= size(structData, 2)
                varargout{1} = dataAsCell{varargin{3}};
            else
                varargout{1} = [];
            end
        end
        
        function varargout = getFormattedSelection(this, varargin)
            data = this.DataModel.getData;
            structDataAsCell = this.DataModel.DataAsCell;
            fields = fieldnames(data);
            dataModelName = this.DataModel.Name;

            % g3357013: If the current column selection is out of range, force it to be the last column;
            % otherwise, we will get errors (e.g., user delets the last struct array field).
            selectedColumns = min(length(fields), this.SelectedColumnIntervals);
            selectedRows = this.SelectedRowIntervals;
            rowCount = size(data,2);
            for r=1:height(selectedRows)
                selectedRows(r, 1) = min(selectedRows(r, 1), rowCount);
                selectedRows(r, 2) = min(selectedRows(r, 2), rowCount);
            end

            if isempty(selectedRows) || isempty(selectedColumns)
                varargout{1} = '';
            else
                varargout{1} = internal.matlab.variableeditor.StructureArrayViewModel.getFormattedSelectionString(selectedRows, ...
                    selectedColumns, fields, dataModelName, data, structDataAsCell);
            end
        end
        
        % Cleanup any listeners that were attached at constructor time
        function delete(this)
            if ~isempty(this.CellMetaDataChangedListener)
                delete(this.CellMetaDataChangedListener);
                this.CellMetaDataChangedListener = [];
            end
            if ~isempty(this.ColumnMetaDataChangedListener)
                delete(this.ColumnMetaDataChangedListener);
                this.ColumnMetaDataChangedListener = [];
            end
        end
    end   
    
    methods(Access='protected')
        % Initializing listeners
        function initListeners(this)
            this.CellMetaDataChangedListener = event.listener(this.DataModel,'CellMetaDataChanged',@this.handleDataModelCellMetaDataChanged);
            this.ColumnMetaDataChangedListener = event.listener(this.DataModel,'ColumnMetaDataChanged',@this.handleDataModelColumnMetaDataChanged);
        end

        function handleDataModelCellMetaDataChanged(this, ~, ed)
            internal.matlab.datatoolsservices.logDebug('variableeditor::StructureArrayViewModel','handleDataModelCellMetaDataChanged');
            this.notify('CellMetaDataChanged', ed);
        end

        function handleDataModelColumnMetaDataChanged(this, ~, ed)
            internal.matlab.datatoolsservices.logDebug('variableeditor::StructureArrayViewModel','handleDataModelColumnMetaDataChanged');
            this.notify('ColumnMetaDataChanged', ed);
        end
    end
    
    methods(Static=true)      
        
        function [renderedData, renderedDims, metaData] = getParsedStructArrayData(data, ...
                dataAsCell, startRow, endRow, startColumn, endColumn, format)
            arguments
                data
                dataAsCell cell
                startRow double
                endRow double
                startColumn double
                endColumn double
                format string = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat;
            end
            if ~isempty(data)
                currentDataAsCell =  dataAsCell;
                [renderedData, renderedDims, metaData] = internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView(...
                    startRow,endRow,startColumn,endColumn,currentDataAsCell,format);
            else
                renderedDims = size(data);
                renderedData = cell(renderedDims);
                metaData = false(renderedDims);
            end            
        end
        
        function selectionString = getFormattedSelectionString(selectedRows, selectedColumns, fields, dataModelName, data, structDataAsCell)
            selectionRowString = '';
            selectionColString = '';
            selectionString = '';
            rowCount = size(data,2);
            
            % this variable evaluates the selected data before returning 
            % the constructed selection string. If the selected
            % data is not valid (.i.e. throws an error at the command window 
            % on evaluation) then the selection string is returned as
            % empty.
            validateSelectionColString = '';
            if ~isempty(selectedRows) || ~isempty(selectedColumns)
                
                % check if all the selected data is numeric
                % This is required in order to construct the selection
                % string and enclose it in 
                % 1. [] if all the data is numeric
                % 2. {} if data is mixed
                allNumericSelection = isSelectionNumeric(selectedRows, selectedColumns, structDataAsCell);
                
                % selectedRows
                for idx=1:size(selectedRows,1)
                    if idx > 1
                        selectionRowString = [selectionRowString ',']; %#ok<AGROW>
                    end
                    
                    if (selectedRows(idx,1) == selectedRows(idx,2))                       
                        selectionRowString = [selectionRowString num2str(selectedRows(idx,1))]; %#ok<AGROW>
                    else
                        % case when a range of subsequent fields are selected
                        selectionRowString = [selectionRowString internal.matlab.variableeditor.StructureArrayViewModel.localCreateSubindex([selectedRows(idx,1) selectedRows(idx,2)],rowCount)];%#ok<AGROW>
                    end
                end
                % If we have more than one set of selections, we need to
                % enclose the selection string in '[' and ']'
                if size(selectedRows, 1) > 1 
                    selectionRowString = ['([' selectionRowString '])'];
                elseif (~(selectedRows(1)==1 && selectedRows(2)==rowCount)) || ...
                        (selectedRows(1)==1  && rowCount == 1)
                    selectionRowString = ['(' selectionRowString ')'];
                end
                
                % selected Columns
                for idx=1:size(selectedColumns,1)
                    if idx > 1
                        selectionColString = [selectionColString ';']; %#ok<AGROW>
                        validateSelectionColString = [validateSelectionColString ',']; %#ok<AGROW>
                    end
                    % case when individual disjoint fields are selected
                    if (selectedColumns(idx,1) == selectedColumns(idx,2))
                        % display string format in case of grouped column
                        if ~allNumericSelection    
                            validateSelectionColString = [validateSelectionColString '{' 'data' selectionRowString '.' char(fields(selectedColumns(idx,1))) '}']; %#ok<AGROW>
                            selectionColString = [selectionColString '{' dataModelName selectionRowString '.' char(fields(selectedColumns(idx,1))) '}']; %#ok<AGROW>
                        else
                            validateSelectionColString = [validateSelectionColString '[' 'data' selectionRowString '.' char(fields(selectedColumns(idx,1))) ']']; %#ok<AGROW>
                            selectionColString = [selectionColString '[' dataModelName selectionRowString '.' char(fields(selectedColumns(idx,1))) ']']; %#ok<AGROW>
                        end
                    else
                        % case when a range of subsequent fields are selected
                        for jdx=(selectedColumns(idx,1)):(selectedColumns(idx,2))
                            if jdx > selectedColumns(idx,1)
                                selectionColString = [selectionColString ';']; %#ok<AGROW>
                                validateSelectionColString = [validateSelectionColString ',']; %#ok<AGROW>
                            end

                            if jdx > length(fields)
                                break;
                            end
                            % display string format in case of grouped column
                            if ~allNumericSelection
                                validateSelectionColString = [validateSelectionColString '{' 'data' selectionRowString '.' char(fields(jdx)) '}'];  %#ok<AGROW>
                                selectionColString = [selectionColString '{' dataModelName selectionRowString '.' char(fields(jdx)) '}']; %#ok<AGROW>
                            else
                                validateSelectionColString = [validateSelectionColString '[' 'data' selectionRowString '.' char(fields(jdx)) ']']; %#ok<AGROW>
                                selectionColString = [selectionColString '[' dataModelName selectionRowString '.' char(fields(jdx)) ']']; %#ok<AGROW>
                            end
                        end
                    end
                end
                try
                   % check if the string is a valid commands
                   validateSelectionColString = ['{' validateSelectionColString '};'];
                   eval(validateSelectionColString);
                   selectionString = selectionColString;
                catch
                end
            end                  
        end
        
        % for testing purpose only
        function result = testIsSelectionNumeric(selectedRows, selectedColumns, data)
            result = isSelectionNumeric(selectedRows, selectedColumns, data);
        end
        
        function subindexString = localCreateSubindex(selectedInterval,count)
            subindexString = internal.matlab.variableeditor.BlockSelectionModel.localCreateSubindex(selectedInterval,count);
            if selectedInterval(1)==1 && selectedInterval(2)==count % All rows/columns
                subindexString = '';
            end    
        end
                            
     end
    
end

%method returns if the data selected is numeric or not
% it checks only for scalars. If the selection consists of non-scalar
% entries or value summaries, it returns false
function allNums = isSelectionNumeric(selectedRows, selectedColumns, data)
    allNums = false;
    try
    % if the first entry is numeric then check the rest
    if isnumeric(data{selectedRows(1,1),selectedColumns(1,1)})
        allNums = true;
        for i=1:size(selectedRows,1)
            for j=1:size(selectedColumns,1)
                selectedData = data(selectedRows(i,1):selectedRows(i,2),selectedColumns(j,1):selectedColumns(j,2));
                % check that all entries are scalar
                if all(cellfun('length',selectedData) <= 1)
                    % check that all entries have the same class type
                    if ~all(cellfun('isclass',selectedData,class(data{selectedRows(1,1),selectedColumns(1,1)})))
                        allNums = false;
                        break;
                    end
                else
                    allNums = false;
                    break;
                end
            end
            if ~allNums
                break;
            end
        end
    end
    catch
        allNums = false;
    end
end

