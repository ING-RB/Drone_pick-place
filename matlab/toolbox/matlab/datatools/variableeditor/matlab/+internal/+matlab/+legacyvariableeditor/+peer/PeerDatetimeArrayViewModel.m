classdef PeerDatetimeArrayViewModel < internal.matlab.legacyvariableeditor.peer.PeerArrayViewModel & ...
        internal.matlab.legacyvariableeditor.DatetimeArrayViewModel &...
        internal.matlab.legacyvariableeditor.VEColumnConstants
    % PEERDATETIMEARRAYVIEWMODEL Peer Model Datetime Array View Model

    % Copyright 2015-2018 The MathWorks, Inc.

    methods
        function this = PeerDatetimeArrayViewModel(parentNode, variable)
            this = this@internal.matlab.legacyvariableeditor.peer.PeerArrayViewModel(parentNode,variable);
            this@internal.matlab.legacyvariableeditor.DatetimeArrayViewModel(variable.DataModel);
            
            if ~isempty(this.DataModel.Data)
                s = this.getSize();
                this.StartRow = 1;
                this.StartColumn = 1;
                this.EndColumn = min(30, s(2));
                this.EndRow = min(80,s(1));
            end

			% Set the renderer types on the table
            widgetRegistryInstance = internal.matlab.datatoolsservices.WidgetRegistry.getInstance();
            widgets = widgetRegistryInstance(1).getWidgets('', 'datetime');

            this.setTableModelProperties(...
                'renderer', widgets.CellRenderer,...
                'editor', widgets.Editor,...
                'inplaceeditor', widgets.InPlaceEditor,...
                'ShowColumnHeaderLabels', false,...
                'ShowRowHeaderLabels', false,...
                'EditorConverter', 'datetimeConverter',...
                'class','datetime');

			% Build the ArrayEditorHandler for the new Document
            import com.mathworks.datatools.variableeditor.web.*;

            if ~isempty(variable.DataModel.Data)
                this.setDefaultColumnWidths(variable.DataModel.Data, internal.matlab.legacyvariableeditor.VEColumnConstants.datetimeColumnWidth);
                this.PagedDataHandler = ArrayEditorHandler(variable.Name,this.PeerNode.Peer,this,this.getRenderedData(1,80,1,30));
            else
                this.PagedDataHandler = ArrayEditorHandler(variable.Name,this.PeerNode.Peer,this);
            end

        end
    end

    methods(Access='public')
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            data = this.getRenderedData@internal.matlab.legacyvariableeditor.DatetimeArrayViewModel(startRow,endRow,startColumn,endColumn);
            renderedData = cell(size(data));

            rowStrs = strtrim(cellstr(num2str((startRow-1:endRow-1)'))');
            colStrs = strtrim(cellstr(num2str((startColumn-1:endColumn-1)'))');

            for row=1:min(size(renderedData,1),size(data,1))
                for col=1:min(size(renderedData,2),size(data,2))
                       jsonData = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON(true, struct('value',data{row,col},...
                                    'editValue',data{row,col},'row',rowStrs{row},'col',colStrs{col}));

                   renderedData{row,col} = jsonData;
                end
            end
            renderedDims = size(renderedData);
        end
    end

    methods(Access='protected')
        function isValid = validateInput(this,value,row,column)
            % Since the client is sending characters we need to try to
            % convert them to a valid datetime object. This requires
            % getting a copy of the actual datetime data and trying an
            % assignment of the form data(row, column) = value. If the
            % result is a datetime, then the value is valid. If an
            % exception occurs, throw a datetime specific error instead of
            % the error sent from handleClientSetData. (g1239590)
            if ischar(value) && size(value, 1) == 1
                try
                    dt = this.getData();
                    dt(row, column) = value;
                    isValid = isdatetime(dt);
                catch
                    error(message('MATLAB:datetime:InvalidFromVE'));
                end
            else
                isValid = false;
            end
        end

        function replacementValue = getEmptyValueReplacement(~,~,~)
            % Empty values should be replaced with NaT.
            replacementValue = datetime('NaT');
        end
    end
end
