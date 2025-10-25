classdef PeerCellArrayAdapter < internal.matlab.legacyvariableeditor.MLCellArrayAdapter
    %PeerCellArrayAdapter
    %   MATLAB Cell Array Variable Editor Mixin
    
    % Copyright 2014-2015 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = PeerCellArrayAdapter(name, workspace, data)
            this@internal.matlab.legacyvariableeditor.MLCellArrayAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.legacyvariableeditor.peer.PeerCellArrayViewModel')) && ~isempty(document) && ~isempty(document.PeerNode)
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.legacyvariableeditor.peer.PeerCellArrayViewModel(document.PeerNode, this);
            end
            viewModel = this.ViewModel;
        end
    end
end
