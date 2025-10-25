classdef FrameworkModuleManager < handle
    %FRAMEWORKMODULEMANAGER Loads Hardware ManagerModules based on the
    %context. Instantiates the modules as they are loaded and stores
    %handles to each module
    
    %   Copyright 2016-2021 The MathWorks, Inc.
    
    properties(GetAccess='public', SetAccess='private')        
        %ModuleMap - Map of all modules
        ModuleMap containers.Map

        % Context in which Hardware Manager is running
        Context
    end
    
    methods
        function obj = FrameworkModuleManager(mediator, context)
            obj.ModuleMap = containers.Map();
            obj.Context = context;
            
            moduleList = matlab.hwmgr.internal.FrameworkModuleManager.getModuleListByContext(context);
            obj.instantiateAndStoreModules(moduleList, mediator, context);
        end
        
        function allModulesMap = getAllModulesMap(obj)
            % Return all modules initialized by the module manager    
            allModulesMap = obj.ModuleMap;
        end
        
        function delete(obj)
            obj.applyFunctionToModules(@(module)module.handle.delete);
        end
    end
        
    methods(Access='private')
        
        function instantiateAndStoreModules(obj, moduleList, mediator, context)
           for moduleIndex = 1:numel(moduleList)
               moduleToLoad = moduleList(moduleIndex);
               handleToModule = feval(char(moduleToLoad.class), mediator);
                              
               obj.ModuleMap(moduleToLoad.name) = struct('handle', handleToModule);
               if isprop(handleToModule, 'Context')
                   % Attach the context to modules that want it
                   handleToModule.Context = context;
               end
           end
           
        end
        
        function applyFunctionToModules(obj, functionToApply)
            moduleKeys = obj.ModuleMap.keys;
            for i = 1:numel(moduleKeys)
                module = obj.ModuleMap(moduleKeys{i});
                functionToApply(module);
            end
        end

    end


    methods (Static)
        function moduleList = getModuleListByContext(context)           
            commonModules = [...
                struct("name", "PluginLoader", "class", "matlab.hwmgr.internal.PluginLoader");...
                struct("name", "DeviceList", "class", "matlab.hwmgr.internal.DeviceList");...
            ];            

            hwmgrAppSpecificModules = [...
                struct("name", "StartPage", "class", "matlab.hwmgr.internal.HwmgrAppStartPage");...
            ];
            
            clientAppSpecificModules = [...
                struct("name", "AppletRunner", "class", "matlab.hwmgr.internal.AppletRunner");...
                struct("name", "Toolstrip", "class", "matlab.hwmgr.internal.ClientAppToolstrip");...
                struct("name", "DocumentPane", "class", "matlab.hwmgr.internal.DocumentPane");...
                struct("name", "HelpPanel", "class", "matlab.hwmgr.internal.HelpPanel");...
                struct("name", "StartPage", "class", "matlab.hwmgr.internal.ClientAppStartPage");...
                struct("name", "RunningAppDeviceListPage", "class", "matlab.hwmgr.internal.RunningAppDeviceListPage");...
            ];
            
            if context.IsClientApp
                moduleList = [commonModules; clientAppSpecificModules];
            else
                moduleList = [commonModules; hwmgrAppSpecificModules];
            end
        end
    end
    
end

