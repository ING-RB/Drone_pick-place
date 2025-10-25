classdef ApplyAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.variableeditor.Actions.CategoricalCleaning.CleanCategoriesActionBase
    % ApplyAction

    % Copyright 2018-2024 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'ApplyAction';
    end

    methods
        function this = ApplyAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CategoricalCleaning.ApplyAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.Callback = @this.Apply;
            this.Manager = manager;
        end

        function Apply(this, editInfo)
            doc = this.getOutputDocument(this.Manager, editInfo.docID);

            % retrieve the cleaned data information from the cleaner
            outputName = doc.Workspace.getOutputName();
            cleanedTableData = doc.Workspace.(outputName);

            % retrieve the output document being cleaned and update the
            % view
            outputManager = this.getOutputManager();
            outputDocumentID = editInfo.actionInfo.outputDocumentID;
            outputDoc = this.getOutputDocument(outputManager, editInfo.actionInfo.outputDocumentID);
            this.updateOutputView(outputDoc, cleanedTableData);

            % get the filter manager
            this.updateFilteredData(outputDocumentID, cleanedTableData);

            % publish the generated code
            this.publishGeneratedCode(outputDoc, outputDocumentID, doc);

            % destroy the categorical cleaner manager
            this.deleteCategoricalCleanerManager();
        end

        function publishGeneratedCode(this, outputDoc, outputDocumentID, doc)
            actionStateHandler = outputDoc.ViewModel.ActionStateHandler;
            workspace = doc.Workspace;
            % loop through the code generated array stored on the workspace
            workspaceCommandArray = workspace.getCodeGeneratedArray();
            colIndex = this.getCategoricalColumnIndex(doc);
            outputDoc = this.getOutputDocument([], outputDocumentID);
            isMOTWContext = contains(outputDoc.ViewModel.userContext, 'MOTW');
            for i=1:length(workspaceCommandArray)
                % NOTE: move the updateFilteredData to a common ActionUtils
                % or a BoundaryActionBase that both Apply and ConvertTo can
                % utilize.
                if ~isMOTWContext
                    % TODO: Refactor to include a better way to update filtered data
                    handleCleanupCommand = ['internal.matlab.variableeditor.Actions.ConvertToDataTypeAction.updateFilteredData(''' outputDocumentID ''',tempDM);'];
                    workspaceCommandArray(i).executeCode{1} = [workspaceCommandArray(i).executeCode{1} handleCleanupCommand];
                    currentCmd = struct('Command', "Clean", 'Index', colIndex, 'commandInfo', workspaceCommandArray(i).commandInfo, ...
                        'generatedCode', {workspaceCommandArray(i).publishCode}, 'executionCode', {workspaceCommandArray(i).executeCode});
                    actionStateHandler.CommandArray = [actionStateHandler.CommandArray, currentCmd];
                    actionStateHandler.getCodegenCommands(colIndex, "Clean");
                    actionStateHandler.publishCode();
                else
                    % If MOTW Context, publish UserDataInteraction instead of
                    % directly updating CommandArray. VEInteractionHandler will
                    % mark IgnoreUpdate accordingly for undo workflow.
                    % Publish to any MATLAB listeners on the View
                    eventdata = internal.matlab.variableeditor.VariableInteractionEventData;
                    eventdata.UserAction = '';
                    eventdata.Index = colIndex;
                    cmd = workspaceCommandArray(i).publishCode;
                    if ~iscell(cmd)
                        cmd = {cmd};
                    end
                    eventdata.Code = cmd;
                    outputDoc.ViewModel.notify('UserDataInteraction', eventdata);
                    actionStateHandler.getCodegenCommands(colIndex, "ToolstripAction");
                    actionStateHandler.publishCode();
                end
            end
        end

        % updates the output view
        function updateOutputView(~, outputDoc, cleanedTableData)
            outputDataModel = outputDoc.DataModel;
            outputDataModel.Data = cleanedTableData;
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            dims = size(outputDataModel.Data);
            eventdata.StartRow = 1;
            eventdata.EndRow = dims(1);
            eventdata.StartColumn = 1;
            eventdata.EndColumn = dims(2);
            eventdata.SizeChanged = false;
            % Mark EventSource as 'InternalDmUpdate' such that
            % VEInteractionHandler can handle this accordingly on DataChange.
            eventdata.EventSource = 'InternalDmUpdate';
            outputDataModel.notify('DataChange', eventdata);
        end

        % updates the filtered view
        function updateFilteredData(~, outputDocumentID, newData)
            filterManagerChannel = strcat('/VE/filter', outputDocumentID);
            filterManager = internal.matlab.variableeditor.peer.VEFactory.createManager(filterManagerChannel, false);
            % in case of grouped columns, filtering does not exist
            if ~isempty(filterManager.Documents)
                tws = filterManager.Workspaces('filterWorkspace');
                tws.updateTableAndResetCache(newData, outputDocumentID);
            end
        end

        % retrieves the output manager
        function outputManager = getOutputManager(this)
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance();
            outputManagerChannel = this.Manager.Channel(1: strfind(this.Manager.Channel, this.CategoricalCleanerManager)-1);
            mgrInstances = factory.getManagerInstances();
            outputManager = mgrInstances(outputManagerChannel);
        end

        % deletes the categorical cleaner manager
        function deleteCategoricalCleanerManager(this)
            this.Manager.closeAllVariables();
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance();
            factory.deleteManager(this.Manager.Channel, true);
        end

        function  UpdateActionState(this)
           this.Enabled = true;
        end
    end
end
