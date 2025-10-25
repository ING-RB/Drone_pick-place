classdef Test < matlab.unittest.TestSuite & matlab.mixin.CustomDisplay
    % Test - Specification of a single Test method
    %
    %   The matlab.unittest.Test class holds the information needed for the
    %   TestRunner to be able to run a single Test method of a TestCase
    %   class. A scalar Test instance is the fundamental element contained
    %   in TestSuite arrays. A simple array of Test instances is a commonly
    %   used form of a TestSuite.
    %
    %   Test properties:
    %       Name               - Name of the Test element
    %       ProcedureName      - Name of the test procedure in the test
    %       TestClass          - Test class name
    %       BaseFolder         - Name of the folder that holds the file that
    %                            defines this Test element
    %       Parameterization   - Parameters for this Test element
    %       SharedTestFixtures - Fixtures for this Test element
    %       Tags               - Tags for this Test element
    %
    %
    %   Examples:
    %
    %       import matlab.unittest.TestSuite;
    %
    %       % Create a suite of Test instances comprised of all test methods in
    %       % the class.
    %       suite = TestSuite.fromClass(?SomeTestClass);
    %       result = run(suite)
    %
    %       % Create and run a single test method
    %       run(TestSuite.fromMethod(?SomeTestClass, 'testMethod'))
    %
    %   See also: TestSuite, TestRunner
    
    
    % Copyright 2012-2023 The MathWorks, Inc.
    
    properties(Dependent, SetAccess=immutable)
        % Name - Name of the Test element
        %
        %   The Name property is a string which identifies the Test method to be
        %   run for the instance. It includes the name of the test method or function
        %   the instance applies to as well as its parent.
        Name
        
        % ProcedureName - Name of the test procedure in the test
        %
        %   The ProcedureName property describes the name of the test procedure
        %   that will be run for this test. For example, in a class based test
        %   the ProcedureName is the name of the test method, in a function based
        %   test it corresponds to the name of the local function containing the
        %   test, and in a script based test it refers to the applicable test
        %   section.
        ProcedureName
    end
    
    properties (Dependent, SetAccess=private)
        % TestClass - Test class name
        %
        %   The TestClass is the name of the class for the TestCase
        %   instance. If a Test element is not a class-based test, then
        %   TestClass is an empty string.
        TestClass
    end
    
    properties(Dependent, SetAccess={?matlab.unittest.internal.TestRunStrategy})
        % BaseFolder - Name of the folder that holds the test content
        %
        %   The BaseFolder property is a string that represents the name of the
        %   folder that holds the class, function, or script that defines the test
        %   content. For test files in namespaces, the BaseFolder is the parent of
        %   the top-level namespace folder.
        BaseFolder
    end
    
    properties (Dependent, SetAccess=private)
        % Parameterization - Parameters for this Test element
        %
        %   The Parameterization property holds a row vector of
        %   matlab.unittest.parameters.Parameter objects that represent all the
        %   parameterized data needed for the TestRunner to run the Test method,
        %   including any parameterized TestClassSetup and TestMethodSetup methods.
        Parameterization
        
        % SharedTestFixtures - Fixtures for this Test element
        %
        %   The SharedTestFixtures property holds a row vector of
        %   matlab.unittest.fixture.Fixture objects that represent all of the
        %   fixtures required for the Test element.
        SharedTestFixtures
        
        % Tags - Tags for this Test element
        %
        %   The Tags property holds a cell array of strings the Test
        %   element is tagged with.
        Tags
    end
    
    properties(Hidden, Dependent, SetAccess=immutable)
        % TestParentName - Name of the test parent
        %
        %   The name of the test class corresponding to the TestCase
        %   instance to be created for this Test. The name describes the
        %   file which contains the test.
        TestParentName
        
        % SharedTestClassName - Name of the shared test class
        %
        %   The name of the test class that groups tests that share the
        %   same set of class setup parameters
        SharedTestClassName
        
        % TestMethodName - Test method name
        %
        %   The name of the method which describes the test method which will be
        %   run for this Test. The method name must describe a method whose Test
        %   attribute is true.
        %
        TestMethodName
        
        % TestName - Alias for the ProcedureName property
        %
        %   TestName is a temporary alias for the ProcedureName property.
        TestName
        
        % Superclasses - List of superclasses of the TestClass
        %
        %  The names of superclasses of the TestCase instance.
        Superclasses
        
        % NumInputParameters - Number of input parameters
        %
        % The number of parameters passed into the test method
        NumInputParameters

        % Filename - Name of file that defines the test
        %
        %   For class-based tests, the filename always refers to the main test
        %   class file. Methods defined in other files (e.g., superclasses, @
        %   folders, etc. are not considered).
        Filename
    end
    
    properties(Access=private)
        TestCaseProvider
        ExternalFixtures(1,:) matlab.unittest.fixtures.Fixture = matlab.unittest.fixtures.EmptyFixture.empty();
    end
    
    properties (Hidden, SetAccess=?matlab.unittest.TestSuite)
        InternalHiddenFixtures = matlab.unittest.fixtures.EmptyFixture.empty();
    end
    
    properties (Hidden, SetAccess=private)
        ClassBoundaryMarker
        InternalSharedTestFixtures        
    end

    properties (Hidden, Dependent, SetAccess = private)
        LegacyName
    end
    
    methods(Hidden, Static)
        function test = fromName(name, modifier, parameters)
            import matlab.unittest.internal.NameParser;
            import matlab.unittest.internal.TestSuiteFactory;
            import matlab.unittest.internal.services.namingconvention.AllowsAnythingNamingConventionService;
            
            % Parse the Name string into its parent name, test name, and
            % parameter information
            parser = NameParser(name);
            parser.parse;
            if ~parser.Valid
                error(message('MATLAB:unittest:TestSuite:InvalidName', name));
            end
            
            allParameters = [parser.ClassSetupParameters, ...
                parser.MethodSetupParameters, parser.TestMethodParameters];
            duplicate = findFirstDuplicate({allParameters.Property});
            if ~isempty(duplicate)
                error(message("MATLAB:unittest:TestSuite:DuplicateParameter", duplicate{1}));
            end
            
            factory = TestSuiteFactory.fromParentName(parser.ParentName, ...
                AllowsAnythingNamingConventionService);
            test = factory.createSuiteFromName(parser, parameters);
            test = modifier.apply(test);
        end
        
        function test = fromMethod(testClass, method, modifier, externalParameters)
            import matlab.unittest.Test;
            import matlab.unittest.internal.TestCaseClassProvider;
            import matlab.unittest.internal.mustBeTextScalar;
            import matlab.unittest.internal.mustContainCharacters;
            import matlab.unittest.internal.convertMethodNameToMetaMethod;
            
            [status, msg] = validateClass(testClass);
            if ~status
                throwAsCaller(MException(msg));
            end
            
            validateattributes(method, ...
                {'matlab.unittest.meta.method','char','string'},{'nonempty'},'','method');            
          
            if isa(method,'matlab.unittest.meta.method')
                if ~all([method.Test])
                    error(message('MATLAB:unittest:Test:TestMethodAttributeNeeded'));
                end
            else
                mustBeTextScalar(method,'method');
                mustContainCharacters(method,'method');
                method = char(method);
                [status, msg, method] = convertMethodNameToMetaMethod(testClass, method);
                if ~status
                    throwAsCaller(MException(msg));
                end
            end

            % Optimization: early return if the modifier rejects TestClass invariant attributes.
            if modifierRejectsTestClassInvariantAttributes(testClass, modifier)
                test = Test.empty(1,0);
                return;
            end
            
            provider = TestCaseClassProvider.withAllParameterizations(testClass, method, externalParameters);
            test = Test.fromProvider(provider);
            test = modifier.apply(test);
        end
        
        function test = fromClass(testClass, modifier, externalParameters)
            import matlab.unittest.Test;
            import matlab.unittest.internal.TestCaseClassProvider;
            
            [status, msg] = validateClass(testClass);
            if ~status
                throwAsCaller(MException(msg));
            end
            
            % Optimization: early return if the modifier rejects TestClass invariant attributes.
            if modifierRejectsTestClassInvariantAttributes(testClass, modifier)
                test = Test.empty(1,0);
                return;
            end
            
            testMethods = rot90(testClass.MethodList.findobj('Test',true), 3);
            provider = TestCaseClassProvider.withAllParameterizations(testClass, testMethods, externalParameters);
            test = Test.fromProvider(provider);
            test = modifier.apply(test);
        end
        
        function test = fromTestCase(testCase, testMethods)
            import matlab.unittest.Test;
            import matlab.unittest.internal.TestCaseInstanceProvider;
            import matlab.unittest.internal.mustBeTextScalar;
            import matlab.unittest.internal.mustContainCharacters;
            import matlab.unittest.internal.convertMethodNameToMetaMethod;
            import matlab.unittest.internal.selectors.getSuiteModifier;
            
            testClass = metaclass(testCase);
            
            if nargin > 1
                validateattributes(testMethods, ...
                    {'matlab.unittest.meta.method','char','string'},{'nonempty'},'','testMethod');
                
                if isa(testMethods,'matlab.unittest.meta.method')
                    if ~all([testMethods.Test])
                        error(message('MATLAB:unittest:Test:TestMethodAttributeNeeded'));
                    end
                else
                    mustBeTextScalar(testMethods,'testMethod');
                    mustContainCharacters(testMethods,'testMethod');
                    testMethods=char(testMethods);
                    [status, msg, testMethods] = convertMethodNameToMetaMethod(testClass, testMethods);
                    if ~status
                        throwAsCaller(MException(msg));
                    end
                end
            else
                testMethods = rot90(testClass.MethodList.findobj('Test',true), 3);
            end
            
            provider = TestCaseInstanceProvider(testCase, testMethods);
            test = Test.fromProvider(provider);
            test = getSuiteModifier().apply(test);
        end
        
        function test = fromFunctions(fcns, testType, varargin)
            import matlab.unittest.Test;
            import matlab.unittest.internal.FunctionTestCaseProvider;
            
            test = Test.fromProvider(FunctionTestCaseProvider(fcns, testType, varargin{:}));
        end
        
        function test = fromProvider(provider)
            test = repmat(matlab.unittest.Test, size(provider));
            for idx = 1:numel(provider)
                test(idx) = matlab.unittest.Test(provider(idx));
            end
            test = addClassBoundaryMarker(test);
        end
    end
    
    methods(Access=private)
        function test = Test(testCaseProvider)
            if nargin > 0
                test.TestCaseProvider = testCaseProvider;
            end
        end
    end
    
    methods
        function name = get.Name(test)
            import matlab.unittest.internal.getTestName
            name = getTestName(test.TestParentName, test.ProcedureName, test.Parameterization);
        end

        function name = get.LegacyName(test)
            import matlab.unittest.internal.getLegacyTestName
            name = getLegacyTestName(test.TestParentName, test.ProcedureName, test.Parameterization);
        end
        
        function testClass = get.TestClass(test)
            testClass = test.TestCaseProvider.TestClass;
        end
        
        function testMethod = get.TestParentName(test)
            testMethod = char(test.TestCaseProvider.TestParentName);
        end
        
        function sharedTestClassName = get.SharedTestClassName(test)
            import matlab.unittest.internal.getParameterNameString;
            
            classSetupParams = test.Parameterization.filterByType;
            classSetupParamsStr = getParameterNameString(classSetupParams, '[', ']');
            sharedTestClassName = [test.TestParentName, classSetupParamsStr];
        end
        
        function testMethodName = get.TestMethodName(test)
            testMethodName = test.TestCaseProvider.TestMethodName;
        end
        
        function testMethod = get.ProcedureName(test)
            testMethod = test.TestCaseProvider.TestName;
        end
        
        function testMethod = get.TestName(test)
            testMethod = test.ProcedureName;
        end
        
        function test = set.BaseFolder(test,folder)         
            [~, pfIdx] = findFixture(test.InternalHiddenFixtures, ...
                'matlab.unittest.internal.fixtures.HiddenPathFixture');
            
            [~,cffIdx] = findFixture(test.InternalHiddenFixtures, ...
                'matlab.unittest.internal.fixtures.HiddenCurrentFolderFixture');
            
            if ~isempty([pfIdx,cffIdx])
                test.InternalHiddenFixtures([pfIdx,cffIdx]) = [];                
                folder = matlab.unittest.internal.folderResolver(folder);
                test = test.addInternalPathAndCurrentFolderFixtures(folder);
            end
        end
        
        function folder = get.BaseFolder(test)
            % If a PathFixture is installed, its folder is the
            % BaseFolder
            
            pathFixture = findFixture(test.InternalSharedTestFixtures, ...
                'matlab.unittest.fixtures.PathFixture');
            
            if ~isempty(pathFixture)
                folder = pathFixture.Folder;
                return;
            end
            
            folder = char(test.TestCaseProvider.getBaseFolder);
        end
        
        function parameterization = get.Parameterization(test)
            parameterization = test.TestCaseProvider.Parameterization;
        end
        
        function sharedTestFixtures = get.SharedTestFixtures(test)
            externalFixtures = test.ExternalFixtures;
            providerFixtures = test.TestCaseProvider.SharedTestFixtures;
            providerFixtures = providerFixtures(:).';
            sharedTestFixtures = [externalFixtures, providerFixtures];
        end
        
        function tags = get.Tags(test)
            tags = test.TestCaseProvider.Tags;
        end
        
        function internalSharedTestFixtures = get.InternalSharedTestFixtures(test)
            providerFixtures = test.TestCaseProvider.InternalSharedTestFixtures;
            hiddenFixtures   = test.InternalHiddenFixtures;
            internalSharedTestFixtures = [providerFixtures, hiddenFixtures];
        end
        
        function superClassList = get.Superclasses(test)
            superClassList = test.TestCaseProvider.getSuperclasses;
        end
        
        function numInputParameters = get.NumInputParameters(test)
            numInputParameters = test.TestCaseProvider.NumInputParameters;
        end

        function filename = get.Filename(test)
            filename = fullfile(test.BaseFolder, test.TestCaseProvider.RelativeFilename);
        end
    end
    
    methods(Hidden)
        function testCase = provideClassTestCase(test)
            testCase = test.TestCaseProvider.provideClassTestCase;
        end
        
        function testCase = createTestCaseFromClassPrototype(test, classTestCase)
            testCase = test.TestCaseProvider.createTestCaseFromClassPrototype(classTestCase);
        end
        
        function idx = matchProviders(suite1, suite2)
            getProviderClass = @(a) class(a.TestCaseProvider);
            provider1Classes = arrayfun(getProviderClass, suite1, 'UniformOutput', false);
            provider2Classes = arrayfun(getProviderClass, suite2, 'UniformOutput', false);
            
            [~, idx] = ismember(provider2Classes, provider1Classes);
        end
        
        function mask = identifyProviders(suite, providerClass)
            mask = arrayfun(@(test)isa(test.TestCaseProvider, providerClass), suite);
        end
        
        function test = addExternalFixtures(test, fixtures)
            for idx = 1:numel(test)
                test(idx).ExternalFixtures = [fixtures, test(idx).ExternalFixtures];
            end
        end
        
        function test = addInternalPathAndCurrentFolderFixtures(test, folder)
            import matlab.unittest.internal.fixtures.HiddenPathFixture;
            import matlab.unittest.internal.fixtures.HiddenCurrentFolderFixture;
            
            % Add a PathFixture and CurrentFolderFixture to ensure that this folder
            % is placed on the path at runtime and that the runner CDs to it.
            hiddenFixtures = [HiddenPathFixture(folder), HiddenCurrentFolderFixture(folder)];
            [test.InternalHiddenFixtures] = deal(hiddenFixtures);
        end
        
        function bool = runsWithoutPathAndCurrentFolderManipulation(test)
            [~, idx1] = findFixture([test.InternalHiddenFixtures], ...
                "matlab.unittest.internal.fixtures.HiddenPathFixture");
            [~, idx2] = findFixture([test.InternalHiddenFixtures], ...
                "matlab.unittest.internal.fixtures.HiddenCurrentFolderFixture");
            bool = isempty(idx1) && isempty(idx2);
        end
        
        function bool = supportsThreadBasedPools(test)
            bool = true;
            for idx = 1:numel(test)
                if ~test(idx).TestCaseProvider.supportsThreadBasedPools
                    bool = false;
                    return;
                end
            end
        end
    end
    
    methods(Hidden, Access=protected)
        function footerStr = getFooter(suite)
            % getFooter - Override of the matlab.mixin.CustomDisplay hook method
            %   Displays a summary of the test suite.
            
            footerStr = string(getString(message("MATLAB:unittest:TestSuite:TestsInclude"))) + newline + ...
                indent(join(getFooterParts(suite, inputname(1)), ", ") + ".") + newline;
            footerStr = char(footerStr);
        end
    end
    
    
    methods (Hidden)
        function testStruct = saveobj(test)
            % R2019a
            testStruct.V7.TestCaseProvider       = test.TestCaseProvider;
            testStruct.V7.ExternalFixtures       = test.ExternalFixtures;
            testStruct.V7.InternalHiddenFixtures = test.InternalHiddenFixtures;
            testStruct.V7.ClassBoundaryMarker    = test.ClassBoundaryMarker;
        end
    end
    
    methods (Hidden, Static)
        function test = loadobj(testStruct)
            import matlab.unittest.internal.TestCaseClassProvider;
            
            % Construct a new Test and assign properties.
            test = matlab.unittest.Test;
            
            if isfield(testStruct, 'V7') % R2019a and later
                test.TestCaseProvider = testStruct.V7.TestCaseProvider;
                test.ExternalFixtures = testStruct.V7.ExternalFixtures;
                test.InternalHiddenFixtures = testStruct.V7.InternalHiddenFixtures;
                test.ClassBoundaryMarker = testStruct.V7.ClassBoundaryMarker;
            elseif isfield(testStruct, 'V6') % R2017a, R2017b, R2018a, R2018b
                test.TestCaseProvider = testStruct.V6.TestCaseProvider;
                test.InternalHiddenFixtures = testStruct.V6.InternalHiddenFixtures;
                test.ClassBoundaryMarker = testStruct.V6.ClassBoundaryMarker;
            end
        end
        
        function test = fromClassOverridingParameters(testClass, overriddenParameter)
            import matlab.unittest.Test;
            import matlab.unittest.internal.TestCaseClassProvider;
            import matlab.unittest.internal.selectors.getSuiteModifier;
            
            testMethods = rot90(testClass.MethodList.findobj('Test',true), 3);
            provider = TestCaseClassProvider.withAllParameterizations(testClass, testMethods, overriddenParameter);
            test = Test.fromProvider(provider);
            test = getSuiteModifier().apply(test);
        end
    end
