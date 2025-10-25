classdef MLObjectArrayAdapter < internal.matlab.legacyvariableeditor.MLAdapter
    %MLOBJECTARRAYADAPTER
    % MATLAB Object Array Variable Editor Mixin

    % Copyright 2015 The MathWorks, Inc.
    
    % DataModel
    properties (SetObservable = true, SetAccess = protected, Dependent=true)
        % DataModel Property
        DataModel;
    end
    
    methods
        function storedValue = get.DataModel(this)
            if isempty(this.DataModel_I)
                this.DataModel = ...
                    internal.matlab.legacyvariableeditor.MLObjectArrayDataModel(...
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
                    internal.matlab.legacyvariableeditor.ObjectArrayViewModel(...
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
        function hObj = MLObjectArrayAdapter(name, workspace, data)
            hObj.Name = name;
            hObj.Workspace = workspace;
            hObj.DataModel.Data = data;
        end
    end
    
    methods(Static)
        function c = getClassType()
            c = internal.matlab.legacyvariableeditor.MLObjectArrayDataModel.ClassType;
        end
    end
end

