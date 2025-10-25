classdef PeerStructureAdapter < internal.matlab.legacyvariableeditor.MLStructureAdapter
    %PeerStructureAdapter
    %   MATLAB Structure Variable Editor Mixin
    
    % Copyright 2013 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = PeerStructureAdapter(name, workspace, data)
            this@internal.matlab.legacyvariableeditor.MLStructureAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.legacyvariableeditor.peer.PeerStructureViewModel')) && ~isempty(document) && ~isempty(document.PeerNode)
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.legacyvariableeditor.peer.PeerStructureViewModel(document.PeerNode, this, document.getNextViewID());
            end
            viewModel = this.ViewModel;
        end
    end
end
