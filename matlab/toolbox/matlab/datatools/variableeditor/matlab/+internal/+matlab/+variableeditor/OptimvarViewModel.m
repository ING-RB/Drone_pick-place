classdef OptimvarViewModel < ...
        internal.matlab.variableeditor.ArrayViewModel
    % OptimvarViewModel handles fetching display data for optimvar scalar
    % and vector views.

    % Copyright 2022 The MathWorks, Inc.
    
    methods(Access='public')
        % Constructor
        function this = OptimvarViewModel(dataModel, viewID, userContext)
            arguments
                dataModel
                viewID char = '';
                userContext char = '';
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
        end
        
        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = internal.matlab.variableeditor.OptimvarViewModel.getParsedOptimvarData(...
                this.DataModel.Data, startRow, endRow, startColumn, endColumn);
        end
    
        % getRenderedData
        % returns a string for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end
    end
    
    methods(Static)
        function [renderedData, renderedDims] = getParsedOptimvarData(currentData, startRow, endRow, startCol, endCol)
            try
                dataSubset = currentData(startRow:endRow, startCol:endCol);
                renderedData = strings(endRow-startRow+1, endCol-startCol+1);
                numCols = endCol-startCol+1;
                for col = 1:numCols
                    renderedData(:,col) = expand2str(dataSubset(:,col));
                end
                renderedDims = size(renderedData);
            catch e 
                renderedData = [];
                renderedDims = [];
            end
        end
    end
end