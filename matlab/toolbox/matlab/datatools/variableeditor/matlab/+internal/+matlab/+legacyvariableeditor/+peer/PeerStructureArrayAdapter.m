classdef PeerStructureArrayAdapter < internal.matlab.legacyvariableeditor.MLStructureArrayAdapter
    %PeerStructureArrayAdapter
    %   MATLAB Structure Array Variable Editor Mixin
    
    % Copyright 2015 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = PeerStructureArrayAdapter(name, workspace, data)
            this@internal.matlab.legacyvariableeditor.MLStructureArrayAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.legacyvariableeditor.peer.PeerStructureArrayViewModel')) && ~isempty(document) && ~isempty(document.PeerNode)
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.legacyvariableeditor.peer.PeerStructureArrayViewModel(document.PeerNode, this);
            end
            viewModel = this.ViewModel;
        end
    end
end


