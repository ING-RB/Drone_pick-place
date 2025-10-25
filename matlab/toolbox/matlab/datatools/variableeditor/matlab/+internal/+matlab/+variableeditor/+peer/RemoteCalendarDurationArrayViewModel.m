classdef RemoteCalendarDurationArrayViewModel < internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.CalendarDurationArrayViewModel
    % RemoteCalendarDurationArrayViewModel Remote Calendar Duration Array View Model
    
    % Copyright 2015-2019 The MathWorks, Inc.
    
    methods
        function this = RemoteCalendarDurationArrayViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            % Ensure that CalendarDurationArrayViewModel is initialized first, else
            % TableModelProperties set during initTableModelInformation
            % will get reset.
            this@internal.matlab.variableeditor.CalendarDurationArrayViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(document,variable,'viewID', viewID);            
        end
        
        % Override RemoteArrayViewModel's information
        function initTableModelInformation (this)
            this.setTableModelProperties(...
                'editable', false, ...
                'class','calendarDuration');
        end   
   
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            [renderedData, renderedDims] = this.getRenderedData@internal.matlab.variableeditor.CalendarDurationArrayViewModel(startRow,endRow,startColumn,endColumn);            
        end
    end
    
    methods(Access='protected')
        function isValid = validateInput(~,value,~,~)
            % The only valid input types are 1x1 calendar durations 
            % This may change in the future when there is a 
            % calendarDuration constructor that accepts a string as input.
            isValid = iscalendarduration(value) && size(value, 1) == 1 && size(value, 2) == 1;
        end
    end  
end
