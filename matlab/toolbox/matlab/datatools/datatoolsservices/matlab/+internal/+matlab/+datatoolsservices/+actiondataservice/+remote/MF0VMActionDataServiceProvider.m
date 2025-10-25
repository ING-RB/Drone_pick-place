classdef MF0VMActionDataServiceProvider
    % MF0VIEWMODELACTIONPROVIDER MF0VMActionDataServiceProvider is an mf0 viewmodel provider for the ActionDataService.
    % Creates the MF0 viewmodel manager and enables synchronization.
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties(Constant)
        NAMESPACE = "/Actions/DefaultNameSpace";
        ROOT_TYPE = "Root";
    end
    
    properties (SetAccess='protected')
        ViewModelManager;
    end
    
    methods
        function this = MF0VMActionDataServiceProvider(namespace)
            arguments
                namespace = internal.matlab.datatoolsservices.actiondataservice.remote.MF0VMActionDataServiceProvider.NAMESPACE;
            end
            factory = viewmodel.internal.ViewModelManagerFactory;
            this.ViewModelManager = factory.getViewModelManager(namespace);
            % Set stop at breakpoints behavior
            this.ViewModelManager.setCallbackDebugFlag(~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);

            Root = [namespace '_Root'];
            this.createRoot(Root);
        end
        
         function manager = get.ViewModelManager(this)
            manager = this.ViewModelManager;
         end       
         
         function remoteAction = addAction(this, action)
             remoteAction = internal.matlab.datatoolsservices.actiondataservice.remote.MF0VMActionWrapper(action, this.getRoot());
         end     
        
         function delete(this)
            root = this.getRoot();
            if ~isempty(root) && isvalid(root)
                root.delete;
            end  
            if ~isempty(this.ViewModelManager) && isvalid(this.ViewModelManager)
                this.ViewModelManager.delete;
            end
         end           
        
        % Gets the root of the tree. Creates a new root on the 
        % ViewModelManager if one does not exist. 
        function root =  getRoot(this)          
            this.createRoot(this.ROOT_TYPE);
            root = this.ViewModelManager.getRoot();
        end    
    end
      % Protected methods
    methods(Access='protected')        
        function createRoot(this, RootType)
            if isempty(this.ViewModelManager.getRoot())
                this.ViewModelManager.setRoot(RootType);
            end
        end               
    end       
end

