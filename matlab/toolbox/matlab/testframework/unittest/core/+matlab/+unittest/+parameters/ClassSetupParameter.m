classdef ClassSetupParameter < matlab.unittest.parameters.Parameter ...
        & matlab.unittest.internal.parameters.ClassBasedParameter
    % ClassSetupParameter - Specification of a Class Setup Parameter.
    %
    %   The matlab.unittest.parameters.ClassSetupParameter class holds
    %   information about a single value of a Class Setup Parameter.
    %
    %   TestParameter properties:
    %       Property - Name of the property that defines the Class Setup Parameter
    %       Name     - Name of the Class Setup Parameter
    %       Value    - Value of the Class Setup Parameter
    
    % Copyright 2013-2020 The MathWorks, Inc.
    
    
    methods (Access=private)
        function classParam = ClassSetupParameter(varargin)
            classParam = classParam@matlab.unittest.parameters.Parameter(varargin{:});
            [classParam.ClassSetup] = deal(true);
        end
    end
    
    methods (Hidden, Static)
        function params = getParameters(testClass, paramPropToDataSourceMap, overriddenParams)
            import matlab.unittest.internal.parameters.SetupParameter;
            import matlab.unittest.parameters.ClassSetupParameter;
                        
            if nargin < 3
                overriddenParams = ClassSetupParameter.empty(1, 0);
            end
            
            upLevelParameterSet = {matlab.unittest.internal.parameters.CombinedParameterSet(matlab.unittest.parameters.EmptyParameter.empty)};
            params = SetupParameter.getSetupParameters(testClass, @ClassSetupParameter, ...
                'TestClassSetup',  upLevelParameterSet, paramPropToDataSourceMap, overriddenParams,...
                @ClassSetupParameter.create);
            
        end
        
        function param = fromName(testClass, propName, propToDataSourceMap, name, upLevelParams)
            import matlab.unittest.internal.parameters.SetupParameter;
            import matlab.unittest.parameters.ClassSetupParameter;
            
            param = SetupParameter.fromName(testClass, propName, propToDataSourceMap, name, ...
                @ClassSetupParameter, 'ClassSetupParameter', upLevelParams);
        end
        
        function names = getAllParameterProperties(testClass)
            import matlab.unittest.internal.parameters.SetupParameter;
            
            names = SetupParameter.getAllParameterProperties(testClass, ...
                'TestClassSetup', {});
        end
        
        function param = create(prop, name, value)
            import matlab.unittest.parameters.Parameter;
            import matlab.unittest.parameters.ClassSetupParameter;
            
            param = Parameter.create(@ClassSetupParameter, prop, name, value);
        end
        
        function param = loadobj(param)
            param.ClassSetup = true;
        end
    end
end

% LocalWords:  unittest
