classdef CharArrayViewModel < internal.matlab.variableeditor.ArrayViewModel
    %CHARARRAYVIEWMODEL
    %   Char Array View Model

    % Copyright 2014-2021 The MathWorks, Inc.
 
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = CharArrayViewModel(dataModel, viewID, userContext)
             if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
        end
        
        function [renderedData, renderedDims] = getDisplayData(this,startRow,endRow,startColumn,endColumn)
            data = this.getData(startRow,endRow,startColumn,endColumn); %#ok<NASGU>
            
            % always 1x1 cell view
            renderedData = evalc('disp(data)');
            % evalc disp values return a newline, strip newline at end.
            % newlines and tabs are handled just like string arrays.
            if endsWith(renderedData, newline)
                renderedData = renderedData(1:end-1);
            end
            % ignore carriage returns
            renderedData = strrep(renderedData, sprintf('\r'),'');
            
            if length(renderedData) > internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH
                renderedData = [strjoin(split(num2str(size(renderedData))), this.TIMES_SYMBOL) ' char'];
            end

            % returns 'true' size
            renderedDims = size(renderedData);
        end

        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end
        
        % The view model's getSize should always return the values [1 1] 
        % since the view is always a 1x1 cell
        function s = getSize(~)
             % always 1x1 cell view
             s = [1 1];
        end
    end
end


