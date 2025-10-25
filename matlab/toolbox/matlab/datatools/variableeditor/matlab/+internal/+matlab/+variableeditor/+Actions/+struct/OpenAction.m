classdef OpenAction < internal.matlab.variableeditor.VEAction 
    % OPENACTION Open the currently selected field in Variable Editor using
    % openvar

    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
       ActionName = 'VariableEditor.struct.open'
    end
    
    methods
        function this = OpenAction(props, manager)
            if ~isfield(props, 'ID')              
                props.ID = internal.matlab.variableeditor.Actions.struct.OpenAction.ActionName;
            end            
            if ~isfield(props, 'Enabled')              
                props.Enabled = true;
            end        
            this@internal.matlab.variableeditor.VEAction(props, manager);            
            this.Callback = @this.openVariable;
        end
         
        function UpdateActionState(~)
        end        
    end
    
    methods(Access='protected')
        function openVariable(this, eventData, forceExecute)
            arguments
                this
                eventData = struct
                forceExecute = false;
            end
            import internal.matlab.variableeditor.Actions.ActionUtils;
            focusedDoc = this.veManager.FocusedDocument;
            focusedView = focusedDoc.ViewModel; 
            % If actionInfo exists, this means varName was passed along from client. 
            % Use that for quicker response instead of querying from selection.
            if isfield(eventData, 'actionInfo')
                actionParams = eventData.actionInfo;
                selectedFields = string(actionParams.varName);
            else
                selectedFields = focusedView.getSelectedFields(); 
            end         
            internal.matlab.datatoolsservices.logDebug("variableeditor::OpenAction::", "SelectedFields: " + selectedFields);
            ws = focusedDoc.Workspace;
            if (this.veManager.getProperty('AppContext'))
                this.handleCustomContext(focusedDoc);    
                return;
            end
            
            hasCustomWorkspace = ~ischar(ws) || internal.matlab.datatoolsservices.VariableUtils.isCustomCharWorkspace(ws);
            if ~isempty(focusedView) && ~isempty(selectedFields)                
                for i=1:length(selectedFields)
                    varname = selectedFields(i);
                    [singlecmd, editorName] = this.getOpenvarCommand(varname, focusedView);
                    % If the document has a custom workspace, openvar on
                    % Manager directly with the correct workspace and userContext. 
                    if hasCustomWorkspace
                        try
                            this.veManager.openvar(editorName, ws, evalin(ws, editorName), UserContext=focusedDoc.UserContext);
                        catch e
                            internal.matlab.datatoolsservices.logDebug("variableeditor::OpenAction::", "Error having manager openvar: " + e);
                        end
                    else
                        if i==1
                            cmd = singlecmd;
                        else
                            cmd = strcat(cmd, " ", singlecmd);
                        end
                    end
                end
                if ~hasCustomWorkspace
                    if forceExecute
                        this.executeCommand(cmd);
                    else
                        codePublishingChannel = focusedDoc.DataModel.CodePublishingDataModelChannel;
                        ActionUtils.publishCode(codePublishingChannel, cmd);
                    end
                end
            end
        end
        
        % Handles OpenSelection for custom context apps. Notify event on
        % the document.
        function handleCustomContext(~, focusedDoc)
            focusedView = focusedDoc.ViewModel;
            ss = focusedView.getSelection;
            rowSelection = ss{1};
            rowIndices = [];
            for i = rowSelection'
                rowIndices = [rowIndices i(1):i(2)];
            end
            colIndices = unique(ss{2});
            ed = internal.matlab.variableeditor.OpenVariableEventData;
            ed.row = rowIndices;
            ed.column = colIndices(1): colIndices(2);
            ed.workspace = focusedDoc.Workspace;
            ed.variableName = focusedView.SelectedFields;
            focusedDoc.notify('OpenSelection', ed);
        end
        
        function executeCommand(~, cmd)
            internal.matlab.variableeditor.Actions.ActionUtils.executeCommand(cmd);
        end
        
        function [cmd, editorName] = getOpenvarCommand(~, selectedField, view)
            openvarcmd = "openvar(""%s"");";            
            editorName = view.getSubVarName(view.DataModel.Name, selectedField);
            cmd = sprintf(openvarcmd, editorName);
        end
    end
end

