classdef MLSimulinkDatasetAdapter < internal.matlab.variableeditor.MLAdapter
    % MLSIMULINKDATASETADAPTER
    % Initializes MLSimulinkDatasetDataModel, loads Dataset into memory for
    % faster access and sets DataModel cache.
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=true, Hidden=false)
        % DataModel for Dataset Object
        DataModel;
    end

    methods
        function storedValue = get.DataModel(this)
            if isempty(this.DataModel_I)
                this.DataModel = internal.matlab.variableeditor.MLSimulinkDatasetDataModel(this.Name, this.Workspace);
            end
            storedValue = this.DataModel_I;
        end
        
        function set.DataModel(this, newValue)
            reallyDoCopy = ~isequal(this.DataModel_I, newValue);
            if reallyDoCopy
                this.DataModel_I = newValue;
            end
        end
    end
    
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=true, Hidden=false)
        % ViewModel for Dataset Object
        ViewModel;
    end
    methods
        function storedValue = get.ViewModel(this)
            if isempty(this.ViewModel_I)
                this.ViewModel_I = internal.matlab.variableeditor.SimulinkDatasetViewModel(this.DataModel);
            end
            storedValue = this.ViewModel_I;
        end
        
        function set.ViewModel(this, newValue)
            reallyDoCopy = ~isequal(this.ViewModel_I, newValue);
            if reallyDoCopy
                this.ViewModel_I = newValue;
            end
        end
    end
    
    properties (GetAccess = protected)
        % Stores whether this is a handle or value object
        HandleObject;
    end
    
    % Constructor
    methods
        function hObj = MLSimulinkDatasetAdapter(name, workspace, data)
            hObj.Name = name;
            hObj.Workspace = workspace;
            if isa(data, 'handle')
                hObj.HandleObject = true;
            else
                hObj.HandleObject = false;
            end
            hObj.DataModel.Data = data;

            % One Time operation to load the Dataset object into
            % memory, retrieve field information and store it in the cache.
            loadIntoMemory(hObj.DataModel.Data);
            hObj.DataModel.setCache(hObj.DataModel.Data);
        end
    end
end