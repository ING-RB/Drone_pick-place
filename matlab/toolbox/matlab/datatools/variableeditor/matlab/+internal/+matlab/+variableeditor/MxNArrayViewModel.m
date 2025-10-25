classdef MxNArrayViewModel < ...
        internal.matlab.variableeditor.ArrayViewModel
    %MxNArrayViewModel
    % MxN Array View Model

    % Copyright 2015-2024 The MathWorks, Inc.
    
    methods(Access='public')
        % Constructor
        function this = MxNArrayViewModel(dataModel, viewID, userContext)
            arguments
                dataModel
                viewID = ''
                userContext = ''
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
        end
        
        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = internal.matlab.variableeditor.MxNArrayViewModel.getParsedMxNArrayData(...
                this.DataModel.Data, startRow, endRow, startColumn, endColumn);
        end
    
        % getRenderedData
        % returns a cellstr for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end
    end
    
    methods(Static)
        function [renderedData, renderedDims] = ...
                getParsedMxNArrayData(currentData, startRow, endRow, ...
                startColumn, endColumn)
            % Return the renderedData for the object array, in the
            % specified range (startRow/endRow startColumn/endColumn)            
            s = size(currentData);
            currentDataCell = cell(s);
            try
                currentDataCell(startRow:endRow, startColumn:endColumn) = arrayfun(@(x) {x}, currentData(startRow:endRow, startColumn:endColumn));
            catch
                for row = 1:s(1)
                    for col = 1:s(2)
                        currentDataCell{row, col} = currentData(row, col);
                    end
                end
            end
            [renderedData, renderedDims, ~] = ...
                internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView(startRow, endRow, ...
                startColumn, endColumn, currentDataCell);
            
        end
    end
end