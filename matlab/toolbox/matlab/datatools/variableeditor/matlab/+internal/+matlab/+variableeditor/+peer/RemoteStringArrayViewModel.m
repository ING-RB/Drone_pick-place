classdef RemoteStringArrayViewModel < ...
        internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.StringArrayViewModel
    % RemoteStringArrayViewModel Remote Model View Model for string array
    % variables
    
    % Copyright 2015-2024 The MathWorks, Inc.   
        
    methods
        function this = RemoteStringArrayViewModel(document, variable, viewID, userContext)
            arguments
                document
                variable
                viewID = ''
                userContext = ''
            end
            % Ensure that StringArrayViewModel is initialized first, else
            % TableModelProperties set during initTableModelInformation
            % will get reset.
            this@internal.matlab.variableeditor.StringArrayViewModel(variable.DataModel, viewID, userContext);   
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(document, variable, 'viewID', viewID);
        end

        % Initialize thread safety to control requests executed on
        % background thread. If string array has > 250000 entries, set thread safety to false.
        function handled = initializeThreadSafety(this)
            handled = this.initializeThreadSafety@internal.matlab.variableeditor.peer.RemoteArrayViewModel();
            if (~handled) && numel(this.DataModel.Data) > this.STR_NUMEL_CUTOFF_FOR_BACKGROUND_FETCHES
                % Set property on pubsubdatastore to notify client.
                this.setThreadSafety(false);
                handled = true;
            end
        end
        
        % Initializes all the tableModelInformation for string arrays.
        function initTableModelInformation (this)             
            this.setTableModelProperties(...                
                'class', 'string');
        end 
        
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            [renderedData, ~, ~] = this.getRenderedData@internal.matlab.variableeditor.StringArrayViewModel(startRow,endRow,startColumn,endColumn);
            renderedDims = size(renderedData);          
        end
    end   
    
    methods(Access='protected')
        function ed = handleDataChange(this, ed)
            fullRows = ed.StartRow:ed.EndRow;
            fullColumns = ed.StartColumn:ed.EndColumn;
            if ed.SizeChanged
                size = this.getTabularDataSize;
                fullRows = 1:size(1);
                fullColumns = 1:size(2);
            end
            this.handleDataChange@internal.matlab.variableeditor.peer.RemoteArrayViewModel(ed);
            try
                this.updateCellModelInformation(ed.StartRow, ed.EndRow, ed.StartColumn, ed.EndColumn, fullRows, fullColumns);
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteStringArrayViewModel", "handleDataChange error: " + e.message);
            end
        end

        % Send missing data information as cellmetadata.
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
            missingStr = ismissing(this.DataModel.Data(startRow: endRow, startColumn: endColumn));
            [row,col] = find(missingStr);
            for i=1:length(row)
                this.setCellModelProperty(startRow+row(i)-1,startColumn+col(i)-1,'isMetaData', true, false);
            end

            % g2636046: Reset the cell model properties to prevent stale meta data.
            [row2, col2] = find(~missingStr);
            for i=1:length(row2)
                this.setCellModelProperty(startRow+row2(i)-1,startColumn+col2(i)-1,'isMetaData', false, false);
            end
            this.updateCellModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startRow, endRow, startColumn, endColumn, fullRows, fullColumns);
        end
        
        function replacementValue = getEmptyValueReplacement(~, ~, ~)   
            replacementValue = '';
        end
        
        function classType = getClassType(this, ~, ~, ~)
            classType = class(this.DataModel.Data);
        end 
    end
    
    methods(Static)
        % NOTE: No usages of this API currently.
        function [renderedData, renderedDims] = getJSONForStringData(data, metaData, startRow, endRow, startColumn, endColumn, dataSize)
            renderedData = cell(size(data));
            [startRow, endRow, startColumn, endColumn] = internal.matlab.datatoolsservices.FormatDataUtils.resolveRequestSizeWithObj(...
                startRow, endRow, startColumn, endColumn, dataSize);

            % Use metadata determined from getRenderedData.  It is limited to the same
            % range as the data
            missingStr = metaData;            
            
            rowStrs = strtrim(cellstr(num2str((startRow-1:endRow-1)'))');
            colStrs = strtrim(cellstr(num2str((startColumn-1:endColumn-1)'))');
            
            for row=1:min(size(renderedData,1),size(data,1))
                for col=1:min(size(renderedData,2),size(data,2))                        
                    jsonData = internal.matlab.variableeditor.peer.PeerUtils.toJSON(true,...
                        struct('value',data{row,col},...
                        'isMetaData', missingStr(row,col), ...
                        'row',rowStrs{row},...
                        'col',colStrs{col}));
                    
                    renderedData{row,col} = jsonData;
                end
            end
            renderedData = data;
            renderedDims = size(renderedData); 
        end
    end
end
