classdef Parameter < matlab.mixin.Heterogeneous
    % Parameter - Base class for parameters.
    %
    %   Parameters provide the ability to pass data to methods defined in a
    %   TestCase class.
    %
    %   Parameter properties:
    %       Property - Name of the property that defines the Parameter
    %       Name     - Name of the Parameter
    %       Value    - Value of the Parameter
    %
    %   Parameter methods:
    %       fromData - Create parameters from data
    
    % Copyright 2013-2022 The MathWorks, Inc.
    
    
    properties (SetAccess=private)
        % Property - Name of the property that defines the Parameter
        %
        %   A character vector representing the name of the property
        %   defining the Parameter.
        Property = '';
        
        % Name - Name of the Parameter
        %
        %   The Name property is a character vector which uniquely identifies a
        %   particular value for a Parameter.
        Name = '';
        
        % Value - Value of the Parameter
        %
        %   The Value property holds the data that the Test Runner passes
        %   into the parameterized method that uses the Parameter.
        Value = [];
    end

    properties(Hidden,SetAccess=private)
        LegacyName = '';
    end
    
    properties (Hidden, SetAccess=protected)
        External = false;
    end
    
    properties(Access=private)
        Dynamic = false;
        UpLevelDependency = matlab.unittest.parameters.Parameter.empty;
    end
    
    % Store parameter type for improved performance of filterByType
    properties (Hidden, Transient, SetAccess=protected, GetAccess=private)
        ClassSetup = false;
        MethodSetup = false;
        Test = false;
    end
    
    methods (Access=protected, Hidden)
        function param = Parameter(propName, upLevelParameters, dataSource, selectedName)
            % Parameter - Construct a Parameter array from a matlab.unittest.meta.property name.
            %
            %   This method constructs an array of Parameter objects based on the
            %   parameter values defined by the property.
            
            % Allow zero-input constructor for pre-allocation.
            if nargin == 0
                return;
            end
            
            allNames = dataSource.getNames(propName, upLevelParameters);
            names = allNames(1,:);
            legacyNames = allNames(2,:);
            values = dataSource.getValues(propName, upLevelParameters);
            
            if nargin > 3
                mask = strcmp(names, selectedName);
                if ~any(mask)
                    mask = strcmp(legacyNames, selectedName);
                    if any(mask)
                        warning(message('MATLAB:unittest:Parameter:MatchingUsingLegacyNames', ...
                            legacyNames{mask}, propName, names{mask}));
                    end
                end
                names = names(mask);
                values = values(mask);
                legacyNames = legacyNames(mask);
                if isempty(names)
                    error(message("MATLAB:unittest:Parameter:NameNotFound", selectedName));
                end
            end
            
            param(1:numel(names)) = param;
            
            [param.Property] = deal(propName);
            [param.Name] = names{:};
            [param.LegacyName] = legacyNames{:};
            [param.Value] = values{:};
            [param.Dynamic] = deal(dataSource.Dynamic);
            filteredUpLevelParameters = dataSource.getFilteredParameterDependencies(upLevelParameters);
            [param.UpLevelDependency] = deal(filteredUpLevelParameters);
        end
    end
    
    methods (Hidden, Static)
        function param = create(paramConstructor, prop, name, value)
            param = paramConstructor();
            param.Property = prop;
            param.Name = name;
            param.LegacyName = name;
            param.Value = value;
        end
    end
    
    methods (Static)
        function params = fromData(varargin)
            %FROMDATA Create parameters from data.
            %  PARAM = matlab.unittest.parameters.Parameter.fromData(PROP, VALUES)
            %  creates an array of Parameters where PROP defines the Property
            %  value for all Parameter elements and VALUES defines the values of
            %  Name and Value for each Parameter element. VALUES is a non-empty
            %  cell array or a struct.
            %
            %  This is analogous to defining Parameters within a class-based
            %  test using a "properties" block, such as:
            %
            %    properties (TestParameter)
            %        PROP = VALUES
            %    end
            %
            %  PARAM = matlab.unittest.parameters.Parameter.fromData(PROP_1, VALUES_1, ...)
            %  creates Parameters for multiple Parameter Property values.
            %
            %  Examples:
            %    import matlab.unittest.parameters.Parameter;
            %
            %    % Create Parameters using a cell array
            %    param = Parameter.fromData('MyParam', {1, 10, 100});
            %
            %    % Create Parameters using a struct
            %    values = struct('small', 1, 'medium', 10, 'large', 100);
            %    param = Parameter.fromData('MyParam', values);
            %
            %    % Use these parameters in any suite-creation method of TestSuite:
            %    import matlab.unittest.TestSuite;
            %    suite = TestSuite.fromClass(?MyClass, 'ExternalParameters', param);
            %
            %  See also matlab.unittest.TestSuite
            
            import matlab.unittest.parameters.Parameter;
            import matlab.unittest.internal.parameters.ParameterDataSource;
            
            % error if odd, need at least one more
            narginchk(nargin + mod(nargin,2), Inf);
            
            parser = inputParser;
            parser.KeepUnmatched = true;
            parser.parse(varargin{:});
            
            inputs = parser.Unmatched;
            propertySpecified = fieldnames(inputs);
            
            numOfSpecifiedProperties = numel(propertySpecified);
            params = cell(1,numOfSpecifiedProperties);
            emptyParam = matlab.unittest.parameters.EmptyParameter.empty;
            
            for i=1:numOfSpecifiedProperties
                property = propertySpecified{i};
                values = inputs.(property);
                
                dataSource = ParameterDataSource.fromData(values);
                allNames = dataSource.getNames(property,emptyParam);
                names = allNames(1,:);
                values = dataSource.getValues(property,emptyParam);
                
                params_i = cellfun( ...
                    @(name,value)Parameter.create(@Parameter, property, name, value), ...
                    names, values(:).', 'UniformOutput', false);
                params{i} = [params_i{:}];
            end
            
            params = [Parameter.empty(1,0) params{:}];
        end
    end
    
    methods (Hidden, Sealed)
        function [classParams, methodParams, testParams] = filterByType(params)
            classParams = params([params.ClassSetup]);
            if nargout > 1
                methodParams = params([params.MethodSetup]);
                testParams = params([params.Test]);
            end
        end
        
        function inputs = getInputsFor(testParams, method)
            % getInputsFor - Get input parameter values for a method.
            %
            %   getInputsFor returns a cell array of parameter values to be passed to a
            %   method. The values are taken from the specified array of Parameters. If
            %   the method does not belong to a matlab.unittest.TestCase class or if
            %   the method is not parameterized, an empty cell array is returned.
            
            import matlab.unittest.parameters.Parameter;
            
            % Only methods defined inside a matlab.unittest.TestCase class
            % can be parameterized.
            if ~(metaclass(method) <= ?matlab.unittest.meta.method)
                inputs = cell(1,0);
                return;
            end
            
            parameterNames = Parameter.getParameterNamesFor(method);
            paramProps = {testParams.Property};
            numInputs = numel(parameterNames);
            
            inputs = cell(1,numInputs);
            for idx = 1:numInputs
                % There should be exactly one Parameter in the array whose
                % Property matches the desired parameter name.
                inputs{idx} = testParams(strcmp(parameterNames{idx}, paramProps)).Value;
            end
        end
        
        function params = convert(params, converterMethod)
            params = arrayfun(@(p)converterMethod(p.Property,p.Name,p.Value), params);
            [params.External] = deal(true);
        end
        
        function paramsArray = getParamWithUpLevelDependencyParams(param)
            paramsArray = param;
            if ~isempty([param.UpLevelDependency])
                upLevelParamsCell =  arrayfun(@(x)x.getParamWithUpLevelDependencyParams,[param.UpLevelDependency],'UniformOutput',false);
                paramsArray = [paramsArray,upLevelParamsCell{:}];
            end
            
        end
    end
    
    
    methods (Hidden, Sealed, Static, Access=protected)
        function instance = getDefaultScalarElement
            instance = matlab.unittest.parameters.EmptyParameter;
        end
        
        function parameterNames = getParameterNamesFor(method)
            % getParameterNamesFor - Get the names of the parameters a method references.
            
            parameterNames = method.InputNames;
            
            % Remove TestCase input argument
            if numel(parameterNames) > 0
                parameterNames(1) = [];
            end
            
            % Always return a row vector
            parameterNames = reshape(parameterNames, 1, []);
        end
        
        function valid = validExtParamSizesForSequentialCombination(combination, parameters)
            valid = true;
            if isa(combination, "matlab.unittest.internal.parameters.SequentialCombination")
                allParameters = [parameters{:}];
                if any([allParameters.External]) || any([allParameters.Dynamic])
                    valid = numel(unique(cellfun(@numel, parameters))) < 2;
                end
            end
        end
    end
end



% LocalWords:  flds vals sz Kuo Tai Yu codetools lang FROMDATA
