classdef (CaseInsensitiveProperties=true, TruncatedProperties=true, ConstructOnLoad=true) Document < handle & internal.matlab.legacyvariableeditor.VariableObserver & JavaVisible
    % Document
    % An abstract class defining the methods for a Variable Document
    % 
    
    % Copyright 2013 The MathWorks, Inc.

    % Events
    events
        DocumentTypeChanged % Fired when the variable type has changed
    end
    
    % Property Definitions:

    % ViewModel
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        % ViewModel Property
        ViewModels;
        ViewCount = 0;
    end 

    properties (Dependent=true)
        ViewModel;
    end%properties
    
    methods
        function storedValue = get.ViewModels(this)
            storedValue = this.ViewModels;
        end
        
        function set.ViewModels(this, newValue)
            if ~isempty(this.ViewModels)
                reallyDoCopy = ~isequal(this.ViewModels{1}, newValue);
            else
                reallyDoCopy = true;
            end
            
            if reallyDoCopy
                this.ViewModels{1} = newValue;
            end
        end

        function value = get.ViewModel(this)
            value = [];
            if ~isempty(this.ViewModels)
                value = this.ViewModels{1};
            end            
        end

        function set.ViewModel(this, newValue)
            reallyDoCopy = true;
            
            % if viewmodel already exists then check the value of the first
            % view model. If it is not the same as the new value, set
            % reallyDoCopy to true else false
            if ~isempty(this.ViewModels) && isvalid(this.ViewModels{1})
                reallyDoCopy = ~isequal(this.ViewModels{1}, newValue);
            else
                this.ViewModels = {};
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
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        % Manager Property
        Manager;
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
    end    
    
    methods(Access='public')
        function this = Document(manager, dataModel, viewModel, userContext)
            % Document will have one DataModel and multipe ViewModels
            this.DataModel = dataModel;
            this.ViewModels = viewModel;
            
            this.Manager = manager;
            this.UserContext = userContext;
        end
    end
    
    % Public methods
    methods (Access='public')
        % Delete
        function delete(this)
            if ~isempty(this.ViewModels)
                for i=1:length(this.ViewModels)
                    if ~isempty(this.ViewModels{i}) && isvalid(this.ViewModels{i})
                        delete(this.ViewModels{i});
                    end
                end
            end
            if ~isempty(this.DataModel) 
                delete(this.DataModel);
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
            viewID = ['__' num2str(this.ViewCount)]; 
        end
        
        function view = getView(this, id)
            view = [];
            
            % if no id is passed in then the first view is returned
            if nargin == 0
                view = this.ViewModels{1};
            end

            for j=1:length(this.ViewModels)
                if (strcmp(this.ViewModels{j}.viewID, id))
                    view = this.ViewModels{j};
                    return;
                end
            end
        end         
    end
end %classdef
