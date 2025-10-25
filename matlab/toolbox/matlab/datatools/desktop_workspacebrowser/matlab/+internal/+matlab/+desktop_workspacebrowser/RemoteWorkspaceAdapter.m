classdef RemoteWorkspaceAdapter < internal.matlab.desktop_workspacebrowser.MLWorkspaceAdapter
    %RemoteWorkspaceAdapter
    %   MATLAB Workspace Variable Editor Mixin

    % Copyright 2019 The MathWorks, Inc.

    methods
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            % Delayed ViewModel creation to assure that the document
            % peerNode has been created.
            if (isempty(this.ViewModel_I) || ...
                ~isa(this.ViewModel_I,'internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModel')) ...
                && ~isempty(document) 
            
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModel(document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end

    % Constructor
    methods
        function this = RemoteWorkspaceAdapter(name, workspace, DataModel, ViewModel)
             arguments
                name
                workspace
                DataModel
                ViewModel = []
            end
            this@internal.matlab.desktop_workspacebrowser.MLWorkspaceAdapter(name, workspace, DataModel, ViewModel);
        end
    end
end

