classdef RemoteOptimvarAdapter < ...
        internal.matlab.variableeditor.MLOptimvarAdapter
    %RemoteObjectArrayAdapter
    %   MATLAB Remote Object Array Variable Editor Mixin

    % Copyright 2022 The MathWorks, Inc.
    
    
    % Constructor
    methods
        function this = RemoteOptimvarAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLOptimvarAdapter(...
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
                    ~isa(this.ViewModel_I, 'internal.matlab.variableeditor.peer.RemoteOptimvarViewModel')) && ...
                    ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = ...
                    internal.matlab.variableeditor.peer.RemoteOptimvarViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
