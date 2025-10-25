classdef PeerInspectorDocument < ...
        internal.matlab.variableeditor.peer.RemoteDocument
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % The Peer level Inspector Document.  Differs from the PeerDocument
    % used in the Variable Editor only in that is overrides the
    % variableChanged function -- because the inspector always uses the
    % same adapter class, and doesn't need to swap out when changes happen.
    % (In specific, inspecting value object arrays would cause a size
    % change that would trigger documents to be swapped out, which was
    % undesireable)
    
    % Copyright 2015-2022 The MathWorks, Inc.
    
    
    methods
        % Constructor
        function this = PeerInspectorDocument(provider, manager, variable, ...
                 docID, documentArgs)
            arguments
                provider
                manager
                variable
                docID char 
                documentArgs.UserContext char = '';
                documentArgs.DisplayFormat = '';
            end
            args = namedargs2cell(documentArgs);
            % Call the MLDocument constructor
            this = this@internal.matlab.variableeditor.peer.RemoteDocument(... 
                provider, manager, variable, docID, args{:});            
            
            % The inspector doesn't need the WorkspaceListener at the document
            % level.  The inspector always uses the same adapter class, and
            % doesn't need to swap out when changes happen.
            % internal.matlab.datatoolsservices.WorkspaceListener's removeListener is fired.
            this.removeListeners();
        end      
        
        function documentInfo = getDocumentInfo(~, manager, variable, userContext, docID)
            documentInfo = struct(...
                'name', variable.getDataModel.Name,...
                'workspace', manager.getWorkspaceKey(variable.getDataModel.Workspace),...
                'docID', docID,...
                'userContext', userContext);
        end
        
        function data = variableChanged(this, varargin)
            % Overrides the variableChanged behavior from the super class,
            % which looks for type and/or dimension changes to swap out the
            % adapter.  This isn't needed because the inspector always uses
            % the same adapter class.
            data = this.DataModel.getData();
        end
    end
end

