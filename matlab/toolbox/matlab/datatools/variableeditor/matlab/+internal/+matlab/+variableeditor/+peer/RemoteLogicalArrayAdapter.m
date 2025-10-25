classdef RemoteLogicalArrayAdapter < ...
        internal.matlab.variableeditor.MLLogicalArrayAdapter
    % RemoteLogicalArrayAdapter
    % MATLAB Remote Logical Array Variable Editor Mixin

    % Copyright 2015-2019 The MathWorks, Inc.
    
    methods
        % Constructor
        function this = RemoteLogicalArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLLogicalArrayAdapter(...
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
                    'internal.matlab.variableeditor.peer.RemoteLogicalArrayViewModel')) && ...
                    ~isempty(document) 
                % Create a new RemoteLogicalArrayAdapter
                delete(this.ViewModel_I);
                this.ViewModel_I = ...
                    internal.matlab.variableeditor.peer.RemoteLogicalArrayViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
