classdef DatetimeArrayViewModel < internal.matlab.variableeditor.ArrayViewModel
    %DATETIMEARRAYVIEWMODEL
    %   Datetime Array View Model

    % Copyright 2015-2023 The MathWorks, Inc.

    properties
        % Store the datetime format to use.
        DTFormat string = "";
        isDateTimeFormatActionUpdate = false
    end

    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = DatetimeArrayViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
        end

        % Returns the format for the duration variable.
        function format = getFormat(this)
            format = this.DTFormat;
        end
        
        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            data = this.getData(startRow,endRow,startColumn,endColumn);
            if ~strcmp(data.Format, this.DTFormat)
                % If the preview is changed then we need to set DTFormat to the new
                % format irrespective of the format's length
                if this.isDateTimeFormatActionUpdate
                    this.DTFormat = data.Format;
                    this.isDateTimeFormatActionUpdate = false;
                else
                    % Its possible when scrolling that the datetime format for the given page of data may be different
                    % than the datetime format used elsewhere (for example, dates with hours/minutes/seconds not all 
                    % zero will show with hh:mm:ss, while if they are all 0 may be shown without this).  When this 
                    % happens, stick with the longer format.
                    if strlength(data.Format) > strlength(this.DTFormat)
                        this.DTFormat = data.Format;
                    end
                    data.Format = this.DTFormat;
                end
            end
            [renderedData, renderedDims] = internal.matlab.variableeditor.DatetimeArrayViewModel.getParsedDatetimeData(data);
        end
    
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end
    end
    
    methods(Static)
        function [renderedData, renderedDims] = getParsedDatetimeData(data)
            renderedData = string(data);
            renderedData(ismissing(renderedData)) = "NaT";

            carriageRet = internal.matlab.datatoolsservices.FormatDataUtils.CARRIAGE_RETURN;
            renderedData = replace(renderedData, {carriageRet, newline}, {' ',' '});
            renderedDims = size(renderedData);
        end
    end
end
