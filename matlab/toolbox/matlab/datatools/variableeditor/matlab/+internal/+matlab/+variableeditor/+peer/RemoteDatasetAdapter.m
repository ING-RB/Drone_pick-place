classdef RemoteDatasetAdapter < internal.matlab.variableeditor.MLDatasetAdapter
    %PeerDatasetAdapter
    %   MATLAB Table Variable Editor Mixin

    % Copyright 2022 The MathWorks, Inc.


    % Constructor
    methods
        function this = RemoteDatasetAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLDatasetAdapter(name, workspace, data);
        end
    end

    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteDatasetViewModel')) && ~isempty(document)
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteDatasetViewModel(document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
