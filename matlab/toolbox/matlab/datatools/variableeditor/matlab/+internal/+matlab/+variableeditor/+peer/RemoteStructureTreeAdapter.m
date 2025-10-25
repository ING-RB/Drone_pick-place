classdef RemoteStructureTreeAdapter < internal.matlab.variableeditor.MLStructureTreeAdapter
    %RemoteStructureAdapter
    % Adapter class that returns RemoteStructureTreeViewModel as the
    % ViewModel and MLStructureTreeAdapter as the DataModel.

    % Copyright 2022 The MathWorks, Inc.

    % Constructor
    methods
        function this = RemoteStructureTreeAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLStructureTreeAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteStructureTreeViewModel')) && ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteStructureTreeViewModel(document, this, ...
                    document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
