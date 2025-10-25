classdef SetupParameter < matlab.unittest.parameters.Parameter ...
        & matlab.unittest.internal.parameters.ClassBasedParameter
    %

    % Copyright 2013-2020 The MathWorks, Inc.
    
    methods (Static)
        function paramSets = getSetupParameters(testClass, paramConstructor, setupType, uplevelParameterSets, varargin)
            import matlab.unittest.internal.parameters.SetupParameter;
            import matlab.unittest.parameters.Parameter;
            
            activeSetupParameters = testClass.("Active" + setupType + "ParameterNames");
            if isempty(activeSetupParameters)
                % No setup level parameterization.
                paramSets = uplevelParameterSets;
                return;
            end
            
            % Determine how the setup methods combine the parameters.
            setupLevelCombination = testClass.(setupType + "ParameterCombination");
            
            % Iterate through each of the up-level parameter combination
            % set to generate the parameter objects pertaining to that set.
            paramSetsCell = cell(1,numel(uplevelParameterSets));
            for upLevelParamIdx = 1:numel(uplevelParameterSets)
                upLevelParams = {[uplevelParameterSets{upLevelParamIdx}.Parameters]};
                
                % Construct Parameter arrays for each parameter used.
                setupParameterArrays = getSetupLevelParameters(activeSetupParameters, ...
                    paramConstructor,  upLevelParams, varargin{:});
                
                validSizes = Parameter.validExtParamSizesForSequentialCombination(setupLevelCombination, setupParameterArrays);
                if ~validSizes
                    error(message('MATLAB:unittest:Parameter:IncompatibleExternalParameterSizesSetupMethods',...
                        setupType, testClass.Name));
                end
                
                params = setupLevelCombination.combine(setupParameterArrays);                
                paramSetsCell{upLevelParamIdx} = combineWithUpLevelParamsAndCreateParamSets(params,upLevelParams);
            end
            paramSets = [paramSetsCell{:}];
        end


        
        function param = fromName(testClass, propName, propToDataSourceMap, name, paramConstructor, paramType, upLevelParams)
            
            prop = testClass.PropertyList.findobj('Name',propName, paramType,true);
            if isempty(prop)
                error(message('MATLAB:unittest:Parameter:PropertyNotFound', ...
                    testClass.Name, paramType, propName));
            end
            
            param = paramConstructor(prop.Name,upLevelParams,propToDataSourceMap(propName), name);
        end
        
        function names = getAllParameterProperties(testClass, setupType, uplevelParameters)
            paramNameToMethodsMap = getSetupParameterMap(testClass, setupType, uplevelParameters);
            names = sort(paramNameToMethodsMap.keys);
        end
    end
    
end


function paramNameToMethodsMap = getSetupParameterMap(testClass, setupType, uplevelParameters)
% getSetupParameterMap - Return a mapping from parameter names to the
%   method(s) which use that parameter.

import matlab.unittest.parameters.Parameter;

setupMethods = rot90(testClass.MethodList.findobj(setupType,true));
paramNameToMethodsMap = containers.Map('KeyType','char', 'ValueType','any');

for method = setupMethods
    paramNames = Parameter.getParameterNamesFor(method);
    paramNames = setdiff(paramNames, uplevelParameters);
    
    for parameterIdx = 1:numel(paramNames)
        parameterName = paramNames{parameterIdx};
        
        % Add the method to the map, appending to the list of other methods
        % that also use the parameter.
        if paramNameToMethodsMap.isKey(parameterName)
            paramNameToMethodsMap(parameterName) = [paramNameToMethodsMap(parameterName), method];
        else
            paramNameToMethodsMap(parameterName) = method;
        end
    end
end
end


function parameterArrays = getSetupLevelParameters(activeSetupParameters, parameterConstructor,...
                                   uplevelParameters, paramPropToDataSourceMap, overriddenParameters, convertMethod)
% getSetupLevelParameters - Construct arrays of setup-level Parameters.

numSetupParameters = numel(activeSetupParameters);
parameterArrays = cell(1,numSetupParameters);

for paramIdx = 1:numSetupParameters
    paramName = activeSetupParameters{paramIdx};
    
    mask = getOverriddenParameterMask(paramName, overriddenParameters);
    if any(mask)
        paramObjects = convert(overriddenParameters(mask), convertMethod);
    else
        paramObjects = parameterConstructor(paramName,uplevelParameters, paramPropToDataSourceMap(paramName));
    end
    parameterArrays{paramIdx} = paramObjects;
end
end


function mask = getOverriddenParameterMask(paramName, overriddenParameters)
mask = strcmp(paramName, {overriddenParameters.Property});
end


function paramSets = combineWithUpLevelParamsAndCreateParamSets(paramObjectCell,upLevelParams)
paramSets = cell(1,numel(paramObjectCell));
for k = 1:numel(paramObjectCell)
    paramSets{k} =  matlab.unittest.internal.parameters.CombinedParameterSet([upLevelParams{:},paramObjectCell{k}]);
end
end

% LocalWords:  unittest uplevel
