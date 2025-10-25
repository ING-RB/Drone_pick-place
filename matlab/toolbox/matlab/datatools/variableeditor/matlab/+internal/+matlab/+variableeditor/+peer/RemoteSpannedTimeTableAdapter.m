classdef RemoteSpannedTimeTableAdapter < internal.matlab.variableeditor.MLSpannedTimeTableAdapter
    %PeerTableAdapter
    %   MATLAB Table Variable Editor Mixin

    % Copyright 2023 The MathWorks, Inc.


    % Constructor
    methods
        function this = RemoteSpannedTimeTableAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLSpannedTimeTableAdapter(name, workspace, data);
        end
    end

    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteTimeTableSpannedViewModel')) && ~isempty(document)
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteTimeTableSpannedViewModel(document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
