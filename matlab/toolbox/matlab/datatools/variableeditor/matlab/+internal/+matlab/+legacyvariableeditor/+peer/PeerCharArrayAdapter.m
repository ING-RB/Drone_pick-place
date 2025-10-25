classdef PeerCharArrayAdapter < ...
        internal.matlab.legacyvariableeditor.MLCharArrayAdapter
    %PeerCharArrayAdapter
    %   MATLAB Char Array Variable Editor Mixin
    
    % Copyright 2014 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = PeerCharArrayAdapter(name, workspace, data)
            this@internal.matlab.legacyvariableeditor.MLCharArrayAdapter(...
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
                    ~isa(this.ViewModel_I, 'internal.matlab.legacyvariableeditor.peer.PeerCharArrayViewModel')) ...
                    && ~isempty(document) && ~isempty(document.PeerNode)
                delete(this.ViewModel_I);
                     this.ViewModel_I = internal.matlab.legacyvariableeditor.peer.PeerCharArrayViewModel(...
                         document.PeerNode, this);
            end
            viewModel = this.ViewModel;
        end
    end
end
