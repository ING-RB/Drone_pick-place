classdef RemoteDatetimeArrayAdapter < ...
        internal.matlab.variableeditor.MLDatetimeArrayAdapter
    %RemoteDatetimeArrayAdapter
    %   MATLAB Datetime Array Variable Editor Mixin
    
    % Copyright 2015-2019 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = RemoteDatetimeArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLDatetimeArrayAdapter( ...
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
                    ~isa(this.ViewModel_I, 'internal.matlab.variableeditor.peer.RemoteDatetimeArrayViewModel')) ...
                    && ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteDatetimeArrayViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
