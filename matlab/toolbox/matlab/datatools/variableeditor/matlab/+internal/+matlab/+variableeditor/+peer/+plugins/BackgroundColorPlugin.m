%BackgroundColorPlugin Plugin to set cell colors in a performant way, only updates cell model properties when client-requests that region.
% Multiple colors can be set, last in wins

% Copyright 2024 The MathWorks, Inc.
classdef BackgroundColorPlugin < internal.matlab.variableeditor.peer.plugins.MetaDataPlugin 
    properties (Access='protected')
        ColorQueue % Struct array of colors and indices
    end

    methods
        function this = BackgroundColorPlugin(viewModel)
            this@internal.matlab.variableeditor.peer.plugins.MetaDataPlugin(viewModel);
            this.ColorQueue = [];
            this.NAME = "BACKGROUND_COLOR_PLUGIN";
        end
        
        function setColorIndices (this, colorIndices, color)
            colorData = struct(ColorArray=colorIndices, Color=color);
            if isempty(this.ColorQueue)
                this.ColorQueue = colorData;
            else
                this.ColorQueue(end+1) = colorData;
            end

            eventdata = internal.matlab.datatoolsservices.data.ModelChangeEventData;
            [rows,cols] = find(colorIndices);
            eventdata.Row = min(rows):max(rows);
            eventdata.Column = min(cols):max(cols);
            this.ViewModel.notify('CellMetaDataChanged', eventdata);  
        end

        function clearColors(this)
            this.ColorQueue = [];

            s = this.ViewModel.getSize();

            eventdata = internal.matlab.datatoolsservices.data.ModelChangeEventData;
            eventdata.Row = 1:s(1);
            eventdata.Column = 1:s(2);
            this.ViewModel.notify('CellMetaDataChanged', eventdata);  
        end
        
        function updateCellModelInformation(this, startRow, endRow, startColumn, endColumn)
            if isempty(this.ColorQueue)
                return;
            end

            this.ViewModel.pauseListener('CellModelChangeListener');
            for cqIndex=1:length(this.ColorQueue)
                colorQueueItem = this.ColorQueue(cqIndex);

                colorIndices = colorQueueItem.ColorArray(startRow:endRow, startColumn:endColumn);
                [rows,cols] = find(colorIndices);
                rows = rows+startRow-1;
                cols = cols+startColumn-1;
                for i=1:length(rows)
                    currentStyle = this.ViewModel.getCellModelProperty(rows(i), cols(i), 'style');
                    jsStyle = this.getModifiedStyle(currentStyle, colorQueueItem.Color);
                    this.ViewModel.setCellModelProperty(rows(i), cols(i), 'style', jsStyle);
                end
            end
            this.ViewModel.resumeListener('CellModelChangeListener');
        end

        function newStyle = getModifiedStyle(~, currentStyle, delta)
            newStyle = struct;
            if isstruct(delta)
                deltaFields = fieldnames(delta);
                for i=1:length(deltaFields)
                    fieldName = deltaFields{i};
                    fieldValue = delta.(fieldName);
                    if ~isempty(fieldValue)
                        newStyle.(fieldName) = fieldValue;
                    end
                end

                if isstruct(currentStyle)
                    currFields = fieldnames(currentStyle);
                    for i=1:length(currFields)
                        fieldName = currFields{i};
                        fieldValue = currentStyle.(fieldName);
                        if ~isempty(fieldValue) && ~ismember(fieldName, deltaFields)
                            newStyle.(fieldName) = fieldValue;
                        end
                    end
                end
            end
        end

        function handled = handleEventFromClient(~, ~)
            handled = false;
        end
    end
end

