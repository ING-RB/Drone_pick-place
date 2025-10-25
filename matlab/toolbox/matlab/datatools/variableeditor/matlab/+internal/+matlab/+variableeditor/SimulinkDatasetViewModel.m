classdef SimulinkDatasetViewModel < internal.matlab.variableeditor.ObjectViewModel
    % SIMULINKDATASETVIEWMODEL
    % Initializes the Field Columns and retrieves data from it to be sent to
    % the remote layer.
    
    % Copyright 2021 The MathWorks, Inc.
    
    methods (Access = public)
        % Constructor
        function this = SimulinkDatasetViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ObjectViewModel(dataModel, viewID, userContext);
        end
    end
    
    methods (Access = protected)
        function initFieldColumns(this, ~)
            indexColumn = internal.matlab.variableeditor.FieldColumns.SimulinkDataset.IndexCol();
            indexColumn.setColumnIndex(1);
            this.addFieldColumn(indexColumn);

            valueColumn = internal.matlab.variableeditor.FieldColumns.ValueCol();
            valueColumn.setColumnIndex(2);
            this.addFieldColumn(valueColumn);

            nameColumn = internal.matlab.variableeditor.FieldColumns.SimulinkDataset.NameCol();
            nameColumn.setColumnIndex(3);
            this.addFieldColumn(nameColumn);
            
            blockPathCol = internal.matlab.variableeditor.FieldColumns.SimulinkDataset.BlockPathCol();
            blockPathCol.setColumnIndex(4);
            this.addFieldColumn(blockPathCol);
            blockPathCol.updateBlockPaths(this.DataModel.getDSBlockPaths());
            
            classColumn = internal.matlab.variableeditor.FieldColumns.SimulinkDataset.ClassCol();
            classColumn.setColumnIndex(5);
            this.addFieldColumn(classColumn);
            classColumn.updateClasses(this.DataModel.getDSClasses());
        end

        function fields = getFields(this, ~)
            fields = this.DataModel.getDSElementNames();
        end

        function [cellData, virtualVals, accessVals] = getRenderedCellData(this, ~, ~)
            cellData = this.DataModel.getDSCellData();
            virtualVals = this.DataModel.getDSVirtualVals();
            accessVals = this.DataModel.getDSAccessVals();
        end
    end
end