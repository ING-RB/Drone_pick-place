classdef CalendarDurationArrayViewModel < internal.matlab.variableeditor.ArrayViewModel
    %CALENDARDURATIONARRAYVIEWMODEL
    %   Calendar Duration Array View Model

    % Copyright 2015-2021 The MathWorks, Inc.

    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = CalendarDurationArrayViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
        end
        
        % Returns the format for the calendar duration variable.
        function format = getFormat(this)
            format = this.DataModel.getData().Format;
        end
        
        % isEditable
        function editable = isEditable(varargin)
            editable = false;
        end
        
        
        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            data = this.getData(startRow,endRow,startColumn,endColumn);
            [renderedData, renderedDims] = internal.matlab.variableeditor.CalendarDurationArrayViewModel.getParsedCalendarDurationData(data);        
        end
    
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end
    end 
    
    methods(Static)
        function [renderedData, renderedDims] = getParsedCalendarDurationData(data)
            renderedData = cellstr(data);        
            renderedDims = size(renderedData);
        end
    end
end
