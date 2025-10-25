classdef RemoteOptimvarViewModel < ...
        internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.OptimvarViewModel
    % RemoteOptimvarViewModel Remote implementation of the optimvar viewmodel.
    % This extends the OptimvarViewModel to provide the functionality for
    % the following classes: 'optim.problemdef.OptimizationExpression',
    % 'optim.problemdef.OptimizationConstraint', 'optim.problemdef.OptimizationInequality', 'optim.problemdef.OptimizationEquality'

    % Copyright 2022 The MathWorks, Inc.
    
    methods
        function this = RemoteOptimvarViewModel(document, variable, viewID, userContext)
           arguments
               document internal.matlab.variableeditor.peer.RemoteDocument
               variable internal.matlab.variableeditor.peer.RemoteOptimvarAdapter
               viewID char = '__1'
               userContext char = ''
           end
            this@internal.matlab.variableeditor.OptimvarViewModel(...
                variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                document, variable, 'viewID', viewID);
        end
        
        % Override RemoteArrayViewModel's information
        function initTableModelInformation (this)
            this.setTableModelProperties(...
                'class', 'optimvar');
        end
        
        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getRenderedData@internal.matlab.variableeditor.OptimvarViewModel(startRow,endRow,startColumn,endColumn);  
        end       
    end
    
    methods(Access = protected)

        % Processes incoming data for optimvar objects. The result string
        % is user entered data and unevaluated. 
        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data)
            origValue = '';
            sz = this.getTabularDataSize();
            isStr = false;
            if ischar(data)
                % Replace non-breaking spaces with ASCII white space character
                data = strrep(data, char(160), ' ');
            end
            data = strtrim(data);
            % compute origValue only if we are editing within the current data grid.
            if (row <= sz(1) && column <= sz(2))
                origValue = this.formatDataForClient(row, row, column, column);
            end
            % NOTE: We do not evaluate data, code is generated as is for
            % incoming data edit.
            evalResult = data;
        end
        
        % Returns underlying class from the datamodel's data.
        function classType = getClassType(this, row, column, sz)
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
        
        function isValid = validateInput(varargin)
            % Incoming Input is always char and treated as valid, generated code will error
            % if this is an invalid edit
            isValid = true;
        end
        
        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteOptimvarViewModel';
        end
        
        % Compare the string expansion version of the old and new values in
        % an edit cycle
        function isEqual = isEqualDataBeingSet(~, newValue, currentValue, ~, ~)
            if ~ischar(currentValue) && ~isstring(currentValue)
                currentValue = char(expand2str(currentValue));
            end
            isEqual = strcmp(newValue, currentValue);
        end
    end  
end