classdef (Hidden) ClassBasedProvider < matlab.unittest.internal.TestCaseProvider
    %

    % Copyright 2016-2024 The MathWorks, Inc.
    
    properties (SetAccess=private)
        Parameterization = matlab.unittest.parameters.EmptyParameter.empty;
        SharedTestFixtures = matlab.unittest.fixtures.EmptyFixture.empty;
        Tags = cell(1,0);
    end
    
    properties (Access = private)
        Superclasses = string.empty
    end
    
    properties (Dependent, SetAccess = immutable)
        TestClass
    end
    
    methods (Access=protected)
        function provider = assignTags(provider, testClass, methods)
            import matlab.unittest.internal.determineTagsFor;
            
            tagMap = determineTagsFor(testClass, methods);
            for methodIdx = 1:numel(methods)
                provider(methodIdx).Tags = cellstr(tagMap(methods(methodIdx).Name));
            end
        end
        
        function provider = assignSharedTestFixtures(provider, testClass)
            import matlab.unittest.internal.determineSharedTestFixturesFor;
            
            [provider.SharedTestFixtures] = deal(determineSharedTestFixturesFor(testClass));
        end
        
        function provider = assignNumInputParameters(provider, methods)
            numInputParameters = arrayfun(@(x)max(0, numel(x.InputNames) - 1), ...
                methods, 'UniformOutput', false);
            [provider.NumInputParameters] = numInputParameters{:};
        end
        
        function provider = setParameterization(provider, parameterization)
            provider.Parameterization = parameterization;
        end
        
        function expansion = expandBasedOnParameterization(provider, testClass, methods, varargin)
            import matlab.unittest.parameters.ClassSetupParameter;
            import matlab.unittest.parameters.MethodSetupParameter;
            import matlab.unittest.parameters.TestParameter;
            
            % Use different instances of ParameterDataSource for parameter
            % properties every time a new suite is created.
            paramPropToDataSourceMap = createParamPropToDataSourceMap(testClass);
            
            classSetupParameterSets = ClassSetupParameter.getParameters(testClass,paramPropToDataSourceMap, varargin{:});
            classAndMethodSetupParameterSets = MethodSetupParameter.getParameters(testClass,classSetupParameterSets,paramPropToDataSourceMap, varargin{:});

            % Query all needed information from the metaclass upfront. Invoking
            % TestParameterDefinition methods might delete the metaclass.
            methodNames = {methods.Name};
           
            expansion = cell(size(classAndMethodSetupParameterSets));
            for paramSetIdx = 1:numel(classAndMethodSetupParameterSets)
                setupParamSet = classAndMethodSetupParameterSets(paramSetIdx);
                
                testParameterMap = TestParameter.getParameters(testClass, methods, setupParamSet,paramPropToDataSourceMap, varargin{:});
                
                expansion2 = cell(1,numel(methods));
                for methodIdx = 1:numel(methods)
                    currentMethodName = methodNames{methodIdx};
                    currentProvider = provider(methodIdx);
                    combinedTestParams = testParameterMap(currentMethodName);
                    providersForCurrentMethod = repmat(currentProvider, 1, numel(combinedTestParams));
                    for paramIdx = 1:numel(combinedTestParams)
                        providersForCurrentMethod(paramIdx).Parameterization = ...
                            [setupParamSet{:}.Parameters combinedTestParams{paramIdx}];
                    end
                    expansion2{methodIdx} = providersForCurrentMethod;
                end
                expansion{paramSetIdx}= [expansion2{:}];
            end
            expansion = [provider.empty,expansion{:}];
            
            if numel(expansion) == numel(methods)
                expansion = reshape(expansion, size(methods));
            end
        end
        
        function provider = determineSuperclasses(provider,testClass)
            import matlab.unittest.internal.getAllSuperclassNamesInHierarchy;
            
            superClassNames = getAllSuperclassNamesInHierarchy(testClass);
            [provider.Superclasses] = deal(superClassNames);
        end

        function providers = assignFilenames(providers)
            import matlab.unittest.internal.whichFile;

            if isempty(providers)
                return;
            end

            providers = providers.setFullFilename(string(whichFile(providers(1).TestParentName)));
        end
    end

    methods        
        function superClasses = getSuperclasses(provider)
            if isempty(provider.Superclasses)
                error(message('MATLAB:unittest:TestSuite:UnableToSelectBasedOnTestClass'));
            else
                superClasses = provider.Superclasses;
            end
        end
        
        function bool = supportsThreadBasedPools(~)
            bool = true;
        end
        
        function testClass = get.TestClass(provider)
            testClass = string(provider.TestParentName);
        end
    end
end
function propToDataSourceMap = createParamPropToDataSourceMap(testClass)
csp =  testClass.PropertyList.findobj('ClassSetupParameter',true);
msp =  testClass.PropertyList.findobj('MethodSetupParameter',true);
tp =  testClass.PropertyList.findobj('TestParameter',true);
paramProps = [csp;msp;tp]';
propToDataSourceMap = matlab.unittest.internal.generateParameterPropertyToDataSourceMap(paramProps);
end

% LocalWords:  csp msp tp
