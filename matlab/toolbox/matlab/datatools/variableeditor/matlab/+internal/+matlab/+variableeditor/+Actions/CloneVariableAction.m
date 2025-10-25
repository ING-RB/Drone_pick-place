classdef CloneVariableAction < internal.matlab.variableeditor.VEAction
    % CloneVariableAction
    % Clone a variable from an existing document on the Manager

    % Copyright 2018-2022 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'CloneVariable';
        Context = 'VariableEditorContainerView';
    end

    properties(Access=private)
        PopoutDeletionListeners
    end

    methods
        function this = CloneVariableAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CloneVariableAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.CloneVariable;
            this.PopoutDeletionListeners = dictionary;          
        end

        function CloneVariable(this, cloneVariableInfo)
            docID = cloneVariableInfo.docID;
            editorID = cloneVariableInfo.editorId;
            context = cloneVariableInfo.context;
            if isempty(context)
                context = internal.matlab.variableeditor.Actions.CloneVariableAction.Context;
            end
            documents = this.veManager.Documents;
            try
                fileName = char(matlab.internal.editor.VariableManager.getFilenameForEditor(editorID));
                ve_channel = this.getPopoutNamespace(editorID, docID);
                % Popout Manager was not previously created, create Manager
                % and Document.
                if ~(isKey(this.veManager.ClonedVariableList, ve_channel))
                    popoutManager = internal.matlab.variableeditor.peer.VEFactory.createManager(ve_channel, true);
                    docIndex  = this.veManager.docIdIndex(docID);
                    clonedData = documents(docIndex).DataModel.getCloneData();
                    varName = documents(docIndex).DataModel.Name;
                    doc = popoutManager.openvar(varName, 'base', clonedData, UserContext=context);
                    this.CloneViewModelProps(documents(docIndex).ViewModel, doc.ViewModel);
                    this.veManager.ClonedVariableList(ve_channel) = popoutManager;
                    this.PopoutDeletionListeners(ve_channel) = event.listener(popoutManager,...
                        'ObjectBeingDestroyed',...
                        @(es,ed)this.handleCleanup(ve_channel));
                else
                    % Popout Manager already exists for this variable.
                    popoutManager = this.veManager.ClonedVariableList(ve_channel);
                    doc = popoutManager.Documents(1);
                end
                varName = doc.getProperty('name');
                displaySize = doc.getProperty('displaySize');
                type = doc.getProperty('type');
                this.veManager.dispatchEventToClient(struct('type','ClonedVariable','eventType','ClonedVariable',...
                        'clonedDocID',doc.DocID,'channel', popoutManager.Channel, 'parentChannel', this.veManager.Channel, 'fileName',fileName, ...
                        'varName', varName, 'varSize', displaySize, 'varType', type));
            catch e
                disp(e);
            end
        end

        function handleCleanup(this, Channel)
            if isKey(this.PopoutDeletionListeners, Channel)
                this.veManager.cleanupClonedVariableList(Channel);
                lh = this.PopoutDeletionListeners(Channel);
                delete(lh);
                this.PopoutDeletionListeners(Channel) = [];
            end
        end

        function CloneViewModelProps(~, originalViewModel, newViewModel)
            if ~isempty(originalViewModel) && ~isempty(newViewModel)
                columnModelProps = originalViewModel.ColumnModelProperties;
                newViewModel.ColumnModelProperties = columnModelProps;

                % users could have sparklines/ summary stats turned on in
                % outputs. Clone tableModelProps as well.
                tableModelProps = originalViewModel.TableModelProperties;
                newViewModel.TableModelProperties = tableModelProps;

                viewModelProps = originalViewModel.getProperties();
                % Cloned Variable Does not have any selection turned on, do
                % not clone selection property.
                if (isfield(viewModelProps,'Selection'))
                   viewModelProps = rmfield(viewModelProps, 'Selection'); 
                end
                newViewModel.setProperties(viewModelProps);
            end
        end

        function  UpdateActionState(~)
        end
    end

    methods
        function popoutNamespace = getPopoutNamespace(~, channelID, docID)
            popoutNamespace = ['/VE_Popout_' channelID '_' docID];
        end
    end
end

