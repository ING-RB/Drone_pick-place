classdef (Hidden) TabCompletion
    %
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    methods (Static)
        function names = nameChoicesFromPartialMatch(test)
            import matlab.unittest.internal.TabCompletion;
            
            parentName = regexp(test, '^[^/\[]*', 'match', 'once');
            names = TabCompletion.nameChoices(parentName);
        end
        
        function names = nameChoices(test)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossible(test);
            names = TabCompletion.getUniqueSuiteParentProcedureNames(suite);
        end
        
        function names = nameChoicesForName(test)
            import matlab.unittest.internal.TabCompletion;
            
            parentName = regexp(test, '^[^/\[]*', 'match', 'once');
            suite = createSuiteIfPossibleFromName(parentName);
            names = {suite.Name};
        end
        
        function names = nameChoicesForFile(file)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFile(file);
            names = TabCompletion.getUniqueSuiteParentProcedureNames(suite);
        end
        
        function names = nameChoicesForFolder(folder)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFolder(folder);
            names = TabCompletion.getUniqueSuiteParentProcedureNames(suite);
        end
        
        function names = nameChoicesForNamespace(namespace)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForNamespace(namespace);
            names = TabCompletion.getUniqueSuiteParentProcedureNames(suite);
        end
        
        function names = nameChoicesForClass(testClass)
            suite = createSuiteIfPossibleForClass(testClass);
            names = {suite.Name};
        end
        
        function names = nameChoicesForMethod(testClass, testMethod)
            suite = createSuiteIfPossibleForMethod(testClass, testMethod);
            names = {suite.Name};
        end
        
        function parameterNames = parameterNameChoices(test)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossible(test);
            parameterNames = TabCompletion.getSuiteParameterNames(suite);
        end
        
        function parameterNames = parameterNameChoicesForFile(file)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFile(file);
            parameterNames = TabCompletion.getSuiteParameterNames(suite);
        end
        
        function parameterNames = parameterNameChoicesForNamespace(namespace)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForNamespace(namespace);
            parameterNames = TabCompletion.getSuiteParameterNames(suite);
        end
        
        function names = parameterNameChoicesForClass(testClass)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForClass(testClass);
            names = TabCompletion.getSuiteParameterNames(suite);
        end
        
        function names = parameterNameChoicesForMethod(testClass, testMethod)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForMethod(testClass, testMethod);
            names = TabCompletion.getSuiteParameterNames(suite);
        end
        
        function parameterNames = parameterNameChoicesForFolder(folder)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFolder(folder);
            parameterNames = TabCompletion.getSuiteParameterNames(suite);
        end
        
        function parameterProperties = parameterPropertyChoices(test)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossible(test);
            parameterProperties = TabCompletion.getSuiteParameterProperties(suite);
        end
        
        function parameterNames = parameterPropertyChoicesForNamespace(namespace)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForNamespace(namespace);
            parameterNames = TabCompletion.getSuiteParameterProperties(suite);
        end
        
        function names = parameterPropertyChoicesForClass(testClass)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForClass(testClass);
            names = TabCompletion.getSuiteParameterProperties(suite);
        end
        
        function names = parameterPropertyChoicesForMethod(testClass, testMethod)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForMethod(testClass, testMethod);
            names = TabCompletion.getSuiteParameterProperties(suite);
        end
        
        function parameterProperties = parameterPropertyChoicesForFile(file)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFile(file);
            parameterProperties = TabCompletion.getSuiteParameterProperties(suite);
        end
        
        function parameterProperties = parameterPropertyChoicesForFolder(folder)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFolder(folder);
            parameterProperties = TabCompletion.getSuiteParameterProperties(suite);
        end
        
        function tags = tagChoices(test)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossible(test);
            tags = TabCompletion.getUniqueTagsFromSuite(suite);
        end
        
        function tags = tagChoicesForNamespace(namespace)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForNamespace(namespace);
            tags = TabCompletion.getUniqueTagsFromSuite(suite);
        end
        
        function names = tagChoicesForClass(testClass)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForClass(testClass);
            names = TabCompletion.getUniqueTagsFromSuite(suite);
        end
        
        function names = tagChoicesForMethod(testClass, testMethod)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForMethod(testClass, testMethod);
            names = TabCompletion.getUniqueTagsFromSuite(suite);
        end
        
        function tags = tagChoicesForFile(file)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFile(file);
            tags = TabCompletion.getUniqueTagsFromSuite(suite);
        end
        
        function tags = tagChoicesForFolder(folder)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFolder(folder);
            tags = TabCompletion.getUniqueTagsFromSuite(suite);
        end
        
        function procedureNames = procedureNameChoices(test)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossible(test);
            procedureNames = TabCompletion.getUniqueProcedureNamesFromSuite(suite);
        end
        
        function procedureNames = procedureNameChoicesForFile(file)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFile(file);
            procedureNames = TabCompletion.getUniqueProcedureNamesFromSuite(suite);
        end
        
        function procedureNames = procedureNameChoicesForFolder(folder)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFolder(folder);
            procedureNames = TabCompletion.getUniqueProcedureNamesFromSuite(suite);
        end
        
        function procedureNames = procedureNameChoicesForNamespace(namespace)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForNamespace(namespace);
            procedureNames = TabCompletion.getUniqueProcedureNamesFromSuite(suite);
        end
        
        function names = procedureNameChoicesForClass(testClass)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForClass(testClass);
            names = TabCompletion.getUniqueProcedureNamesFromSuite(suite);
        end
        
        function names = procedureNameChoicesForMethod(testClass, testMethod)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForMethod(testClass, testMethod);
            names = TabCompletion.getUniqueProcedureNamesFromSuite(suite);
        end
        
        function verbosity = verbosityChoices
            verbosity = {'None', 'Terse', 'Concise', 'Detailed', 'Verbose'};
        end
        
        function superclassNames = superclassChoices(tests)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossible(tests);
            superclassNames = TabCompletion.getSuperClassNames(suite);
        end
        
        function superclassNames = superclassChoicesForNamespace(namespace)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForNamespace(namespace);
            superclassNames = TabCompletion.getSuperClassNames(suite);
        end
        
        function names = superclassChoicesForClass(testClass)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForClass(testClass);
            names = TabCompletion.getSuperClassNames(suite);
        end
        
        function names = superclassChoicesForMethod(testClass, testMethod)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForMethod(testClass, testMethod);
            names = TabCompletion.getSuperClassNames(suite);
        end
        
        function superclassNames = superclassChoicesForFile(file)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFile(file);
            superclassNames = TabCompletion.getSuperClassNames(suite);
        end
        
        function superclassNames = superclassChoicesForFolder(folder)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForFolder(folder);
            superclassNames = TabCompletion.getSuperClassNames(suite);
        end
        
        function methods = methodChoices(testClass)
            import matlab.unittest.internal.TabCompletion;
            
            suite = createSuiteIfPossibleForClass(testClass);
            methods = TabCompletion.getUniqueProcedureNamesFromSuite(suite);
        end
    end
    
    methods (Static, Access=protected)
        function parameterNames = getSuiteParameterNames(suite)
            import matlab.unittest.parameters.Parameter;
            
            parameters = [Parameter.empty, suite.Parameterization];
            parameterNames = unique({parameters.Name});
        end
        
        function parameterProperties = getSuiteParameterProperties(suite)
            import matlab.unittest.parameters.Parameter;
            
            parameters = [Parameter.empty, suite.Parameterization];
            parameterProperties = unique({parameters.Property});
        end
        
        function names = getUniqueSuiteParentProcedureNames(suite)
            suiteNames = {suite.Name};
            parentAndProcedureNames = cellstr(string({suite.TestParentName}) + "/" + {suite.ProcedureName});
            names = unique([suiteNames, parentAndProcedureNames]);
        end
        
        function tags = getUniqueTagsFromSuite(suite)
            tags = unique([cell.empty, suite.Tags]);
        end
        
        function procedureNames = getUniqueProcedureNamesFromSuite(suite)
            procedureNames = unique({suite.ProcedureName});
        end
        
        function superclassNames = getSuperClassNames(suite)
            superclassNames = unique(vertcat(cell.empty, suite.Superclasses));
            superclassNames(arrayfun(@isHidden,superclassNames)) = [];
            function bool = isHidden(className)
                cls = meta.class.fromName(className);
                bool = isempty(cls) || cls.Hidden;
            end
        end
    end
