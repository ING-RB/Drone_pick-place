classdef MLMxNArrayAdapter < internal.matlab.variableeditor.MLAdapter
    %MLMxNArrayAdapter
    % MATLAB MxN Array Variable Editor Mixin

    % Copyright 2015-2023 The MathWorks, Inc.
    
    % DataModel
    properties (SetObservable = true, SetAccess = protected, Dependent=true)
        % DataModel Property
        DataModel;
    end
    
    methods
        function storedValue = get.DataModel(this)
            if isempty(this.DataModel_I)
                this.DataModel = ...
                    internal.matlab.variableeditor.MLMxNArrayDataModel(...
                    this.Name, this.Workspace);
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
    
    % ViewModel
    properties (SetObservable = true, SetAccess = protected, Dependent=true)
        % ViewModel Property
        ViewModel;
    end
    
    methods
        function storedValue = get.ViewModel(this)
            if isempty(this.ViewModel_I)
                this.ViewModel_I = ...
                    internal.matlab.variableeditor.MxNArrayViewModel(...
                    this.DataModel);
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
    
    % Constructor
    methods
        function hObj = MLMxNArrayAdapter(name, workspace, data)
            hObj.Name = name;
            hObj.Workspace = workspace;
            hObj.DataModel.Data = data;
        end
    end
    
    methods(Static)
        function c = getClassType()
            c = internal.matlab.variableeditor.MLMxNArrayDataModel.ClassType;
        end
    end
end

