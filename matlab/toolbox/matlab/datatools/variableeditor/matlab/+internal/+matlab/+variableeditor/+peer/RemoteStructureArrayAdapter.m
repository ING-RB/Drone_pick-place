classdef RemoteStructureArrayAdapter < internal.matlab.variableeditor.MLStructureArrayAdapter
    %RemoteStructureArrayAdapter
    %   MATLAB Structure Array Variable Editor Mixin
    
    % Copyright 2015-2019 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = RemoteStructureArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLStructureArrayAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteStructureArrayViewModel')) && ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteStructureArrayViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end


