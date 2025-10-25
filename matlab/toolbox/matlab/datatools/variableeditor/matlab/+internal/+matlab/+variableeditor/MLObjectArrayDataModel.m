classdef MLObjectArrayDataModel < ...
        internal.matlab.variableeditor.MLArrayDataModel & ...
        internal.matlab.variableeditor.ObjectArrayDataModel & ...
        internal.matlab.variableeditor.TimerBasedDataModel
    %MLOBJECTARRAYDATAMODEL
    % MATLAB Object Array Data Model

    % Copyright 2015-2023 The MathWorks, Inc.

    events
        CellMetaDataChanged
    end

    methods
        % Constructor
        function this = MLObjectArrayDataModel(name, workspace, useTimer)
            arguments
                name
                workspace
                useTimer (1,1) logical = true
            end

            this@internal.matlab.variableeditor.MLArrayDataModel(...
                name, workspace);
            this@internal.matlab.variableeditor.TimerBasedDataModel(useTimer);
        end

        function s = getDataSize(this, data)
            s(1) = length(data);
            s(2) = length(this.getProperties(data));
        end

        function data = variableChanged(this, varargin)
            if ~isobject(this.Data) || (ismethod(this.Data, 'isvalid') && ~all(isvalid(this.Data),'all'))
                this.updateCaches();
            end
            data = this.variableChanged@internal.matlab.variableeditor.MLArrayDataModel(varargin{:});
        end
    end

    methods (Access = protected)
        function [I,J] = doCompare(this, newData)
            [I,J] = find(arrayfun(@(a,b) ~isequal(a,b), ...
                this.Data, newData));
        end

        % On metadata differences, check to see if Prperties
        % have changed and notify [type]MetadataChanged on DataModel.
        function handleMetaDataUpdate(this, newData, origData, sizeChanged, rowDiff, columnDiff)
            if nargin<4
                sizeChanged = false;
            end
            % 1. For column name changes, just detect the actual changes
            oldProps = this.getProperties(origData);
            newProps = this.getProperties(newData);
            if sizeChanged
                metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                metaDataEvent.Row = 1;
                metaDataEvent.Column = 1:length(newProps);
                this.notify('CellMetaDataChanged', metaDataEvent);

            else
                metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                [~, colDiffIndices] = (setdiff(oldProps, newProps));
                if ~isempty(colDiffIndices)
                    metaDataEvent.Row = 1;
                    metaDataEvent.Column = colDiffIndices;
                else
                    % Update entire indices, if multiple indices have
                    % changed, refresh upto the changed viewport.
                    metaDataEvent.Row = rowDiff;
                    metaDataEvent.Column = columnDiff;
                end
                this.notify('CellMetaDataChanged', metaDataEvent);
            end
        end
    end
end
