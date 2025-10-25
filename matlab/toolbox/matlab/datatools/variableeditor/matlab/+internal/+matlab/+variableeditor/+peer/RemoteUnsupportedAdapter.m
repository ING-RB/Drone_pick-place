classdef RemoteUnsupportedAdapter < internal.matlab.variableeditor.MLUnsupportedAdapter
    %RemoteUnsupportedAdapter
    %   MATLAB Object Variable Editor Mixin
    
    % Copyright 2013-2019 The MathWorks, Inc.

    % Constructor
    methods
        function this = RemoteUnsupportedAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLUnsupportedAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteUnsupportedViewModel')) && ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel = internal.matlab.variableeditor.peer.RemoteUnsupportedViewModel(document, this, ...
                     document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
