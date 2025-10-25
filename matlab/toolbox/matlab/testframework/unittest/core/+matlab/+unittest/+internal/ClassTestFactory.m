classdef ClassTestFactory < matlab.unittest.internal.MATLABCodeTestFactory
    % This class is undocumented.
    
    % ClassTestFactory - Factory for creating suites for TestCase classes.
    
    % Copyright 2014-2023 The MathWorks, Inc.
    
    properties(Constant)
        SupportsParameterizedTests = true;
    end
    
    properties (SetAccess=immutable)
        TestClass matlab.unittest.meta.class;
    end
    
    properties (SetAccess=private, GetAccess=protected)
        Filename;
    end
    
    methods
        function factory = ClassTestFactory(testClass)
            factory.TestClass = testClass;
        end
        
        function suite = createSuiteFromProcedureName(factory, procedureName, modifier, parameters)
            suite = matlab.unittest.Test.fromMethod(factory.TestClass, procedureName, modifier, parameters);
        end
        
        function suite = createSuiteFromName(factory, nameParser, parameters)
            % Optimized version of createSuiteFromName that avoids creating
            % the entire test suite.
            
            import matlab.unittest.Test;
            import matlab.unittest.internal.convertMethodNameToMetaMethod;
            import matlab.unittest.internal.TestCaseClassProvider;
            import matlab.unittest.parameters.ClassSetupParameter;
            import matlab.unittest.parameters.MethodSetupParameter;
            import matlab.unittest.parameters.TestParameter;
            
            testClass = factory.TestClass;
            
            % Determine and validate the TestMethod
            [status, msg, method] = convertMethodNameToMetaMethod(testClass, nameParser.TestName);
            if ~status
                throwAsCaller(MException(msg));
            end
            
            % Create copy of parameter data source objects used to resolve
            % parameter values.
            propToDataSourceMap = createParamPropToDataSourceMap(testClass, nameParser);
            
            % Determine and validate parameters
            classSetupParameters = constructParameters(nameParser.ClassSetupParameters, ...
                ClassSetupParameter.getAllParameterProperties(testClass), nameParser.Name, 'ClassSetup', ...
                @(propName,name)ClassSetupParameter.fromName(testClass, propName, propToDataSourceMap, name, {matlab.unittest.parameters.EmptyParameter.empty}), ...
                parameters, @ClassSetupParameter.create);
            
            methodSetupParameters = constructParameters(nameParser.MethodSetupParameters, ...
                MethodSetupParameter.getAllParameterProperties(testClass), nameParser.Name, 'MethodSetup', ...
                @(propName,name)MethodSetupParameter.fromName(testClass, propName, propToDataSourceMap, name,{classSetupParameters}), ...
                parameters, @MethodSetupParameter.create);
            
            testParameters = constructParameters(nameParser.TestMethodParameters, ...
                TestParameter.getAllParameterProperties(testClass, nameParser.TestName), nameParser.Name, 'Test', ...
                @(propName,name)TestParameter.fromName(testClass, propName, propToDataSourceMap, name,{[classSetupParameters methodSetupParameters]}), ...
                parameters, @TestParameter.create);
            
            parameters = [classSetupParameters, methodSetupParameters, testParameters];
            provider = TestCaseClassProvider.withSpecificParameterization(testClass, method, parameters);
            suite = Test.fromProvider(provider);
        end
        
        function filename = get.Filename(factory)
            import matlab.unittest.internal.whichFile;
            filename = whichFile(factory.TestClass.Name);
        end
    end
    
    methods (Access=protected)
        function suite = createSuite(factory, modifier, parameters)
            suite = matlab.unittest.Test.fromClass(factory.TestClass, modifier, parameters);
        end
    end
    
    methods(Hidden)
        function bool = isValidProcedureName(factory,procedureName)
            metaMethod = findobj(factory.TestClass.MethodList, 'Name', procedureName);
            bool = ...
                ~isempty(metaMethod) && ...
                metaclass(metaMethod) <= ?matlab.unittest.meta.method && ...
                metaMethod.Test;
        end
    end 
end

function parameters = constructParameters(paramInfo, allParamPropNames, ...
    name, paramType, fromNameMethod, ...
    externalParameters, fromDataMethod)
import matlab.unittest.parameters.EmptyParameter;

% Make sure the correct set of parameters was specified
if ~isempty(setxor(allParamPropNames, {paramInfo.Property}))
    if isempty(allParamPropNames)
        error(message('MATLAB:unittest:TestSuite:NoParametersNeeded', ...
            paramType));
    else
        error(message('MATLAB:unittest:TestSuite:IncorrectParameters', ...
             name));
    end
end

numParameters = numel(paramInfo);
parameters(1:numParameters) = EmptyParameter;
extmask = [paramInfo.External];

% apply "ordinary" parameters
params = paramInfo(~extmask);
P = cellfun(fromNameMethod, {params.Property}, {params.Name}, 'UniformOutput', false);
parameters(~extmask) = [EmptyParameter.empty(1,0) P{:}];

% apply externally-specified parameters
inputProps = {externalParameters.Property};
inputNames = {externalParameters.Name};
for idx = find(extmask)
    p = paramInfo(idx);
    match = strcmp(p.Property, inputProps) & strcmp(p.Name, inputNames);
    if nnz(match) ~= 1
        % not a unique match
        error( message('MATLAB:unittest:TestSuite:UnmatchedParameter', p.Property, p.Name) );
    end
    parameters(idx) = convert(externalParameters(match), fromDataMethod);
end

end

function propToDataSourceMap = createParamPropToDataSourceMap(testClass, nameParser)
csp = cellfun(@(name)testClass.PropertyList.findobj('Name',name),{nameParser.ClassSetupParameters.Property},'UniformOutput',false);
msp = cellfun(@(name)testClass.PropertyList.findobj('Name',name),{nameParser.MethodSetupParameters.Property},'UniformOutput',false);
tp = cellfun(@(name)testClass.PropertyList.findobj('Name',name),{nameParser.TestMethodParameters.Property},'UniformOutput',false);
paramProps = [csp{:},msp{:},tp{:}];
propToDataSourceMap = matlab.unittest.internal.generateParameterPropertyToDataSourceMap(paramProps);
end

% LocalWords:  extmask
