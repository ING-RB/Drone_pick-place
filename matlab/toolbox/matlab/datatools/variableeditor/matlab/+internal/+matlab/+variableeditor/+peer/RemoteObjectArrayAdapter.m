classdef RemoteObjectArrayAdapter < ...
        internal.matlab.variableeditor.MLObjectArrayAdapter
    %RemoteObjectArrayAdapter
    %   MATLAB Remote Object Array Variable Editor Mixin

    % Copyright 2015-2019 The MathWorks, Inc.
    
    
    % Constructor
    methods
        function this = RemoteObjectArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLObjectArrayAdapter(...
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
                    ~isa(this.ViewModel_I, 'internal.matlab.variableeditor.peer.RemoteObjectArrayViewModel')) && ...
                    ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = ...
                    internal.matlab.variableeditor.peer.RemoteObjectArrayViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
