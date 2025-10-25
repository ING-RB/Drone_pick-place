classdef CustomWidthsPlugin < internal.matlab.variableeditor.peer.plugins.MetaDataPlugin
    %CUSTOMWIDTHSPLUGIN 
    % This plugin computes custom widths based on cell contents and sets them as columnModelProps 
    
    % Copyright 2019-2024 The MathWorks, Inc.
    properties
        CustomColumnWidths;
        CharacterWidth;
        ViewClassType;
    end

    properties(Transient)
        PropertySetListener;
    end

    properties (Constant)
        % By default, use a pre-computed single character width on
        % monospace fonts. If we do not hear back from client on time, use these values instead. 
        DEFAULT_CHAR_WIDTH = 6.59375;
        % Start with 14 rows, make this customizable in the future.
        MAX_ROW_LIMIT = 10;
        MAX_CELL_LIMIT = 30;
        LEADING_SPACES_LENGTH = 3;
        MIN_COLUMN_WIDTH = 82;
        
    end   
    
    methods
        % Constructor inherits from MetaDataplugin and adds propertyset
        % listener for getting browser CharacterWidth for monospace fonts.
        function this = CustomWidthsPlugin(viewModel)
            this@internal.matlab.variableeditor.peer.plugins.MetaDataPlugin(viewModel);   
            this.CustomColumnWidths = [];
            this.ViewClassType = class(viewModel.DataModel.Data);
            this.PropertySetListener = event.listener(viewModel,'PropertySet',@this.handlePropertySet);
            if isempty(this.CharacterWidth)
                this.CharacterWidth = this.DEFAULT_CHAR_WIDTH;
            end
            this.NAME = 'SERVER_CUSTOM_WIDTHS';
        end
        
        % Set characterWidth class property.
        function handlePropertySet(this, ~, ed)
            if isa(ed, 'internal.matlab.variableeditor.CharacterWidthEventData')
                this.CharacterWidth = ed.CharacterWidth.value;
            end
        end
        
        % This is called whenever metadata changes or is requested from
        % client. Compute ColumnWidth based on cellContent length and
        % characterWidths.
        function updateColumnModelInformation(this, startCol, endCol)            
            for columnIndex=startCol:endCol
                 % check to see if this can be optimized
                size = this.ViewModel.getTabularDataSize;
                rowLimit = min(size(1), this.MAX_ROW_LIMIT);
                % Note, the views have some additional formatting for
                % display that might affect cell content length. Ideally,
                % we should be able to get formatted Data without JSON'ed
                % data. TODO: Refactor views such that these responsibilities are separate. 
                data = this.ViewModel.getRenderedData(1, rowLimit, columnIndex, columnIndex);
                maxWidth = 0;
                for rowIndex = 1: rowLimit                    
                    cellContent = this.getParsedCellData(data{rowIndex});
                    cellLength = this.LEADING_SPACES_LENGTH + length(cellContent);
                    maxWidth = min(max(maxWidth, cellLength), this.MAX_CELL_LIMIT);
                end
                this.CustomColumnWidths(columnIndex) = maxWidth;                
                columnWidth = max(ceil(maxWidth * this.CharacterWidth), this.MIN_COLUMN_WIDTH);
                this.ViewModel.setColumnModelProperty(columnIndex, 'ColumnWidth', columnWidth, false);
            end            
        end
        
        % getParsedCellData fetches contents from the rendererdData
        % assuming that data is in a json format
        function cellData = getParsedCellData(this, renderedData)
            jsonData = jsondecode(renderedData);
            isMetaData = false;
            if (isfield(jsonData, 'isMetaData'))
                isMetaData = jsonData.isMetaData;
            end
            cellData = this.getCellDataBasedOnType(jsonData.value, isMetaData);
        end
        
        % Returns cellContent based on viewType. 
        % TODO: Allow the view to deal with quoted strings. 
        function cellContent = getCellDataBasedOnType(this, cellData, isMetadata)            
            if (isequal(this.ViewClassType, 'string') && ~isMetadata)
               cellContent = ['"' cellData '"'];
            else
               cellContent = cellData; 
            end            
        end

        function handled = handleEventFromClient(~, ~)
            handled = false;
        end
    end
end

