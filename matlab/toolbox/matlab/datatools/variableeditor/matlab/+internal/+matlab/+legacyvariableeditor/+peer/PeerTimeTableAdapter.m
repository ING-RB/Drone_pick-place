classdef PeerTimeTableAdapter < internal.matlab.legacyvariableeditor.MLTimeTableAdapter
    %PeerTimeTableAdapter
    %   MATLAB Table Variable Editor Mixin
    
    % Copyright 2013-2018 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = PeerTimeTableAdapter(name, workspace, data)
            this@internal.matlab.legacyvariableeditor.MLTimeTableAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.legacyvariableeditor.peer.PeerTimeTableViewModel')) && ~isempty(document) && ~isempty(document.PeerNode)
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.legacyvariableeditor.peer.PeerTimeTableViewModel(document.PeerNode, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
