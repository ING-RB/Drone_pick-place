classdef RemoteMxNArrayAdapter < ...
        internal.matlab.variableeditor.MLMxNArrayAdapter
    %RemoteMxNArrayAdapter
    %   MATLAB Remote MxN Array Variable Editor Mixin

    % Copyright 2015-2023 The MathWorks, Inc.
    
    
    % Constructor
    methods
        function this = RemoteMxNArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLMxNArrayAdapter(...
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
                    ~isa(this.ViewModel_I, 'internal.matlab.variableeditor.peer.RemoteMxNArrayViewModel')) && ...
                    ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = ...
                    internal.matlab.variableeditor.peer.RemoteMxNArrayViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
