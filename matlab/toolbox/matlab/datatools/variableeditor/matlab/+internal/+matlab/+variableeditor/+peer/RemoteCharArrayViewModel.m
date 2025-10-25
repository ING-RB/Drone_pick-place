classdef RemoteCharArrayViewModel < ...
        internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.CharArrayViewModel
    % RemoteCharArrayViewModel Remote Model View Model for char array
    % variables
    
    % Copyright 2014-2022 The MathWorks, Inc.
    
    methods
        function this = RemoteCharArrayViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            
            this@internal.matlab.variableeditor.CharArrayViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(document, variable, 'viewID', viewID);
        end
        
        function initTableModelInformation (this)
            this.setTableModelProperties(...                
                'RemoveQuotedStrings', false, ...
                'class','char');
        end
        
        
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow, endRow, startColumn, endColumn)
            % dataSize denotes the actual char array size where each
            % character occupies one column.
            % Eg: s = 'hello_world'
            % dataSize = [1 11]
            dataSize = this.DataModel.getSize();
            data = this.getRenderedData@internal.matlab.variableeditor.CharArrayViewModel(startRow,dataSize(1),startColumn,dataSize(2));
            if isempty(data)
                data = '';
            end
            renderedData{1,1} = data;
            renderedDims = size(renderedData);
        end
    end
    
    methods(Access='protected')
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
            % If char exceeds the max display length, tag as isMetaData as they are represented as dims and classname. 
            dataSize = this.DataModel.getSize();
            if (dataSize(2) > internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH)
                this.setCellModelProperty(startRow,startColumn,'isMetaData', true, false);
            end            
            this.updateCellModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startRow, endRow, startColumn, endColumn, fullRows, fullColumns);
        end
        
        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteCharArrayViewModel';
        end


        % Replaces data with empty value replacement or formats incoming
        % data such that we can eval the data to be set for the row/column
        % in the correct workspace.
        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data)
            % This is always scalar char
            origValue = this.getData();
            isStr = false;
            % TODO: Double check this behavior
            if ~(isequal(data, '''') || isequal(data, '"'))
                data = strrep(data,'''','''''');
                if ~isempty(data)
                    % The user is not expected to explicitly type
                    % quotes while entering char data in the VE
                    data = ['''' data ''''];
                    % Escape /n and /t if the input data contains these characters, checking for chars
                    % as well to support inline editing of strings in struct arrays.
                    data = internal.matlab.variableeditor.peer.PeerUtils.escapeSpecialCharsForChars(data);                  
                else
                    % when data is empty translate it as valid empty data. The
                    % data thus needs to be padded with additional quotes. Resultant data = ''
                    data = '''''';
                end
            end
            evalResult = data;
        end

        function isEqual = isEqualDataBeingSet(~, newValue, currentValue, ~, ~)
             isEqual = isequal(newValue, currentValue);
        end
    end
end