end

function suite = createSuiteIfPossible(tests)
suite = createSuiteIfPossibleSuppressingOutput(@()matlab.unittest.internal.createTestSuite(tests));
end

function suite = createSuiteIfPossibleForNamespace(namespace)
import matlab.unittest.TestSuite;
import matlab.unittest.internal.selectors.NeverFilterSelector
import matlab.unittest.parameters.Parameter

namespaceMetadata = meta.package.fromName(namespace);
suite = createSuiteIfPossibleSuppressingOutput(@()TestSuite.fromNamespaceCore_(namespaceMetadata, NeverFilterSelector, Parameter.empty, false));
end

function suite = createSuiteIfPossibleForClass(testClass)
import matlab.unittest.Test
import matlab.unittest.internal.selectors.NeverFilterSelector
import matlab.unittest.parameters.Parameter
suite = createSuiteIfPossibleSuppressingOutput(@()Test.fromClass(testClass, NeverFilterSelector, Parameter.empty));
end

function suite = createSuiteIfPossibleForMethod(testClass, testMethod)
import matlab.unittest.Test
import matlab.unittest.internal.selectors.NeverFilterSelector
import matlab.unittest.parameters.Parameter
suite = createSuiteIfPossibleSuppressingOutput(@()Test.fromMethod(testClass, testMethod, NeverFilterSelector, Parameter.empty));
end

