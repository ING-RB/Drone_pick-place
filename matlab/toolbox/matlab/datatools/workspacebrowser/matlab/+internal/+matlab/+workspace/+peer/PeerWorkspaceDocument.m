classdef PeerWorkspaceDocument < internal.matlab.workspace.MLWorkspaceDocument & internal.matlab.legacyvariableeditor.peer.PeerVariableNode
    %PeerWorkspaceDocument PeerModel Variable Document

    % Copyright 2013-2021 The MathWorks, Inc.

    % Property Definitions:
    
    properties (Constant)
        % PeerNodeType
        PeerNodeType = '_WorkspaceDocument_';
    end

    properties (Dependent = true)
        DocID;
    end
        
    methods
        % Constructor
        function this = PeerWorkspaceDocument(root, manager, variable, userContext)
            mlock; % Keep persistent variables until MATLAB exits
            persistent docIDCounter;
            if isempty(docIDCounter)
                docIDCounter = 0;
            end
            docIDCounter = docIDCounter+1;
            ws = variable.getDataModel.Workspace;
            wsKey = manager.getWorkspaceKey(ws);
            this = this@internal.matlab.workspace.MLWorkspaceDocument(manager, variable, userContext);
            this = this@internal.matlab.legacyvariableeditor.peer.PeerVariableNode(root,...
                internal.matlab.legacyvariableeditor.peer.PeerDocument.PeerNodeType,...
                'name',variable.getDataModel.Name,...
                'workspace', wsKey,... % Send the serializable key across
                'docID', [variable.getDataModel.Name num2str(docIDCounter)],...
                'userContext', userContext);
            this.DataModel = variable.getDataModel();
            this.ViewModel = variable.getViewModel(this);
        end

        function whosError(this, exception)
            this.Manager.sendErrorMessage(exception.getMessage());
        end

        function handlePropertySet(this, es, ed)
            % No properties at this time
        end
        
        function handlePropertyDeleted(this, es, ed)
            % No properties at this time
        end
        
        function handlePeerEvents(this, es, ed)
            % No peer events at this time
        end
        
        function storedValue = get.DocID(this)
            storedValue = this.PeerNode.getProperties.docID;
        end
    end
end