end


function [status, msg] = validateClass(testClass)
status = false;

mcls = metaclass(testClass);

if isempty(mcls)
    msg = message("MATLAB:unittest:TestSuite:NonMetaclass");
    return;
end
if mcls <= ?matlab.unittest.TestCase
    msg = message('MATLAB:unittest:TestSuite:NonMetaClass');
    return;
end
if ~(mcls <= ?meta.class)
    msg = message('MATLAB:unittest:TestSuite:NonMetaclass');
    return;
end
if isempty(testClass)
    msg = message('MATLAB:unittest:TestSuite:InvalidClass');
    return;
end
if ~(mcls <= ?matlab.unittest.meta.class)
    msg = message('MATLAB:unittest:TestSuite:NonTestCase',testClass.Name);
    return;
end
if ~isscalar(testClass)
    msg = message('MATLAB:unittest:TestSuite:NonscalarClass');
    return;
end
if testClass.Abstract
    msg = message('MATLAB:unittest:TestSuite:AbstractTestCase', testClass.Name);
    return;
end

status = true;
msg = message.empty;
end

function bool = modifierRejectsTestClassInvariantAttributes(testClass, modifier)
import matlab.unittest.internal.getBaseFolderFromParentName;
import matlab.unittest.internal.selectors.AttributeSet
import matlab.unittest.internal.selectors.BaseFolderAttribute;
import matlab.unittest.internal.selectors.SuperclassAttribute;
import matlab.unittest.internal.getAllSuperclassNamesInHierarchy;