function suite = createSuiteIfPossibleForFile(file)
import matlab.unittest.TestSuite;
import matlab.unittest.internal.selectors.NeverFilterSelector
import matlab.unittest.parameters.Parameter
suite = createSuiteIfPossibleSuppressingOutput(@()TestSuite.fromFileCore_(file, NeverFilterSelector, Parameter.empty));
end

function suite = createSuiteIfPossibleFromName(name)
import matlab.unittest.internal.TestSuiteFactory;
import matlab.unittest.internal.services.namingconvention.AllowsAnythingNamingConventionService;
import matlab.unittest.internal.selectors.NeverFilterSelector;

factory = TestSuiteFactory.fromParentName(name, AllowsAnythingNamingConventionService);
suite = createSuiteIfPossibleSuppressingOutput(@()factory.createSuiteFromParentName(NeverFilterSelector));
end

function suite = createSuiteIfPossibleForFolder(folder)
import matlab.unittest.TestSuite
import matlab.unittest.internal.selectors.NeverFilterSelector
import matlab.unittest.parameters.Parameter

fcn = @()matlab.unittest.internal.folderResolver(folder);
[~, exception, folderFullPath] = matlab.lang.internal.runWithCapture(fcn);
if ~isempty(exception)
    suite = matlab.unittest.Test.empty;
else
    suite = createSuiteIfPossibleSuppressingOutput(@()TestSuite.fromFolderCore_(folderFullPath, NeverFilterSelector, Parameter.empty, false));
end
end

function suite = createSuiteIfPossibleSuppressingOutput(fcn)
import matlab.lang.internal.runWithCapture;
import matlab.unittest.Test;

[~, exception, suite] = runWithCapture(fcn);
if ~isempty(exception)
    suite = Test.empty;
end
end

% LocalWords:  unittest testsuite namingconvention cls lang
