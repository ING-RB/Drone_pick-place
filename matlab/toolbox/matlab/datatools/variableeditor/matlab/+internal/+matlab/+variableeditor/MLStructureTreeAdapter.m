classdef MLStructureTreeAdapter < internal.matlab.variableeditor.MLAdapter
    %MLStructureTreeAdapter
    %   MATLAB Structure Variable Editor Mixin
    
    % Copyright 2022 The MathWorks, Inc.
    
    % DataModel
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=true, Hidden=false)
        % DataModel Property
        DataModel;
    end
    
    methods
        function storedValue = get.DataModel(this)
            % Return the DataModel for scalar structures.  Creates it the
            % first time if it hasn't been created yet.
            if isempty(this.DataModel_I)
                this.DataModel = internal.matlab.variableeditor.MLStructureTreeDataModel(...
                    this.Name, this.Workspace);
            end
            storedValue = this.DataModel_I;
        end
        
        function set.DataModel(this, newValue)
            % Sets the DataModel for structures.
            reallyDoCopy = ~isequal(this.DataModel_I, newValue);
            if reallyDoCopy
                this.DataModel_I = newValue;
            end
        end
    end
    
    % ViewModel
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=true, Hidden=false)
        % ViewModel Property
        ViewModel;
    end
    
    methods
        function storedValue = get.ViewModel(this)
            % Return the ViewModel for scalar structures.  Creates it the
            % first time if it hasn't been created yet.
            if isempty(this.ViewModel_I)
                this.ViewModel_I = internal.matlab.variableeditor.StructureTreeViewModel(...
                    this.DataModel);
            end
            storedValue = this.ViewModel_I;
        end
        
        function set.ViewModel(this, newValue)
            % Sets the ViewModel for structures
            reallyDoCopy = ~isequal(this.ViewModel_I, newValue);
            if reallyDoCopy
                this.ViewModel_I = newValue;
            end
        end
    end
    
    % Constructor
    methods
        function hObj = MLStructureTreeAdapter(name, workspace, data)
            hObj.Name = name;
            hObj.Workspace = workspace;
            hObj.DataModel.Data = data;
            % Initializing size upon creation will ensure document
            % properties are initialized correctly
            hObj.DataModel.updateCachedSize();
        end
    end
    
    methods(Static)
        function c = getClassType()
            c = internal.matlab.variableeditor.MLStructureTreeDataModel.ClassType;
        end
    end
end

