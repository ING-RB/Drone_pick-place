% This class is unsupported and might change or be removed without notice in
% a future version.

% This class is the Tabular Import Adapter class

% Copyright 2022 The MathWorks, Inc.

classdef TabularImportAdapter < internal.matlab.variableeditor.MLAdapter

    properties(SetObservable = true, SetAccess = protected, Dependent = true)
        DataModel;
        ViewModel;
    end

    properties(SetAccess = protected)
        DataSource;
    end

    methods
        function dm = get.DataModel(this)
            if isempty(this.DataModel_I)
                this.DataModel = internal.matlab.importtool.server.TabularImportDataModel(this.DataSource.Importer);
            end
            dm = this.DataModel_I;
        end

        function set.DataModel(this, dm)
            reallyDoCopy = ~isequal(this.DataModel_I, dm);
            if reallyDoCopy
                this.DataModel_I = dm;
            end
        end

        function vm = get.ViewModel(this)
            if isempty(this.ViewModel_I)
                this.ViewModel_I = internal.matlab.importtool.server.TabularImportViewModel(this.DataModel);
            end
            vm = this.ViewModel_I;
        end

        function set.ViewModel(this, vm)
            reallyDoCopy = ~isequal(this.ViewModel_I, vm);
            if reallyDoCopy
                this.ViewModel_I = vm;
            end
        end

        function this = TabularImportAdapter(name, dataSource)
            this.Name = name;
            this.DataSource = dataSource;
        end
    end
end
