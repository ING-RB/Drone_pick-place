classdef RemoteCellArrayViewModel < internal.matlab.variableeditor.peer.RemoteArrayViewModel & internal.matlab.variableeditor.CellArrayViewModel
    % RemoteCellArrayViewModel Remote Model Cell Array View Model
    
    % Copyright 2015-2024 The MathWorks, Inc.

    methods
        function this = RemoteCellArrayViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.CellArrayViewModel(variable.DataModel, viewID, userContext);    
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(document,variable, 'viewID', viewID);
        end

        % Initialize thread safety to control requests executed on
        % background thread. If cell array has > 250000 entries, set thread safety to false.
        function handled = initializeThreadSafety(this)
            handled = this.initializeThreadSafety@internal.matlab.variableeditor.peer.RemoteArrayViewModel();
            if (~handled) && numel(this.DataModel.Data) > this.STR_NUMEL_CUTOFF_FOR_BACKGROUND_FETCHES
                % Set property on pubsubdatastore to notify client.
                this.setThreadSafety(false);
                handled = true;
            end
        end
        
        function [renderedData, renderedDims] = getRenderedData(this, startRow, endRow, ...
            startColumn, endColumn)
            data = this.getRenderedData@internal.matlab.variableeditor.CellArrayViewModel(...
                startRow, endRow, startColumn, endColumn);
            rawData = this.DataModel.Data;
            isMetaData = this.MetaData;
            
            [renderedData, renderedDims] = internal.matlab.variableeditor.peer.RemoteCellArrayViewModel.getJSONForCellData( ...
                data, rawData, isMetaData, startRow, startColumn, this.DataModel.Name, this.DisplayFormatProvider);            
        end        
    end
    
    methods(Access='protected')
        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data)
            [data, origValue, evalResult, isStr] = this.processIncomingDataSet@internal.matlab.variableeditor.peer.RemoteArrayViewModel(row, column, data);
             sz = this.getSize();
             if row <= sz(1) && column <= sz(2) 
                 if isa(this.DataModel.Data{row, column}, 'datetime')
                    data = ['''' data ''''];
                 end
             end
        end

        function handleDataChangedOnDataModel(this, es ,ed)
            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.peer.RemoteArrayViewModel(es, ed);
            if isa(ed, 'internal.matlab.datatoolsservices.data.DataChangeEventData')
                % Update Cell Information for chaged data because class
                % types may have changed g3504765
                [sr, er, sc, ec] = this.getAdjustedRange(this.ViewportStartRow, this.ViewportEndRow, this.ViewportStartColumn, this.ViewportEndColumn);
                this.updateCellModelInformation(sr, er, sc, ec, [ed.StartRow:ed.EndRow], [ed.StartColumn:ed.EndColumn]);
            end
        end

    end
    
    methods(Static)      
        function [renderedData, renderedDims] = getJSONForCellData(data, rawData, isMetaData, startRow, startColumn, variableName, DisplayFormatProvider)
            arguments
                data;
                rawData;
                isMetaData;
                startRow double;
                startColumn double;
                variableName = '';
                DisplayFormatProvider internal.matlab.variableeditor.NumberDisplayFormatProvider = internal.matlab.variableeditor.NumberDisplayFormatProvider
            end
            sRow = max(1,startRow);            
            sCol = max(startColumn,1);  
            colStrsIndex = 1;
            renderedData = cell(size(data));
            jsonData = struct;
            
            numDisplayFormat = DisplayFormatProvider.NumDisplayFormat;
            longDisplayFormat = DisplayFormatProvider.LongNumDisplayFormat;
            isDifferentLongFormat = ~strcmp(numDisplayFormat, longDisplayFormat);
            
            for col = 1:size(renderedData,2)                
                rowStrsIndex = 1;
                ld = [];
                try
                    eRow = sRow + size(renderedData,1) - 1;
                    if ~any(cellfun(@isempty, rawData(sRow:eRow,col)))
                        colData = [rawData{sRow:eRow,col}];
                        % If the data is vector we can optimize calling numeric
                        % display, it's less efficient to call it in a loop
                        if all(isnumeric(colData)) && isvector(colData) 
                            ld = matlab.internal.display.numericDisplay(colData,'Format', longDisplayFormat);
                        end
                    end
                catch ex
                    % This will error if not all the can be cast to the same
                    % type
                end
                for row = 1:size(renderedData,1)
                    editorValue = '';
                    rawDataAtIndex = rawData{row+sRow-1,col+sCol-1};
                    if (isMetaData(row,col) || ...
                            ischar(rawDataAtIndex) && size(rawDataAtIndex,1) > 1) && ~isempty(variableName)
                        editorValue = sprintf('%s{%d,%d}', variableName,row+sRow-1,col+sCol-1);
                    end             
                    % only numerics need to have an editvalue which is in
                    % long format
                    % other data types have their edit value same as data
                    % value 
                    isNumericCell = isnumeric(rawDataAtIndex);
                    % For numeric objects, convert to numeric before
                    % formatting (g2044078) 
                    if isNumericCell
                        rawDataAtIndex = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(rawDataAtIndex);
                        rawData{row+sRow-1,col+sCol-1} = rawDataAtIndex;
                    end
                    if isNumericCell && ~isMetaData(row,col) && isscalar(rawDataAtIndex) && isDifferentLongFormat
                        if ~isempty(ld)
                            longData = ld(row);
                        else
                            longData = matlab.internal.display.numericDisplay(rawData{row+sRow-1,col+sCol-1},'Format', longDisplayFormat);
                        end
                    else  
                        % Escape \ and " , Handle \n and \t for strings alone.
                        data{row,col} = internal.matlab.variableeditor.peer.PeerUtils.formatGetJSONforCell(rawDataAtIndex, data{row,col});
                        longData = [];
                    end
                    jsonData.value = data{row,col};
                    jsonData.editValue = longData;
                    jsonData.isMetaData = isMetaData(row,col);
                    jsonData.editorValue = []; % Need to add for all structs because structs in struct array need same fields, will remove later if not set
                    if ~isempty(editorValue)
                        jsonData.editorValue = editorValue;
                    end
                    nrd(row, col) = jsonData;
                    %renderedData{row,col} = jsonencode(jsonData);                
                    rowStrsIndex = rowStrsIndex + 1;
                end
                colStrsIndex = colStrsIndex + 1;
            end

            if isempty(data)
                % This can happen when deleting all content of a cell array
                % while it is open
                renderedData = {};
            else
                jd = jsonencode(nrd);
                if size(nrd,1) > 1
                    jd = jd(2:end-1);
                end
                if size(nrd,2) > 1
                    jd = jd(2:end-1);
                end
                jd = strrep(jd, ',"editorValue":[]', '');
                jd = strrep(jd, ',"editValue":[]', '');
                jd = strrep(jd, ',"isMetaData":false', '');% Strip default metadata values
                rs = split(jd, "],[");

                % Replace comma between cells with arbitrary string so that we can split on it
                rs = strrep(rs, "},{", "}_@TSPLIT_{");
                % Split to get column elements
                ds = split(rs, "_@TSPLIT_");
                % Need to make sure the array has the correct
                % dimensions
                renderedData = reshape(ds, size(nrd,1), size(nrd,2));
            end
            renderedDims = size(renderedData);
        end
    end
    
    methods(Access = 'protected')
        
        function updateCellModelInformation(this, startRow, endRow, startColumn, endColumn, fullRows, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                startColumn (1,1) double {mustBeNonnegative}
                endColumn (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
                fullColumns (1,:) double = startColumn:endColumn
            end
            this.CellModelChangeListener.Enabled = false;
            currentData = this.DataModel.Data;           
            for col=endColumn:-1:startColumn
                for row = endRow:-1:startRow
                    val = currentData{row,col};
                    % if className is different from matchedVariableClass then
                    % it means that the current data type is unsupported or it 
                    % is a custom object. In this case, the metadata of the 
                    % unsupported object should be displayed in the table
                    % column. GetRenderered Data specifies the right
                    % data/metadata to be displayed by the client renderer.
                    className = this.getLookupClassName(class(this), val);                   
                    this.setCellModelProperties(row, col,...                    
                        'class', className);
                    if any(strcmp(className, ["categorical","nominal","ordinal"]))
                        cats = categories(val);
                        % Limit the number of categories displayed, otherwise we hit OutOfMemory errors
                        cats(internal.matlab.datatoolsservices.FormatDataUtils.MAX_CATEGORICALS:end) = [];
                        this.setCellModelProperties(row, col,...                    
                        'categories', cats, 'isProtected', isprotected(val), 'RemoveQuotedStrings', true);
                    elseif any(strcmp(className, ["duration", "calendarDuration"]))
                        this.setCellModelProperties(row, col, 'editable', false);
                    end
                end
            end
            this.CellModelChangeListener.Enabled = true;
            this.updateCellModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startRow, endRow, startColumn, endColumn, fullRows, fullColumns);
        end
        
        function classType = getClassType(~, ~, ~, ~, ~)
            % Return container class type (cell), not the individual cell
            % from the specified row/col.  Decisions made on the class type
            % returned here only depend on the container type.
            classType = 'cell';
        end                
    end   
end
