classdef MLStructureArrayDataModel < internal.matlab.variableeditor.MLArrayDataModel & internal.matlab.variableeditor.StructureArrayDataModel
        
    %MLSTRUCTUREARRAYDATAMODEL
    %   MATLAB Structure Array Data Model

    % Copyright 2014-2021 The MathWorks, Inc.
    events
        CellMetaDataChanged
        ColumnMetaDataChanged
    end

    methods(Access='public')
        % Constructor
        function this = MLStructureArrayDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(name, workspace);
        end       
    end 
    
    methods(Access='protected')
        % NOTE: doCompare is currently called to generate diff indices
        % after detecting an inequality check. It is more performant to
        % update the viewport than to run comparisons.
        function [I,J] = doCompare(this, newData)
            sz = size(this.DataAsCell);
            I = [1 sz(1)];
            J = [1 sz(2)];                
        end
        
        % On metadata differences, check to see if VariableNames or
        % rowNames have changed and notify [type]MetadataChanged on DataModel. 
        function handleMetaDataUpdate(this, newData, origData, sizeChanged, rowDiff, columnDiff)
            if nargin<4
                sizeChanged = false;
            end
            % 1. For column name changes, just detect the actual changes
            oldFields = fields(origData);
            newFields = fields(newData);
            if sizeChanged                                
                metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                metaDataEvent.Row = 1;
                metaDataEvent.Column = 1:length(oldFields); % Assume all columns have changed if size changed
                this.notify('CellMetaDataChanged', metaDataEvent);
                this.notify('ColumnMetaDataChanged', metaDataEvent); % This is needed to make sure column headers update properly
            else
                metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                [~, colDiffIndices] = (setdiff(oldFields, newFields));
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
    
    methods(Access='public')    
        function dims = getDataSize(~, data)
            % return the size as the number of rows and number of fields
            % this is necessary since the size method on structure array
            % does not reflect the change in the number of fields
            dims = [size(data,1) size(data,2) length(fields(data))];
        end
        
        function eq = equalityCheck(this, oldData, newData)
            eq = this.equalityCheck@internal.matlab.variableeditor.StructureArrayDataModel(oldData, newData);
        end
    end
end

