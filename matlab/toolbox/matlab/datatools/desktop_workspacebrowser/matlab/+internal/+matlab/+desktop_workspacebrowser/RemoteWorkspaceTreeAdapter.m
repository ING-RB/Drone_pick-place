classdef RemoteWorkspaceTreeAdapter < internal.matlab.desktop_workspacebrowser.RemoteWorkspaceAdapter
    % RemoteWorkspaceTreeAdapter

    % Copyright 2023 The MathWorks, Inc.
    
    methods
        % getViewModel
        function viewModel = getViewModel(this, document)
            % Delayed ViewModel creation to assure that the document
            % peerNode has been created.
            if (isempty(this.ViewModel_I) || ...
                ~isa(this.ViewModel_I,'internal.matlab.desktop_workspacebrowser.RemoteWorkspaceTreeViewModel')) ...
                && ~isempty(document) 
            
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceTreeViewModel(document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end

    % Constructor
    methods
        function this = RemoteWorkspaceTreeAdapter(name, workspace, DataModel, ViewModel)
             arguments
                name
                workspace
                DataModel
                ViewModel = []
            end
            this = this@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceAdapter(name, workspace, DataModel, ViewModel)
        end
    end
end

