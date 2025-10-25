classdef RemoteObjectAdapter < internal.matlab.variableeditor.MLObjectAdapter
    %RemoteObjectAdapter
    %   MATLAB Object Variable Editor Mixin
    
    % Copyright 2013-2019 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = RemoteObjectAdapter(name, workspace, data)
            % Creates a new RemoteObjectAdapter
            this@internal.matlab.variableeditor.MLObjectAdapter(name, workspace, data);
        end
    end
    
    methods (Access = public)
        % getDataModel
        function dataModel = getDataModel(this, ~)
            % Returns the DataModel
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            % Returns the ViewModel
            if (isempty(this.ViewModel_I) || ...
                    ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteObjectViewModel')) && ...
                    ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteObjectViewModel(...
                    document, this, document.getNextViewID, document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
