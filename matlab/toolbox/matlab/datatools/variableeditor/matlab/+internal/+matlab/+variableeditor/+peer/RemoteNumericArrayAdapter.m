classdef RemoteNumericArrayAdapter < internal.matlab.variableeditor.MLNumericArrayAdapter
    %RemoteNumericArrayAdapter
    %   MATLAB Numeric Array Variable Editor Mixin

    % Copyright 2013-2019 The MathWorks, Inc.


    % Constructor
    methods
        function this = RemoteNumericArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLNumericArrayAdapter(name, workspace, data);
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
                ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteNumericArrayViewModel')) ...
                && ~isempty(document) 
                delete(this.ViewModel_I);
                % usecontext is needed for live editor use case
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteNumericArrayViewModel(document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
