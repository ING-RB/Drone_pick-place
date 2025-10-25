classdef RemoteSimulinkDatasetAdapter < internal.matlab.variableeditor.MLSimulinkDatasetAdapter
    %RemoteSimulinkDatasetAdapter
    %   MATLAB Simulink Dataset Variable Editor Mixin
    
    % Copyright 2021 The MathWorks, Inc.

    % Constructor
    methods
        function this = RemoteSimulinkDatasetAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLSimulinkDatasetAdapter(name, workspace, data);
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
                    ~isa(this.ViewModel_I,'internal.matlab.variableeditor.peer.RemoteSimulinkDatasetViewModel')) && ...
                    ~isempty(document) 
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteSimulinkDatasetViewModel(...
                    document, this, document.getNextViewID, document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end