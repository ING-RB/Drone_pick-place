classdef RemoteWorkspaceDocument < internal.matlab.desktop_workspacebrowser.MLWorkspaceDocument
    %RemoteWorkspaceDocument PeerModel Variable Document

    % Copyright 2019-2024 The MathWorks, Inc.

    % Property Definitions:
    properties 
        DocID;
    end

    properties(WeakHandle)
        Provider internal.matlab.desktop_workspacebrowser.MF0ViewModelWSBProvider;
    end

    properties (Constant, Hidden=true)
        % EnableContainerExpansionAttribute is a data attribute used to
        % determine the choice of view model on the front end, similar to
        % those defined in VEDataAttributes
        EnableContainerExpansionAttribute = "EnableContainerExpansion";
    end
  
    events
        DoubleClickOnVariable;
        OpenSelection;
        DropEvent;
    end
        
    methods
        % Constructor
        function this = RemoteWorkspaceDocument(provider, manager, variable, enableContainerExpansion, workspaceArgs)     
            arguments
                provider
                manager
                variable
                enableContainerExpansion (1,1) logical = false;
                workspaceArgs.UserContext char = ''
                workspaceArgs.DisplayFormat = ''
            end
            args = namedargs2cell(workspaceArgs);
            this = this@internal.matlab.desktop_workspacebrowser.MLWorkspaceDocument(manager, variable, args{:});
            % WorkspaceManager only ever has a single Document, Always
            % setting the DocID which is used to uniquely map the document to be Name property of DataModel.
            this.DocID = variable.getDataModel.Name;
            this.Provider = provider;
            ws = variable.getDataModel.Workspace;
            wsKey = manager.getWorkspaceKey(ws);
            documentInfo = struct('name',variable.getDataModel.Name,...
                'workspace', wsKey,... % Send the serializable key across
                'docID', variable.getDataModel.Name,...
                'userContext', workspaceArgs.UserContext, ...
                'containerType', 'struct', ...
                'type', 'struct');
            if enableContainerExpansion
                % Package the feature flag as a dataAttribute, so it can 
                % be used by different plugins on the front end
                documentInfo.dataAttributes = jsonencode(this.EnableContainerExpansionAttribute);
            end
            this.Provider.addDocument(this.DocID, documentInfo);
            this.Provider.setUpProviderListeners(this, this.DocID);

            this.DataModel = variable.getDataModel();
            this.ViewModel = variable.getViewModel(this);

            % Remove the WorkspaceListener for the document.  The document type
            % of the workspace cannot change, so we don't need the listener for
            % it.
            lst = internal.matlab.datatoolsservices.WorkspaceListener.getWorkspaceListenersList;
            lst.removeListener(this);
        end

        function whosError(this, exception)
            this.Manager.sendErrorMessage(exception.getMessage());
        end

        function handlePropertySetFromClient(~, ~, ~)
            % No properties at this time
        end
        
        function handleEventFromClient(this, ~, eventData)
           if strcmp(eventData.data.type, 'doubleClickedOnMetaData')
                ed = internal.matlab.variableeditor.OpenVariableEventData;
                % Ensure row and column are 1 indexed
                ed.row = eventData.data.row + 1;
                ed.column = eventData.data.column + 1;
                ed.workspace = eventData.data.workspace;
                ed.variableName = eventData.data.variableName;
                this.notify('DoubleClickOnVariable', ed);
           elseif strcmp(eventData.data.type, 'drop')
               ed = internal.matlab.desktop_workspacebrowser.DragDropEventData;
               ed.DropData = eventData.data.data;
               ed.Workspace = eventData.data.workspace;
               this.notify('DropEvent', ed);
            end
        end
        
        % Calls into the provider to set a property on the client
        function setProperty(this, propertyName, propertyValue)
            if ~isempty(this.Provider)
                this.Provider.setPropertyOnClient(propertyName, propertyValue, this, this.DocID);
            end
        end

        % Returns the property value of the given property by accessing the
        % provider
        function propertyValue = getProperty(this, propertyName)
            propertyValue = this.Provider.getProperty(propertyName, this, this.DocID);
        end
        
        function delete(this)
            if ~isempty(this.Provider) && isvalid(this.Provider)
                this.Provider.deleteDocument(this.DocID);
            end
        end
    end
end
