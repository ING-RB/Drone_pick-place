classdef RemoteCategoricalAdapter < ...
        internal.matlab.variableeditor.MLCategoricalAdapter
    %RemoteCategoricalAdapter
    %   MATLAB Categorical Variable Editor Mixin
    
    % Copyright 2013-2019 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = RemoteCategoricalAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLCategoricalAdapter(...
                name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ...
                    ~isa(this.ViewModel_I, 'internal.matlab.variableeditor.peer.RemoteCategoricalViewModel')) ...
                    && ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteCategoricalViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