selector = modifier.getRejector;

% Filter on base folder
if selector.uses(?matlab.unittest.internal.selectors.BaseFolderAttribute)
    folderAttribute = BaseFolderAttribute(getBaseFolderFromParentName(testClass.Name));
    folderAttributeSet = AttributeSet(folderAttribute, 1);

    % Check for possible early return if the selector rejects the folder
    if selector.reject(folderAttributeSet)
        bool = true;
        return;
    end
end

% Filter on superclass
if selector.uses(?matlab.unittest.internal.selectors.SuperclassAttribute)
    superclassAttribute = SuperclassAttribute({getAllSuperclassNamesInHierarchy(testClass)});
    superclassAttributeSet = AttributeSet(superclassAttribute, 1);

    % Check for possible early return if the selector rejects the superclass
    if selector.reject(superclassAttributeSet)
        bool = true;
        return;
    end
end

bool = false;
end

function [fixture, fixtureIdx] = findFixture(fixtureArray, className)
fixtureIdx = find(arrayfun(@(f)isa(f,className), fixtureArray), 1, 'first');
fixture = fixtureArray(fixtureIdx);
end

function suite = addClassBoundaryMarker(suite)
if ~isempty(suite)
    [suite.ClassBoundaryMarker] = deal(matlab.unittest.internal.ClassBoundaryMarker);
