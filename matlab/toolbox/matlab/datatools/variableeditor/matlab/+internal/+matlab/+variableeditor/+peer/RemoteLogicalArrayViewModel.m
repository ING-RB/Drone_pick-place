classdef RemoteLogicalArrayViewModel < ...
        internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.LogicalArrayViewModel
    % RemoteLogicalArrayViewModel
    % Remote Model Logical Array View Model
    
    % Copyright 2015-2019 The MathWorks, Inc.
   
    methods
        % Constructor - creates a new RemoteLogicalArrayViewModel
        function this = RemoteLogicalArrayViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end            
            % Ensure that LogicalArrayViewModel is initialized first, else
            % TableModelProperties set during initTableModelInformation
            % will get reset.
            this@internal.matlab.variableeditor.LogicalArrayViewModel(...
                variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                document,variable, 'viewID', viewID);                       
        end
        
        % getRenderedData - returns a cell array of strings for the desired
        % range of values
        function [renderedData, renderedDims] = getRenderedData(...
                this, startRow, endRow, startColumn, endColumn)
            % Get the data from the LogicalArrayViewModel.  This is a cell
            % array of the values, with '1' or '0' in each cell
            [renderedData, renderedDims] = this.getRenderedData@internal.matlab.variableeditor.LogicalArrayViewModel(...
                startRow, endRow, startColumn, endColumn);
        end
       
        % Doing a one time update of TableModelProps as we do not have any
        % fields that change dynamically
        function initTableModelInformation (this)
            this.setTableModelProperties(...
                'class', 'logical');   
        end
        
        % No value in updating columnWitdhs for Logical Arrays, they are
        % always displayed as binary data(Resized ColumnWidths will still
        % be retained)
        function updateColumnWidths(this, startCol, endCol)
        end
    end    

    methods (Access = protected)
       
        function result = evaluateClientSetData(~, data, ~, ~)
            % In case of logicals, if the user types a single character in 
            % single quotes, it is converted to its equivalent ascii value
            result = [];
            if (isequal(length(data), 3) && isequal(data(1),data(3),''''))
                result = double(data(2));
            end
        end
        
        % Called to validate input when the user makes changes
        function isValid = validateInput(~, value, ~, ~)
            if ischar(value)
                % Accept the text true and false
                isValid = strcmp(value, 'true') || strcmp(value, 'false');
            else
                % Also accept numeric and logical values
                isValid = (isnumeric(value) || islogical(value)) ...
                    && size(value, 1) == 1 && size(value, 2) == 1;
            end
        end
        
        % getEmptyValueReplacement - returns false for logicals
        function replacementValue = getEmptyValueReplacement(~, ~, ~)
            replacementValue = false;
        end
    end
    
    methods (Static)         
        function renderedData = getJSONForLogicalData(data, startRow, endRow, startColumn, endColumn)
            renderedData = cell(size(data));
            
            % Create the row and column strings to use in the JSON data
            % below
            rowStrs = strtrim(cellstr(...
                num2str((startRow-1:endRow-1)'))');
            colStrs = strtrim(cellstr(...
                num2str((startColumn-1:endColumn-1)'))');
            
            % Loop through the data, and create the JSON representation
            for row = 1:min(size(renderedData, 1), size(data, 1))
                for col = 1:min(size(renderedData, 2), size(data, 2))
                    jsonData = internal.matlab.variableeditor.peer.PeerUtils.toJSON(...
                        false, ...
                        struct('value', data(row, col),...
                        'row', rowStrs{row}, ...
                        'col',colStrs{col}));
                    
                    renderedData{row, col} = jsonData;
                end
            end
        end
    end
end
