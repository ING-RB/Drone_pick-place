classdef CloneVariableAction < internal.matlab.legacyvariableeditor.VEAction
    % CloneVariableAction
    % Clone a variable from an existing document on the Manager

    % Copyright 2018 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'CloneVariable'
    end

    properties
        Manager;
    end

    methods
        function this = CloneVariableAction(props, manager)
            props.ID = internal.matlab.legacyvariableeditor.Actions.CloneVariableAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.legacyvariableeditor.VEAction(props, manager);
            this.Callback = @this.CloneVariable;
            this.Manager = manager;

        end

        function CloneVariable(this, cloneVariableInfo)
            docID = cloneVariableInfo.docID;
            editorID = cloneVariableInfo.editorId;
            context = cloneVariableInfo.context;
            if isempty(context)
                context = 'liveeditor';
            end
            documents = this.Manager.Documents;
            try
                fileName = matlab.internal.editor.VariableManager.getFilenameForEditor(editorID);
                if ~(isKey(this.Manager.ClonedVariableList,docID))
                    docIndex  = this.Manager.docIdIndex(docID);
                    clonedData = documents(docIndex).DataModel.getCloneData();
                    varName = documents(docIndex).DataModel.Name;
                    doc = this.Manager.openvar(varName, 'base', clonedData, context, false);
                    this.CloneViewModelProps(documents(docIndex).ViewModel, doc.ViewModel);
                    clonedDocID = doc.DocID;
                    this.Manager.ClonedVariableList(docID) = clonedDocID;
                else
                    clonedDocID = this.Manager.ClonedVariableList(docID);
                end
                this.Manager.getRoot.dispatchEvent(struct('type','ClonedVariable','docID',clonedDocID,...
                        'channel',this.Manager.Channel,'fileName',fileName));
            catch e
            end
        end

        function CloneViewModelProps(this, originalViewModel, newViewModel)
            if ~isempty(originalViewModel.PeerNode) && ~isempty(newViewModel.PeerNode)
                columnModelProps = originalViewModel.ColumnModelProperties;
                startColumn = 1;
                endColumn = length(columnModelProps); % End of column model properties
                for i=startColumn: endColumn
                    newViewModel.setColumnModelProperties(i, columnModelProps{i});
                end
                viewModelProps = originalViewModel.PeerNode.getProperties;
                newViewModel.PeerNode.setProperties(viewModelProps);
            end
        end

        function  UpdateActionState(this)
            this.Enabled = true;
        end
    end
end

