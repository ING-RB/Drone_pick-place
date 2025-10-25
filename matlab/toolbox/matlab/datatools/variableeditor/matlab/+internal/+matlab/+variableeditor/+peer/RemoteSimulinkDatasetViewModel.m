classdef RemoteSimulinkDatasetViewModel < internal.matlab.variableeditor.peer.RemoteObjectViewModel & ...
        internal.matlab.variableeditor.SimulinkDatasetViewModel
    % REMOTESIMULINKDATASETVIEWMODEL
    % Remote layer for Simulink Dataset. Gets rendered data from
    % SimulinkDataSetViewModel and reformats it to display in JSON.
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    methods
        function this = RemoteSimulinkDatasetViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.SimulinkDatasetViewModel(variable.DataModel, viewID, userContext);
            this@internal.matlab.variableeditor.peer.RemoteObjectViewModel(document, variable, viewID, userContext);
        end

        function s = getSize(this)
            s = [this.DataModel.Data.numElements() this.VisibleFieldColumnList.Count];
            % Return size as double as we might compute viewport based on
            % min/max on size.
            s = double(s);
        end
    end

    methods (Access = protected)

        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteSimulinkDatasetViewModel';
        end

        % Update Field Column cache when any data is changed
        function handleDataChangedOnDataModel(this, es, ed)
            blockPathCol = this.findFieldByHeaderName('BlockPath');
            blockPathCol.updateBlockPaths(this.DataModel.getDSBlockPaths());

            classCol = this.findFieldByHeaderName('Class');
            classCol.updateClasses(this.DataModel.getDSClasses());

            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.peer.RemoteObjectViewModel(es, ed);
        end

        function [renderedData, renderedDims] = renderData(this, data, classValues, fields, accessValues, ...
                startRow, endRow, startColumn, endColumn)
            arguments (Input)
                this
                data         (:,:) cell
                classValues  (:,1) cell
                fields       (1,:) cell
                accessValues (1,:) cell % {'public', 'protected', 'private'}
                startRow     (1,1) double
                endRow       (1,1) double
                startColumn  (1,1) double
                endColumn    (1,1) double
            end

            arguments (Output)
                renderedData cell
                renderedDims (1,2) double
            end

            numColumnsRequested = endColumn - startColumn + 1;
            renderedData = cell(size(data,1), numColumnsRequested);
            this.CellModelChangeListener.Enabled = false;
            CellMetaDataColIndices = [];
            % For each of the rows of rendered data, create the json object
            % string for each column's data.
            for row = 1:size(renderedData, 1)
                for col = startColumn:endColumn
                    val = data{row,col};
                    dataObj = struct('value', val);
                    classVal = classValues{row};
                    fName = fields{col}.getHeaderName();
                    if any(strcmp(fName, ["Name", "Value"]))
                        if fName == "Name"
                            dataObj.class = classVal;
                            if ~isempty(accessValues)
                                dataObj.access = accessValues(row);
                            end
                        else
                            if strcmp(classVal,'string')
                                dataObj.class = classVal;
                            end
                            dataObj.editable = fields{col}.Editable;
                            this.setCellModelProperty(row, col,...
                                'editable', false);
                            CellMetaDataColIndices = union(CellMetaDataColIndices, col);

                            editorRowNumber = startRow + row - 1;
                            dataObj.editorValue = this.DataModel.Name + "{" + editorRowNumber + "}";
                        end
                    else
                        dataObj.editable = fields{col}.Editable;
                    end
                    renderedData{row, col} = jsonencode(dataObj);
                end
            end

            this.CellModelChangeListener.Enabled = true;
            if ~isempty(CellMetaDataColIndices)
                this.updateCellModelInformation(startRow, endRow, min(CellMetaDataColIndices), max(CellMetaDataColIndices));
            end
            renderedDims = size(renderedData);
        end
    end % methods
end
