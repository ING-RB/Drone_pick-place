classdef RemoteCharArrayAdapter < ...
        internal.matlab.variableeditor.MLCharArrayAdapter
    %RemoteCharArrayAdapter
    %   MATLAB Char Array Variable Editor Mixin
    
    % Copyright 2014-2019 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = RemoteCharArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLCharArrayAdapter(...
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
                    ~isa(this.ViewModel_I, 'internal.matlab.variableeditor.peer.RemoteCharArrayViewModel')) ...
                    && ~isempty(document) 
                delete(this.ViewModel_I);
                     this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteCharArrayViewModel(...
                         document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
