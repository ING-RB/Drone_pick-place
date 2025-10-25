classdef MethodSetupParameter < matlab.unittest.parameters.Parameter ...
        & matlab.unittest.internal.parameters.ClassBasedParameter
    % MethodSetupParameter - Specification of a Method Setup Parameter.
    %
    %   The matlab.unittest.parameters.MethodSetupParameter class holds
    %   information about a single value of a Method Setup Parameter.
    %
    %   TestParameter properties:
    %       Property - Name of the property that defines the Method Setup Parameter
    %       Name     - Name of the Method Setup Parameter
    %       Value    - Value of the Method Setup Parameter
    
    % Copyright 2013-2020 The MathWorks, Inc.
    
    
    methods (Access=private)
        function methodParam = MethodSetupParameter(varargin)
            methodParam = methodParam@matlab.unittest.parameters.Parameter(varargin{:});
            [methodParam.MethodSetup] = deal(true);
        end
    end
    
    methods (Hidden, Static)
        function params = getParameters(testClass, classSetupParamSet, paramPropToDataSourceMap, overriddenParams)
            import matlab.unittest.internal.parameters.SetupParameter;
            import matlab.unittest.parameters.MethodSetupParameter;
            
            if nargin < 4
                overriddenParams = MethodSetupParameter.empty(1, 0);
            end
            
            params = SetupParameter.getSetupParameters(testClass, @MethodSetupParameter, ...
                'TestMethodSetup', classSetupParamSet, paramPropToDataSourceMap, ...
                overriddenParams,@MethodSetupParameter.create);
        end
        
        function param = fromName(testClass, propName, propToDataSourceMap, name, upLevelParams)
            import matlab.unittest.internal.parameters.SetupParameter;
            import matlab.unittest.parameters.MethodSetupParameter;
            
            param = SetupParameter.fromName(testClass, propName, propToDataSourceMap, name, ...
                @MethodSetupParameter, 'MethodSetupParameter',upLevelParams);
        end
        
        function names = getAllParameterProperties(testClass)
            import matlab.unittest.internal.parameters.SetupParameter;
            
            uplevelParameters = SetupParameter.getAllParameterProperties(testClass, 'TestClassSetup', {});
            names = SetupParameter.getAllParameterProperties(testClass, ...
                'TestMethodSetup', uplevelParameters);
        end
        
        function param = create(prop, name, value)
            import matlab.unittest.parameters.Parameter;
            import matlab.unittest.parameters.MethodSetupParameter;
            
            param = Parameter.create(@MethodSetupParameter, prop, name, value);
        end
        
        function param = loadobj(param)
            param.MethodSetup = true;
        end
    end
end


% LocalWords:  unittest uplevel
