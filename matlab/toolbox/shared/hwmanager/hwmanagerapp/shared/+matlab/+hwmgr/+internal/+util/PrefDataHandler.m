classdef PrefDataHandler < handle
    % Utility class to write and read data from the Hardware Manager cache.
    % The cache is a MAT file that lives in the prefdir.
    
    % Copyright 2018 Mathworks Inc.
    properties (Constant)
        MatFileName = 'hwmgrData';
        DevicesVarName = 'cachedDevices';
        AppConfigVarName = 'appAutoLoadData';
        ParamValMapVarName = 'paramValMapData';
        MatFilePath = fullfile(prefdir, matlab.hwmgr.internal.util.PrefDataHandler.MatFileName);
    end
    
    methods (Static)
        
        function writeDevicesToCache(devices)
            import matlab.hwmgr.internal.util.PrefDataHandler;
            PrefDataHandler.writeDataToCache(devices, PrefDataHandler.DevicesVarName);
        end
        
        function [data, errorID] = loadDevicesFromCache()
            import matlab.hwmgr.internal.util.PrefDataHandler;
            [data, errorID] = PrefDataHandler.loadDataFromCache(PrefDataHandler.DevicesVarName);
        end
        
        function writeAppConfigDataToCache(appConfigDataStruct)
            import matlab.hwmgr.internal.util.PrefDataHandler;
            PrefDataHandler.writeDataToCache(appConfigDataStruct, PrefDataHandler.AppConfigVarName);
        end
        
        function [data, errorID] = loadAppConfigDataFromCache()
            import matlab.hwmgr.internal.util.PrefDataHandler;
            [data, errorID] = PrefDataHandler.loadDataFromCache(PrefDataHandler.AppConfigVarName);
        end
        
        function writeParamValMapToCache(paramValMapStruct)
            import matlab.hwmgr.internal.util.PrefDataHandler;
            PrefDataHandler.writeDataToCache(paramValMapStruct, PrefDataHandler.ParamValMapVarName);
        end
        
        function [data, errorID] = loadParamValMapsFromCache()
            import matlab.hwmgr.internal.util.PrefDataHandler;
            [data, errorID] = PrefDataHandler.loadDataFromCache(PrefDataHandler.ParamValMapVarName);
        end
        
        function deleteCacheFile()
            cacheFilePath = [matlab.hwmgr.internal.util.PrefDataHandler.MatFilePath '.mat'];
            if exist(cacheFilePath, 'file')
                delete([matlab.hwmgr.internal.util.PrefDataHandler.MatFilePath '.mat']);
            end
        end
        
    end
    
    methods (Static, Access = private)
        function writeDataToCache(data, varName) %#ok<INUSL>
            eval([varName '= data;']);
            matFile = [matlab.hwmgr.internal.util.PrefDataHandler.MatFilePath '.mat'];
            if exist(matFile, 'file')
                save(matFile, varName, '-append');
            else
                save(matFile, varName);
            end
        end
        
        function [data, errorID] = loadDataFromCache(varToLoad)

            import matlab.hwmgr.internal.util.PrefDataHandler;
            matFile = [PrefDataHandler.MatFilePath '.mat'];
            data = [];
            errorID = string.empty;

            if ~exist(matFile, 'file')
                return;
            end

            % If the variable being fetched does not exist, the load function will generate 
            % a warning (variableNotFound) on the command window. Disable the warning as we
            % handle it internally
            warnState = warning('off','MATLAB:load:variableNotFound');
            
            % Catch any exception generated while accessing the mat file (such as accessability, corruption)
            try
                s = load(PrefDataHandler.MatFilePath, varToLoad);
                
                varsInFile = whos('-file', matFile);

                if any(arrayfun(@(var)strcmp(var.name, varToLoad),varsInFile))
                    data = s.(varToLoad);
                end
            catch ex
                errorID = ex.identifier;
            end
            
            warning(warnState);
        end
    
    end
    
end