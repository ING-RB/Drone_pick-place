classdef RemoteMxNArrayViewModel < ...
        internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.MxNArrayViewModel
    % RemoteMxNArrayViewModel Remote Model MxN Array View Model.  This
    % extends the MxNArrayViewModel to provide the functionality for
    % display of NxM struct and object arrays in Matlab Online/JSD.

    % Copyright 2015-2023 The MathWorks, Inc.
    
    methods
        function this = RemoteMxNArrayViewModel(document, variable, viewID, userContext)
            % Creates a new RemoteMxNArrayViewModel for the given
            % variable, using the specified document.
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.MxNArrayViewModel(...
                variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                document, variable, 'viewID', viewID);
        end
        
        % Override RemoteArrayViewModel's information
        function initTableModelInformation (this)
            this.setTableModelProperties(...
                'ShowColumnHeaderNumbers',false, ...
                'class', 'object');
        end
        
        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)
            % Returns the rendered data for the specified range of
            % startRow/endRow, startColumn/endColumn.
            data = this.getRenderedData@internal.matlab.variableeditor.MxNArrayViewModel(...
                startRow, endRow, startColumn, endColumn);            
            [renderedData, renderedDims] = internal.matlab.variableeditor.peer.RemoteMxNArrayViewModel.getJSONForMxNArrayData( ...
                data, startRow, startColumn, this.DataModel.Name, this.usesCellArrayIndexing(this.DataModel.getData()));           
        end
    end

    methods(Access='protected')
        % Replaces data with empty value replacement or formats incoming
        % data such that we can eval the data to be set for the row/column
        % in the correct workspace.
        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data)
            if isempty(data)
                % Cannot have empty data in object arrays
                 error(message('MATLAB:codetools:variableeditor:EmptyValueInvalid'));          
            end
            [data, origValue, evalResult, isStr] = this.processIncomingDataSet@internal.matlab.variableeditor.peer.RemoteArrayViewModel(row, column, data);
        end

        function isEqual = isEqualDataBeingSet(~, newValue, currentValue, ~, ~)
            isEqual = isequaln(newValue, currentValue);
        end
    end
    
    methods(Static)
        function [renderedData, renderedDims] = getJSONForMxNArrayData(...
                data, startRow, startColumn, variableName, useCellArrayIndexing)
            if nargin < 4
                variableName = '';
            end
            
             % Populate the renderedData cell array with the data determined
            % from the MxNArrayViewModel, as well as the row/column
            % numbers 
            renderedData = cell(size(data));            
            
            sRow = max(1,startRow);            
            sCol = max(startColumn,1);            
            for col = 1:size(renderedData,2)
                for row = 1:size(renderedData,1)                    
                    jsonData =  struct('value',data{row,col},...
                        'isMetaData', true);
                    
                    % Setup the editor value (something like
                    % varName(row,column))
                    if ~isempty(variableName)
                        if useCellArrayIndexing
                            jsonData.editorValue = sprintf('%s{%d,%d}', ...
                                variableName, row + sRow - 1, ...
                                col + sCol - 1);
                        else
                            jsonData.editorValue = sprintf('%s(%d,%d)', ...
                                variableName, row + sRow - 1, ...
                                col + sCol - 1);
                        end
                    end
                    renderedData{row,col} = jsonencode(jsonData);                     
                end                
            end
            renderedDims = size(renderedData);
        end
        
        function b = usesCellArrayIndexing(rawData)
            b = isa(rawData, 'collection');
        end
       
    end
    
    methods(Access = protected)
        
        function classType = getClassType(this, row, column, sz) %#ok<INUSL>
            arguments
                this
                row
                column
                sz = this.getTabularDataSize()
            end
            classType = '';
            if row > sz(1) || column > sz(2)
                % Infinite grid, no exisitng class type.
                return;
            end
            % Called to return the class type
            classType = eval(sprintf('class(this.DataModel.Data(%d,%d))', ...
                row, column));
        end
        
        function isValid = validateInput(this, value, row, column)
            % Called to validate the input for the specified row/column.
            % Attempt to make the assignment to a copy of the data. If it errors, the error will
            % be displayed as an error message in the Variable Editor.
            % Do not modify DataModel's Data, this will prevent detection
            % of a DataChange and notifying the view.
            currData = this.DataModel.Data;
            currData(row,column) = value;
            isValid = true;
        end
        
        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteMxNArrayViewModel';
        end   
    end  
end