classdef PeerLogicalArrayAdapter < ...
        internal.matlab.legacyvariableeditor.MLLogicalArrayAdapter
    % PEERLOGICALARRAYADAPTER
    % MATLAB Peer Logical Array Variable Editor Mixin

    % Copyright 2015 The MathWorks, Inc.
    
    methods
        % Constructor
        function this = PeerLogicalArrayAdapter(name, workspace, data)
            this@internal.matlab.legacyvariableeditor.MLLogicalArrayAdapter(...
                name, workspace, data);
        end
    end
    
    methods
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end
        
        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ...
                    ~isa(this.ViewModel_I, ...
                    'internal.matlab.legacyvariableeditor.peer.PeerLogicalArrayViewModel')) && ...
                    ~isempty(document) && ~isempty(document.PeerNode)
                % Create a new PeerLogicalArrayViewModel
                delete(this.ViewModel_I);
                this.ViewModel_I = ...
                    internal.matlab.legacyvariableeditor.peer.PeerLogicalArrayViewModel(...
                    document.PeerNode, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
