classdef PeerCategoricalAdapter < ...
        internal.matlab.legacyvariableeditor.MLCategoricalAdapter
    %PeerCategoricalAdapter
    %   MATLAB Categorical Variable Editor Mixin
    
    % Copyright 2013-2014 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = PeerCategoricalAdapter(name, workspace, data)
            this@internal.matlab.legacyvariableeditor.MLCategoricalAdapter(...
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
                    ~isa(this.ViewModel_I, 'internal.matlab.legacyvariableeditor.peer.PeerCategoricalViewModel')) ...
                    && ~isempty(document) && ~isempty(document.PeerNode)
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.legacyvariableeditor.peer.PeerCategoricalViewModel(...
                    document.PeerNode, this);
            end
            viewModel = this.ViewModel;
        end
    end
end
