classdef RemoteCellArrayAdapter < internal.matlab.variableeditor.MLCellArrayAdapter
    %RemoteCellArrayAdapter
    %   MATLAB Cell Array Variable Editor Mixin
    
    % Copyright 2014-2019 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = RemoteCellArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLCellArrayAdapter(name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteCellArrayViewModel')) && ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteCellArrayViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);

            end
            viewModel = this.ViewModel;
        end
    end
end
