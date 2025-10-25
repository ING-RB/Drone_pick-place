classdef Document < handle & internal.matlab.variableeditor.VariableObserver 
    % Document
    % An abstract class defining the methods for a Variable Document
    % 
    
    % Copyright 2013-2025 The MathWorks, Inc.

    % Events
    events
        DocumentTypeChanged % Fired when the variable type has changed
    end
    
    % Property Definitions:

    % ViewModel
    properties (SetAccess='protected')
        % ViewModel Property
        ViewModels = internal.matlab.variableeditor.MLUnsupportedViewModel.empty;
    end

    properties (SetAccess='protected')
        ViewCount = 0;
    end 

    properties (Dependent=true)
        ViewModel;
    end%properties
    
    methods
        function value = get.ViewModel(this)
            value = [];
            if ~isempty(this.ViewModels)
                value = this.ViewModels(1);
            end            
        end

        function set.ViewModel(this, newValue)
            reallyDoCopy = true;
            
            % if viewmodel already exists then check the value of the first
            % view model. If it is not the same as the new value, set
            % reallyDoCopy to true else false
            if ~isempty(this.ViewModels) && ...
                    (isa(this.ViewModels, 'handle') && isvalid(this.ViewModels(1)))
                reallyDoCopy = ~isequal(this.ViewModels(1), newValue);
            else
                this.ViewModels = internal.matlab.variableeditor.MLUnsupportedViewModel.empty;
            end
            
            % if ViewModels is empty or if reallyDoCopy then update the
            % first ViewModel value to newValue
            if reallyDoCopy
                this.ViewModels = newValue;
            end
        end        
    end
    
    % DataModel
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        % DataModel Property
        DataModel;
    end %properties
    methods
        function storedValue = get.DataModel(this)
            storedValue = this.DataModel;
        end
        
        function set.DataModel(this, newValue)
            reallyDoCopy = ~isequal(this.DataModel, newValue);
            if reallyDoCopy
                this.DataModel = newValue;
            end
        end
    end
    
    % Manager
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false, WeakHandle)
        % Manager Property
        Manager internal.matlab.variableeditor.MLManager;
    end %properties
    methods
        function storedValue = get.Manager(this)
            storedValue = this.Manager;
        end
        
        function set.Manager(this, newValue)
            reallyDoCopy = ~isequal(this.Manager, newValue);
            if reallyDoCopy
                this.Manager = newValue;
            end
        end
    end
    
    % UserContext
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        % UserContext Property
        UserContext;
    end %properties
    methods
        function storedValue = get.UserContext(this)
            storedValue = this.UserContext;
        end
        
        function set.UserContext(this, newValue)
            reallyDoCopy = ~isequal(this.UserContext, newValue);
            if reallyDoCopy
                this.UserContext = newValue;
            end
        end
    end

    % IgnoreScopeChange
    properties (SetObservable=false, SetAccess='public', GetAccess='public', Dependent=false, Hidden=true)
        % IgnoreScopeChange Property
        IgnoreScopeChange = false;
        DisplayFormat char = '';
    end    
    
    methods(Access='public')
        function this = Document(manager, dataModel, viewModel, documentArgs)
            arguments
                manager
                dataModel
                viewModel
                documentArgs.UserContext char = ''
                documentArgs.DisplayFormat char = ''
            end
            % Document will have one DataModel and multipe ViewModels
            this.DataModel = dataModel;
            this.ViewModels = viewModel;
            
            this.Manager = manager;
            this.UserContext = documentArgs.UserContext;
            this.DisplayFormat = documentArgs.DisplayFormat;
        end
        
        % NOOP on setProperty, Remote classes will set property remotely
        function setProperty(~, ~, ~)           
        end
    end
    
    % Public methods
    methods (Access='public')
        % Delete
        function delete(this)
            if ~isempty(this.ViewModels)
                for i=1:length(this.ViewModels)
                    if ~isempty(this.ViewModels(i)) && isvalid(this.ViewModels(i))
                        delete(this.ViewModels(i));
                    end
                end
            end
            if ~isempty(this.DataModel) 
                delete(this.DataModel);
                this.DataModel = [];
            end
        end 
        
        % set DataModel 
        function setDataModel(this, value)
            this.DataModel = value;
        end
        
        % set ViewModel
        function setViewModel(this, value)
            this.ViewModels = value;
        end
        
        function addViewModel(this, value, viewType)
            this.ViewModels{end + 1} = value; 
        end
        
        function removeViewModel(this, value)
            index = this.getView(value.viewID);
            if ~isempty(index)
                delete(this.ViewModels{index});
                this.ViewModels{index} = [];
            end
        end
        
        function viewID = getNextViewID(this)
            this.ViewCount = this.ViewCount + 1;
            viewID = "__" + this.ViewCount; 
        end
        
        function view = getView(this, id)
            view = [];
            
            % if no id is passed in then the first view is returned
            if nargin == 0
                view = this.ViewModels(1);
            end

            for j=1:length(this.ViewModels)
                if (strcmp(this.ViewModels{j}.viewID, id))
                    view = this.ViewModels{j};
                    return;
                end
            end
        end
        
        % Returns true of the adapter is of type Object/ObjectArray     
        function isObjType = isObjectTypeAdapter(~, adapterClass)
            isObjType = any(strcmp(adapterClass, {'internal.matlab.variableeditor.MLObjectAdapter', ...
                        'internal.matlab.variableeditor.MLObjectArrayAdapter'}));
        end
        
        % Returns the workspace where this document is created to run eval
        % commands
        function ws = getWorkspaceForEval(this)
            ws = this.DataModel.Workspace;
            if ischar(ws) && strcmp(ws, 'caller')
                ws = 'debug';
            end
        end
    end
    
    methods(Static = true)
        
        % Fetches immediate parentName if one exists
        function parentName = getParentName(varName)
            parentName = [];
            baseVarName = matlab.internal.datatoolsservices.getImmediateParentName(varName);
            if ~strcmp(baseVarName, varName)
                parentName = baseVarName;
            end
        end
        
        function containerType = getContainerType(data)
            containerType = class(data);
            try
                if (isa(data, 'internal.matlab.variableeditor.NullValueObject') || ...
                        issparse(data) || (~ismatrix(data) && ~isnumeric(data)))
                    containerType = '';
                end
            catch
                % Ignore any errors, just return the class(data)
            end
        end
        
        % utility fn to detect if we have an 'object' like conatiner based on the viewmodel and data.
        function isContainerType = isObjectTypeContainer(vm, vardata)
            isContainerType = false;
            c = class(vm);

            % Short circuit for know types that are objects but not handles
            % as object types
            if istabular(vardata) || isstring(vardata) || istall(vardata)
                return;
            end

            if isa(vm, "internal.matlab.variableeditor.ObjectViewModel") || ...
               isa(vm, "internal.matlab.variableeditor.ObjectArrayViewModel") || ...
               isa(vm, "internal.matlab.variableeditor.MxNArrayViewModel")
                isContainerType = true;
            elseif c == "internal.matlab.variableeditor.MLUnsupportedViewModel" && isobject(vardata) && ~istabular(vardata) && ~(isa(vardata, 'tall') || ...
                    internal.matlab.variableeditor.MLManager.isSupportedOptimvarType(vardata)) && ~isa(vardata, 'matlab.system.SystemImpl')
            % For optimvar types, the Manager detects the correct
            % adapter-container, no need to special case.
                isContainerType = true;
            % g2374723: Ensure data is not a primitive numeric when
            % checking for objects using ishandle to catch false positives
            % due to open figures.
            elseif isa(vm, "internal.matlab.variableeditor.NumericArrayViewModel") && ...
                    ((isobject(vardata) && isnumeric(vardata)) && ~internal.matlab.datatoolsservices.VariableUtils.isPrimitiveNumeric(vardata))
                isContainerType = true;
            end

            internal.matlab.datatoolsservices.logDebug("variableeditor::Document::isObjectTypeContainer", "VM class: " + c + "  isObjectTypeContainer: " + isContainerType);
        end
    end
end %classdef
