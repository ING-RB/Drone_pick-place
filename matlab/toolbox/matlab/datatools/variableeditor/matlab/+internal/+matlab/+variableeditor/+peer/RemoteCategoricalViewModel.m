classdef RemoteCategoricalViewModel < ...
        internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.CategoricalViewModel        
        
    % RemoteCategoricalViewModel Remote Model Table View Model for categorical
    % variables
    
    % Copyright 2014-2024 The MathWorks, Inc.
    
    methods
        function this = RemoteCategoricalViewModel(document, variable, viewID, userContext)
            arguments
                document
                variable
                viewID = ''
                userContext = ''
            end
            
            this@internal.matlab.variableeditor.CategoricalViewModel(variable.DataModel, viewID, userContext);            
            % Ensure that CategoricalViewModel is initialized first, else
            % TableModelProperties set during initTableModelInformation
            % will get reset.                       
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                document, variable, 'viewID', viewID);
        end

        % Initialize thread safety to control requests executed on
        % background thread. If categorical array has > 120000 categories,
        % set thread safety to false. (See PubSubTabularDataStore for cut
        % off limits)
        function handled = initializeThreadSafety(this)
            handled = this.initializeThreadSafety@internal.matlab.variableeditor.peer.RemoteArrayViewModel();
            if (~handled) && numel(this.getCategories(false)) > this.CAT_CUTOFF_FOR_BACKGROUND_FETCHES
                % Set property on pubsubdatastore to notify client.
                this.setThreadSafety(false);
                handled = true;
            end
        end
        
        % Override RemoteArrayViewModel's information
        function initTableModelInformation (~)                       
        end       
       
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getRenderedData@internal.matlab.variableeditor.ArrayViewModel(...
                startRow, endRow, startColumn, endColumn);
        end
    end
    
    methods(Access=protected)
        % Setup the table properties, including the categories and
        % whether the categorical variable is protected or not.       
        function updateTableModelInformation(this)            
            this.setTableModelProperties(...                                         
                'categories', this.getCategories,...
                'isProtected', this.DataModel.Protected,...                
                'class', 'categorical');
            
            this.updateTableModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel();
        end
        
        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteCategoricalViewModel';
        end    

        % Replaces data with empty value replacement or formats incoming
        % data such that we can eval the data to be set for the row/column
        % in the correct workspace.
        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data)
             origValue = this.getData(row, row, column, column);
             evalResult = data;
             isStr = false;
             if isempty(data)
                data = this.getEmptyValueReplacement(row,column);
             else
                 % accept non-empty string as a valid enum
                 if ~ischar(data)
                     error(message('MATLAB:codetools:variableeditor:InvalidInputType'));
                 end
                % Escape double quotes as we generate string
                % code.
                data = strrep(data, '"', '""');
             end         
        end

        function isEqual = isEqualDataBeingSet(this, newValue, currentValue, ~, ~)
             isEqual = strcmp(char(currentValue), newValue);
        end
    end
end
