classdef TestParameter < matlab.unittest.parameters.Parameter ...
        & matlab.unittest.internal.parameters.ClassBasedParameter
    % TestParameter - Specification of a Test Parameter.
    %
    %   The matlab.unittest.parameters.TestParameter class holds
    %   information about a single value of a Test Parameter.
    %
    %   TestParameter properties:
    %       Property - Name of the property that defines the Test Parameter
    %       Name     - Name of the Test Parameter
    %       Value    - Value of the Test Parameter

    % Copyright 2013-2024 The MathWorks, Inc.

    methods (Access=private)
        function testParam = TestParameter(varargin)
            testParam = testParam@matlab.unittest.parameters.Parameter(varargin{:});
            [testParam.Test] = deal(true);
        end
    end
    
    methods (Hidden, Static)
        function parameterMap = getParameters(testClass, testMethods, combinedSetupParams, paramPropToDataSourceMap, overriddenParams)
            if nargin < 5
                overriddenParams = matlab.unittest.parameters.Parameter.empty;
            end
            
            parameterMap = getParameterCombinationForEachMethod(testClass, testMethods, overriddenParams, combinedSetupParams, paramPropToDataSourceMap);
        end
        
        function param = fromName(testClass, propName,propToDataSourceMap, name, upLevelParams)
            import matlab.unittest.parameters.TestParameter;
            
            prop = testClass.PropertyList.findobj('Name',propName, 'TestParameter',true);
            if isempty(prop)
                error(message('MATLAB:unittest:Parameter:PropertyNotFound', ...
                    testClass.Name, 'TestParameter', propName));
            end
            
            param = TestParameter(propName,upLevelParams, propToDataSourceMap(propName),name);
        end
        
        function names = getAllParameterProperties(testClass, methodName)
            import matlab.unittest.parameters.Parameter;
            
            method = testClass.MethodList.findobj('Name',methodName);
            names = Parameter.getParameterNamesFor(method);
            names = setdiff(names, getUplevelParameters(testClass));
        end
        
        function param = create(prop, name, value)
            import matlab.unittest.parameters.Parameter;
            import matlab.unittest.parameters.TestParameter;
            
            param = Parameter.create(@TestParameter, prop, name, value);
        end
        
        function param = loadobj(param)
            param.Test = true;
        end
    end
end


function parameterMap = getParameterCombinationForEachMethod(testClass, testMethods, overriddenParams, combinedSetupParamSet, paramPropToDataSourceMap)
import matlab.unittest.parameters.TestParameter;
import matlab.unittest.parameters.Parameter;

uplevelParameters = getUplevelParameters(testClass);
emptyParameter = {matlab.unittest.parameters.EmptyParameter.empty};

% Query all needed information from the metaclass upfront. Invoking
% TestParameterDefinition methods might delete the metaclass.
testMethods = [matlab.unittest.meta.method.empty(1,0); testMethods(:)];
methodNames = {testMethods.Name};
allParameterNames = arrayfun(@(aMethod)TestParameter.getParameterNamesFor(aMethod), testMethods, UniformOutput=false);
parameterCombinationDefinitions = {testMethods.ParameterCombinationDefinition};

% Initialize a map of parameter arrays to return
parameterMap = containers.Map('KeyType','char', 'ValueType','any');
for methodIdx = 1:numel(testMethods)
    methodName = methodNames{methodIdx};
    
    testParameterNames = allParameterNames{methodIdx};
    if ~isempty(testParameterNames) && ~isempty(uplevelParameters)
        testParameterNames = setdiff(testParameterNames, uplevelParameters, 'stable');
    end
    
    numParams = numel(testParameterNames);
    if numParams == 0
        % Method is not parameterized with TestParameters
        parameterMap(methodName) = emptyParameter;
        continue;
    end
    
    [~,propMatch] = ismember({overriddenParams.Property}, testParameterNames);
    setupParamSet = {[combinedSetupParamSet{:}.Parameters]};
    
    % Look up values of the Test Parameters and store in a cell array.
    parametersCell = cell(1, numParams);
    for paramIdx = 1:numParams
        paramName = testParameterNames{paramIdx};
        
        mask = propMatch == paramIdx;
        if any(mask)
            paramObjects = convert(overriddenParams(mask), @TestParameter.create);
        else
            paramObjects = TestParameter(paramName, setupParamSet, paramPropToDataSourceMap(paramName));
        end
        parametersCell{paramIdx} = paramObjects;
    end
    
    validExtSizes = Parameter.validExtParamSizesForSequentialCombination(parameterCombinationDefinitions{methodIdx}, parametersCell);
    if ~validExtSizes
        error(message('MATLAB:unittest:Parameter:IncompatibleExternalParameterSizes',...
            methodName, testClass.Name));
    end
    
    % Create the combinations according to the ParameterCombination attribute.
    combinedParams = parameterCombinationDefinitions{methodIdx}.combine(parametersCell);
    parameterMap(methodName) = combinedParams;
end
end

function uplevelParameters = getUplevelParameters(testClass)
classSetupParameters = testClass.PropertyList.findobj('ClassSetupParameter',true);
methodSetupParameters = testClass.PropertyList.findobj('MethodSetupParameter',true);
uplevelParameters = [{classSetupParameters.Name}, {methodSetupParameters.Name}];
end

% LocalWords:  unittest uplevel
