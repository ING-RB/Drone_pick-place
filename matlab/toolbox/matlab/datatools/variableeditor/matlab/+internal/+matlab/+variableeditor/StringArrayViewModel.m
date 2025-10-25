classdef StringArrayViewModel < internal.matlab.variableeditor.ArrayViewModel
    %STRINGARRAYVIEWMODEL
    %   String Array View Model
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    
    properties(Access='public', Constant=true)
        % NO need to escape new lines and tabs, They will show up as
        % unicode symbols when json encoded and be treated as control
        % characters on the client.
        ESCAPES = {char(0)}; % Characters to escape
        ESCAPED = {' '}; % Escaped versions of characters
        MULTIPLYCHAR = internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL;
    end

    properties (SetObservable=true, SetAccess='private', Transient)
        CellMetaDataChangedListener;
    end
    
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = StringArrayViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
            this.initListeners();
        end
        
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims, metaData] = getRenderedData(this, startRow, endRow, startColumn, endColumn)
           [renderedData, renderedDims, metaData] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end
        
        function [renderedData, renderedDims, metaData] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            data = this.getData(startRow,endRow,startColumn,endColumn);
            [renderedData, renderedDims, metaData] = internal.matlab.variableeditor.StringArrayViewModel.getParsedStringData(data);
        end
        
        % Cleanup any listeners that were attached at constructor time
        function delete(this)
            if ~isempty(this.CellMetaDataChangedListener)
                delete(this.CellMetaDataChangedListener);
                this.CellMetaDataChangedListener = [];
            end          
        end
    end
    
    methods(Access='protected')
        function initListeners(this)
            this.CellMetaDataChangedListener = event.listener(this.DataModel,'CellMetaDataChanged',@(es,ed) this.notify('CellMetaDataChanged', ed));
        end
    end
    
    methods(Static)
        function [renderedData, renderedDims, metaData] = getParsedStringData(data)

            escapes = internal.matlab.variableeditor.StringArrayViewModel.ESCAPES;
            escaped = internal.matlab.variableeditor.StringArrayViewModel.ESCAPED;
            multiplyChar = internal.matlab.variableeditor.StringArrayViewModel.MULTIPLYCHAR;
            
            renderedData = data;
        
            % Get the indices of the missing elements and replace with
            % "<missing>"
            missingInds = ismissing(renderedData);
            renderedData(missingInds) = "<missing>";
        
            % Get the indices of elements whose length exceeds
            % MAX_TEXT_DISPLAY_LENGTH and replace with "1x1 string"
            overflowInds = (strlength(renderedData) > internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH);
            renderedData(overflowInds) = "1"+multiplyChar+"1 string";
        
            % Replace escape characters with their corresponding escaped
            % chars
            renderedData = replace(renderedData,escapes,escaped);
        
            % Calculate the final metadata and size of the output array
            metaData = missingInds | overflowInds;
            renderedDims = size(renderedData);
        end        
    end
end


