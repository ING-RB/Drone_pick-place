classdef DatetimeArrayViewModel < internal.matlab.legacyvariableeditor.ArrayViewModel
    %DATETIMEARRAYVIEWMODEL
    %   Datetime Array View Model

    % Copyright 2015 The MathWorks, Inc.

    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = DatetimeArrayViewModel(dataModel)
            this@internal.matlab.legacyvariableeditor.ArrayViewModel(dataModel);
        end
                
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            data = this.getData(startRow,endRow,startColumn,endColumn);
            renderedData = cellstr(data);
            
            % Replace line feeds and carriage returns with white space.
            renderedData =  internal.matlab.datatoolsservices.FormatDataUtils.replaceNewLineWithWhiteSpace(renderedData);
            renderedDims = size(renderedData);
        end
    end
end
