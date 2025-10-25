classdef PeerUnsupportedAdapter < internal.matlab.legacyvariableeditor.MLUnsupportedAdapter
    %PeerObjectAdapter
    %   MATLAB Object Variable Editor Mixin
    
    % Copyright 2013 The MathWorks, Inc.

    % Constructor
    methods
        function this = PeerUnsupportedAdapter(name, workspace, data)
            this@internal.matlab.legacyvariableeditor.MLUnsupportedAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.legacyvariableeditor.peer.PeerUnsupportedViewModel')) && ~isempty(document) && ~isempty(document.PeerNode)
                delete(this.ViewModel_I);
                this.ViewModel = internal.matlab.legacyvariableeditor.peer.PeerUnsupportedViewModel(document.PeerNode, this);
            end
            viewModel = this.ViewModel;
        end
    end
end
