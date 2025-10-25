classdef TestParameterDefinitionCache < handle
    %
    
    % Copyright 2020-2021 The MathWorks, Inc.   
    properties (Access=private)
        IOMapID double
        CurrentIOMapID double
        TPDMethodOutputNames
        TPDMethodInputNames
        OutputNameToValuesMap
        InputsLogged = {};
        TPDMethodHandle
        TPDMetaMethod
    end
    
        
    methods
        function cache = TestParameterDefinitionCache(metaMethod, tpdMethodHandle)
            validateattributes(metaMethod,{'matlab.unittest.meta.method'},{'scalar'});
            
            cache.TPDMethodOutputNames = metaMethod.OutputNames;
            cache.TPDMethodInputNames = metaMethod.InputNames;
            cache.OutputNameToValuesMap = generateOutputToValuesMap(cache.TPDMethodOutputNames);
            cache.IOMapID = 0;
            cache.CurrentIOMapID = 0;
            cache.TPDMethodHandle = tpdMethodHandle;
            cache.TPDMetaMethod = metaMethod;
        end
        
        function valuesCell = accessValuesForProperty(cache,propertyName,upLevelParameters)
            cache.updateCache(upLevelParameters);
            
            IOMap = cache.OutputNameToValuesMap(propertyName);  
            dataSource = IOMap(cache.CurrentIOMapID);
            valuesCell = dataSource.getValues(propertyName,upLevelParameters);           
        end
        
        function namesCell = accessNamesForProperty(cache,propertyName,upLevelParameters)
            cache.updateCache(upLevelParameters);
            
            IOMap = cache.OutputNameToValuesMap(propertyName);  
            dataSource = IOMap(cache.CurrentIOMapID);
            namesCell = dataSource.getNames(propertyName,upLevelParameters);
        end
    end
    
    methods (Access=private)
        
        function logIO(cache, inputParams, outputDataSources)
            % Log the input and output sets in the cache for future use
            
            cache.IOMapID = cache.IOMapID + 1; 
            cache.CurrentIOMapID = cache.IOMapID;
            cache.InputsLogged = [cache.InputsLogged, {inputParams}];
            cache.updateOutputNameToValuesMap(outputDataSources, cache.IOMapID);            
        end
        
        function bool = inputLogged(cache,inputParams)
            % This method checks if the TestParameterDefinition method has
            % been invoked with a set of inputs previously. To check that,
            % we match the Property and the Names of the new input
            % parameters with the previously logged ones.
            bool = false;
            for inputIdx = 1:numel(cache.InputsLogged)
                loggedInputParams = cache.InputsLogged{inputIdx};
                
                bool = cache.compareParameterArrays(inputParams,loggedInputParams);
                
                if bool
                    cache.CurrentIOMapID = inputIdx;
                    return;
                end
            end
        end
        
        function updateOutputNameToValuesMap(cache,outputDataSource, IOMapID)
            
            % update the map to store the output data for each outputname
            for idx = 1:numel(outputDataSource)
                IOMap = cache.OutputNameToValuesMap(cache.TPDMethodOutputNames{idx}); 
                IOMap(IOMapID) =  outputDataSource(idx);
                cache.OutputNameToValuesMap(cache.TPDMethodOutputNames{idx}) = IOMap;
            end
        end
                
        function updateCache(cache,upLevelParameters)
            % Generate output for each combination of input that the
            % TestParameterDefinition method can get and store it in the cache. Invoke
            % the TestParameterDefinition method only if it has not been invoked with a
            % particular combination of inputs.
            numberOfInputCombinations = size(upLevelParameters,1);
            cls = cache.TPDMetaMethod.DefiningClass;
            className = cls.Name;
            if numberOfInputCombinations > 0
                inputsParams = upLevelParameters;
                cache.invokeTPDMethodIfNeeded(cache.TPDMethodHandle,inputsParams,cache.TPDMethodOutputNames,className);
            else % TestParameterDefinition method does not accept any inputs. Invoke the method once, if needed.
                cache.invokeTPDMethodIfNeeded(cache.TPDMethodHandle , matlab.unittest.parameters.Parameter.empty,cache.TPDMethodOutputNames,className);
            end
        end
        
        function invokeTPDMethodIfNeeded(cache,methodHandle,inputParams, outputNames, className)
            
            fcnInvokedWithSameInputs = cache.inputLogged(inputParams);
            methodName = cache.TPDMetaMethod.Name;
            if ~fcnInvokedWithSameInputs
                % Capture the output in a cell and convert it to appropriate
                % ParameterDataSource instances for storing in the cache.
                outputsPerCall = cell(1,numel(outputNames));
                dataSources = cell(1,numel(outputNames));
                [outputsPerCall{:}] = methodHandle(inputParams.Value);
                for idx = 1:numel(outputNames)
                    dataSources{idx} = getParameterDataSourceForOutputs(outputsPerCall{idx},methodName,outputNames{idx},className);
                end
                cache.logIO(inputParams,[dataSources{:}]);
            end
        end
        
        function bool = compareParameterArrays(~,inputParams,loggedInputParams)
            % compare the Name and Property of the inputParams and
            % loggedInputParams with all of the up-level params that they 
            % depend on
            inputParams_WithupLevelParams = inputParams.getParamWithUpLevelDependencyParams;
            loggedInputParams_WithUpLevelParams = loggedInputParams.getParamWithUpLevelDependencyParams;
            
            % Match the test parameter Property
            actUpLevelPropertyNameArray = {inputParams_WithupLevelParams.Property};
            loggedUpLevelPropertyNameArray = {loggedInputParams_WithUpLevelParams.Property};
            propNameEqual = isequal(actUpLevelPropertyNameArray,loggedUpLevelPropertyNameArray);
            
            % Match the test parameter Name
            actUpLevelParamNameArray = {inputParams_WithupLevelParams.Name};
            loggedUpLevelParamNameArray = {loggedInputParams_WithUpLevelParams.Name};
            paramNameEqual = isequal(actUpLevelParamNameArray,loggedUpLevelParamNameArray);
            
            bool = propNameEqual && paramNameEqual ;
        end
    end
end
function cache = generateOutputToValuesMap(outputNames)
% cache is a map that stores a map of all inputs to outputs for a given
% property name.
cache = containers.Map('KeyType','char','ValueType','any');

% iterate through all properties written by the TestParameterDefinition
% method
for idx = 1:numel(outputNames)
    cache(outputNames{idx}) = containers.Map('KeyType','double','ValueType','any');
end
end
function paramDataSource = getParameterDataSourceForOutputs(outputs,methodName, propName,className)
try
    paramDataSource = matlab.unittest.internal.parameters.ParameterDataSource.fromData(outputs);
catch exp
    exception = MException(message('MATLAB:unittest:TestCase:InvalidValueForParameter',methodName, propName,className));
    exception = exception.addCause(exp);
    throwAsCaller(exception);
end
end