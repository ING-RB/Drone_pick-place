classdef ContextMenuManager < handle
    % CONTEXTMENUMANAGER handle class from the ContextMenuFramework    
    % This class takes care of creating a menuprovider for each unique
    % namepsace provided.     
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties (SetObservable=true, SetAccess='protected')       
       ContextMenuProviderMap = containers.Map;
    end 
 
    methods 
        % For each xmlfile and namespace provided, this method creates a
        % menu provider and hashes it to a provider map
        function menuProvider = createMenuProvider(this, xmlFile, nameSpace, rootProperties)
            menuProvider = [];
            if isKey(this.ContextMenuProviderMap, nameSpace)
                menuProvider = this.ContextMenuProviderMap(nameSpace);    
            end
            
            if isempty(menuProvider) || ~isvalid(menuProvider)
                menuProvider = internal.matlab.datatoolsservices.contextmenuservice.MsgServiceContextMenuProvider(xmlFile, rootProperties);
                this.ContextMenuProviderMap(nameSpace) = menuProvider;
            end
        end
        
        function menuProvider = getContextMenuProvider(this, namespace)
            menuProvider = [];
            if isKey(this.ContextMenuProviderMap, namespace)
                menuProvider = this.ContextMenuProviderMap(namespace);
            end
        end
        
        function deleteContextMenuProvider(this, namespace)            
            if isKey(this.ContextMenuProviderMap, namespace)                
                delete(this.ContextMenuProviderMap(namespace));
                remove(this.ContextMenuProviderMap, namespace);
            end
        end
        
        function delete(this)
            menuMapKeys = keys(this.ContextMenuProviderMap);
            for i=1:length(menuMapKeys)
                delete(this.ContextMenuProviderMap(menuMapKeys{i}));
            end
            this.ContextMenuProviderMap = containers.Map;
        end
    end
    
    methods(Access='protected')
        function obj = ContextMenuManager()
            obj.ContextMenuProviderMap = containers.Map;
        end
    end
    
    methods(Static)
        function obj = getInstance()
            mlock; % Keep persistent variables until MATLAB exits
            persistent menuManagerInstance;            
            if isempty(menuManagerInstance) || ~isvalid(menuManagerInstance)
                menuManagerInstance = internal.matlab.datatoolsservices.contextmenuservice.ContextMenuManager();                
            end
            obj = menuManagerInstance;
        end      
    end
end

