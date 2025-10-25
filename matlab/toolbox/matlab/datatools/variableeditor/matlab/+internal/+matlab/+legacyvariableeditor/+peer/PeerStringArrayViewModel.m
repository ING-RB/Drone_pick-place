classdef PeerStringArrayViewModel < ...
        internal.matlab.legacyvariableeditor.peer.PeerArrayViewModel & ...
        internal.matlab.legacyvariableeditor.StringArrayViewModel
    % PeerStringArrayViewModel Peer Model View Model for string array
    % variables
    
    % Copyright 2015-2018 The MathWorks, Inc.
        
    methods
        function this = PeerStringArrayViewModel(parentNode, variable)
            this = this@internal.matlab.legacyvariableeditor.peer.PeerArrayViewModel(parentNode, variable);
            this@internal.matlab.legacyvariableeditor.StringArrayViewModel(variable.DataModel);

            % Build the ArrayEditorHandler for the new Document
            import com.mathworks.datatools.variableeditor.web.*;
            this.PagedDataHandler = ArrayEditorHandler(variable.Name,this.PeerNode.Peer,this,this.getRenderedData(1,80,1,30));
            
            % Set the renderer types on the table
            widgetRegistryInstance = internal.matlab.datatoolsservices.WidgetRegistry.getInstance();
            widgets = widgetRegistryInstance(1).getWidgets('', 'string');
            this.setTableModelProperties(...
                'renderer', widgets.CellRenderer,...
                'editor', widgets.Editor,...
                'inplaceeditor', widgets.InPlaceEditor,...
                'ShowColumnHeaderLabels', false,...
                'ShowRowHeaderLabels', false,...
                'RemoveQuotedStrings',true,...
                'class', 'string');
        end
        
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims, shortenedValues] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            [data, ~, shortenedValues, metaData] = this.getRenderedData@internal.matlab.legacyvariableeditor.StringArrayViewModel(startRow,endRow,startColumn,endColumn);
            renderedData = cell(size(data));
            [startRow, endRow, startColumn, endColumn] = internal.matlab.datatoolsservices.FormatDataUtils.resolveRequestSizeWithObj(...
                startRow, endRow, startColumn, endColumn, size(this.getData));

            % Use metadata determined from getRenderedData.  It is limited to the same
            % range as the data
            missingStr = metaData; 
            
            this.setCurrentPage(startRow, endRow, startColumn, endColumn, false);
            
            rowStrs = strtrim(cellstr(num2str((startRow-1:endRow-1)'))');
            colStrs = strtrim(cellstr(num2str((startColumn-1:endColumn-1)'))');
            
            for row=1:min(size(renderedData,1),size(data,1))
                for col=1:min(size(renderedData,2),size(data,2))
                    dataValue = data{row,col};
                    shortValue = shortenedValues{row,col};
                        
                    jsonData = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON(true,...
                        struct('value',shortValue,...
                        'editValue',dataValue,...
                        'isMetaData', missingStr(row,col), ...
                        'row',rowStrs{row},...
                        'col',colStrs{col}));
                    
                    renderedData{row,col} = jsonData;
                end
            end
            renderedDims = size(renderedData);
        end
    end
    
    methods(Access='protected')
        function replacementValue = getEmptyValueReplacement(~, ~, ~) 
            replacementValue = '';
        end
        
        function classType = getClassType(this, ~, ~)
            classType = class(this.DataModel.Data);
        end  
    end
end
