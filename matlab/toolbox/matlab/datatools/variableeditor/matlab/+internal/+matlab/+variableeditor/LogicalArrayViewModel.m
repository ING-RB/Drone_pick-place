classdef LogicalArrayViewModel < ...
        internal.matlab.variableeditor.ArrayViewModel
    % LOGICALARRAYVIEWMODEL
    % Logical Array View Model

    % Copyright 2015-2024 The MathWorks, Inc.

    % Public Abstract Methods
    methods (Access = public)
        % Constructor
        function this = LogicalArrayViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
        end
        
        function [renderedData, renderedDims] = getRenderedData(...
                this, startRow, endRow, startColumn, endColumn)
            % Get the data from the LogicalArrayViewModel.  This is a
            % string array of the values, with '1' or '0' in each cell
            renderedData = {};
            renderedDims = [0, 0];
            if ~isempty(this.DataModel.Data)
                dataSubset = this.DataModel.Data(startRow:endRow, startColumn:endColumn);
                renderedData = matlab.internal.display.numericDisplay(this.DataModel.Data, dataSubset);
                renderedDims = size(renderedData);
            end
        end
    end
end