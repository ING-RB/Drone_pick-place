classdef ColumnTransformationAction < internal.matlab.variableeditor.VEAction ...
        & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles table column transformations by opening the Column
    %  Transformation Dialog then publishing code.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Constant)
        ActionName = 'ColumnTransformationAction';
    end
    
    properties (Access={?matlab.internal.datatools.widgets.ColumnTransformationDialog, ?matlab.unittest.TestCase})
        LastCmd
        LastExecutionCmd
        LastDialog
    end

    methods
        function this = ColumnTransformationAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.table.ColumnTransformationAction.ActionName;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
        end

        function UpdateActionState(~)
        end
        
        function delete(this)
            if ~isempty(this.LastDialog) && isvalid(this.LastDialog) && isvalid(this.LastDialog.ColumnTransformationUIFigure)
                delete(this.LastDialog.ColumnTransformationUIFigure);
            end
        end
    end

    methods(Access='protected')
        % This method generates cmd to convert datatype for the selected
        % column based on the conversionType. For datetime/duration,
        % dataTypeOption is used to generate the InputFormat attribute.
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, opts)
            executionCmd = "";
            varName = focusedDoc.Name;
            columnIndex = focusedDoc.ViewModel.SelectedColumnIntervals(1);
            colName = focusedDoc.ViewModel.getHeaderInfoFromIndex(columnIndex);
            data = focusedDoc.ViewModel.DataModel.Data;
            code = string.empty;
            if isprop(data, 'VarEditorEquation')
                code = data.Properties.CustomProperties.VarEditorEquation(columnIndex);
            end
            ctd = matlab.internal.datatools.widgets.ColumnTransformationDialog(varName, colName, data, code, false);
            block = true; % Default behavior
            if ~isempty(opts) && isfield(opts, 'Block') % Used for testing
                block = opts.Block;
            end
            if ~block
                ctd.OKCallbackFcn = @()this.okCallback(ctd);
                ctd.CancelCallbackFcn = @()this.cancelCallback(ctd);
                this.LastDialog = ctd;
            end
            [cmd, outputVarName] = ctd.showDialog('Block', block);
            if block
                delete(ctd.ColumnTransformationUIFigure);
            end

            % Save the command into the table
            if ~isempty(cmd)
                if ~isprop(data, 'VarEditorEquation')
                    executionCmd = varName + " = addprop(" + varName + ", 'VarEditorEquation', {'Variable'});";
                end
                if ~isvarname(outputVarName)
                    [~,outputVarName,~] = matlab.internal.tabular.generateVariableNameAssignmentString(data, 1, outputVarName, varName);
                end
                executionCmd = executionCmd + varName + ".Properties.CustomProperties.VarEditorEquation(" + outputVarName + ") = """ + cmd + """;";
            end
        end

        function cancelCallback(this, ctd)
            % Used for testing purposes, if we don't block then we need to
            % have a way for tests to get the cmd back
            this.LastCmd = string.empty;
            this.LastExecutionCmd = string.empty;

            delete(ctd.ColumnTransformationUIFigure);
        end

        function okCallback(this, ctd)
            % Used for testing purposes, if we don't block then we need to
            % have a way for tests to get the cmd back
            cmd = ctd.Code;
            executionCmd = "";
            if ~isempty(cmd)
                data = ctd.OriginalTable;
                varName = ctd.TableName;
                outputVarName = ctd.ColumnName;
                if ~isprop(data, 'VarEditorEquation')
                    executionCmd = varName + " = addprop(" + varName + ", 'VarEditorEquation', {'Variable'});";
                end
                executionCmd = executionCmd + varName + ".Properties.CustomProperties.VarEditorEquation('" + outputVarName + "') = """ + cmd + """;";
                try
                    publishingChannel = this.Manager.FocusedDocument.DataModel.CodePublishingDataModelChannel;
                    this.publishCode(publishingChannel, cmd, executionCmd);
                catch e
                    disp(e.message);
                    e.stack;
                end
            end
            this.LastCmd = cmd;
            this.LastExecutionCmd = executionCmd;

            delete(ctd.ColumnTransformationUIFigure);
        end
    end
end


