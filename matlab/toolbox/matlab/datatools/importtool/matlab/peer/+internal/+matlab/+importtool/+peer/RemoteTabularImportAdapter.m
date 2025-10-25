% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides Remote Adapter for tabular file import

% Copyright 2022 The MathWorks, Inc.

classdef RemoteTabularImportAdapter < internal.matlab.importtool.server.TabularImportAdapter

    methods
        function this = RemoteTabularImportAdapter(name, dataSource)
            this@internal.matlab.importtool.server.TabularImportAdapter(name, dataSource);
        end

        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ...
                    ~isa(this.ViewModel_I,'internal.matlab.importtool.peer.RemoteTabularImportViewModel')) && ...
                    ~isempty(document) && ...
                    ~isempty(document.Provider)
                delete(this.ViewModel_I);
                state = this.DataModel.getState();
                this.ViewModel_I = internal.matlab.importtool.peer.RemoteTabularImportViewModel(...
                    document, this, 'viewID', document.getNextViewID(), "type", state.ViewType);
            end
            viewModel = this.ViewModel;
        end
    end
end