end
end

function duplicate = findFirstDuplicate(strs)
[~, uniqueIdx] = unique(strs);
mask = true(1,numel(strs));
mask(uniqueIdx) = false;
duplicate = strs(find(mask,1));
end

function footers = getFooterParts(suite, variableName)
import matlab.automation.internal.services.ServiceLocator;
import matlab.unittest.internal.services.ServiceFactory;
import matlab.unittest.internal.services.testfooter.TestFooterLiaison;
import matlab.unittest.internal.services.testfooter.TestFooterService;
import matlab.unittest.internal.services.testfooter.ParameterizationFooterService;
import matlab.unittest.internal.services.testfooter.SharedTestFixturesFooterService;
import matlab.unittest.internal.services.testfooter.TestTagsFooterService;

namespace = "matlab.unittest.internal.services.testfooter.located";
locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
cls = ?matlab.unittest.internal.services.testfooter.TestFooterService;
locatedServiceClasses = locator.locate(cls);
locatedServices = ServiceFactory.create(locatedServiceClasses);
services = [ParameterizationFooterService; SharedTestFixturesFooterService; TestTagsFooterService; locatedServices];
liaison = TestFooterLiaison(suite, variableName);
fulfill(services, liaison);
footers = liaison.Footers;
end

% LocalWords:  c'tor Teardownable isscript namingconvention Parameterizations cff Rejector
% LocalWords:  CDs isstring mcls unittest strjoin extmask strsplit strs testfooter cls
