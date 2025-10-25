classdef TestFileDerivatives < matlab.buildtool.io.FileCollection
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        Tests (1,:) matlab.buildtool.io.FileCollection
        IncludeSubfolders (1,1) logical
        RunOnlyImpactedTests (1,1) logical
        Tag (1,:) string
        Selector matlab.unittest.selectors.Selector {mustBeScalarOrEmpty} = matlab.unittest.selectors.NotSelector.empty()
        ExternalParameters (1,:) matlab.unittest.parameters.Parameter
    end

    properties (Transient, SetAccess=private, Dependent, Hidden)
        TestSuite (1,:) matlab.unittest.TestSuite
    end

    properties (Transient, SetAccess=private, Hidden)
        TestSuiteHolder (1,1) matlab.buildtool.internal.tasks.TestSuiteHolder
    end

    methods
        function collection = TestFileDerivatives(tests, options)
            arguments
                tests (1,:) matlab.buildtool.io.FileCollection = pwd()
                options.IncludeSubfolders (1,1) logical = true
                options.RunOnlyImpactedTests (1,1) logical = false
                options.Tag (1,:) string = string.empty(1,0)
                options.Selector matlab.unittest.selectors.Selector {mustBeScalarOrEmpty}
                options.ExternalParameters (1,:) matlab.unittest.parameters.Parameter = ...
                    matlab.unittest.parameters.Parameter.empty(1, 0);
            end

            collection.Tests = tests;
            collection.TestSuiteHolder = matlab.buildtool.internal.tasks.TestSuiteHolder();

            for prop = string(fieldnames(options))'
                collection.(prop) = options.(prop);
            end
        end

        function suite = get.TestSuite(collection)
            if isSuiteCreated(collection)
                suite = collection.TestSuiteHolder.TestSuite;
            else
                suite = constructTestSuite(collection);
                collection.TestSuiteHolder.TestSuite = suite;
            end
        end

        function collection = set.Tests(collection, value)
            collection.clearTestSuite();
            collection.Tests = value;
        end

        function collection = set.IncludeSubfolders(collection, value)
            collection.clearTestSuite();
            collection.IncludeSubfolders = value;
        end

        function collection = set.Tag(collection, value)
            collection.clearTestSuite();
            collection.Tag = value;            
        end

        function collection = set.Selector(collection, value)
            collection.clearTestSuite();
            collection.Selector = value;            
        end

        function collection = set.RunOnlyImpactedTests(collection, value)
            collection.clearTestSuite();
            collection.RunOnlyImpactedTests = value;
        end

        function collection = set.ExternalParameters(collection, value)
            collection.clearTestSuite();
            if matlab.internal.feature('MBTTestTaskExternalParameters') == 1
                collection.ExternalParameters = value;
            else
                collection.ExternalParameters = ...
                    matlab.unittest.parameters.Parameter.empty(1, 0);
            end
        end

        function collection = clearTestSuite(collection)
            collection.TestSuiteHolder.TestSuite = [];
        end

    end

    methods (Access = protected)
        function paths = elementPaths(collection)
            paths = collection.traceTestDerivatives();
        end
    end

    methods (Access=private)
        function tf = isSuiteCreated(collection)
            tf = isa(collection.TestSuiteHolder.TestSuite, "matlab.unittest.TestSuite");
        end

        function suite = constructTestSuite(collection)
            args.IncludeSubfolders = collection.IncludeSubfolders;
            if ~isempty(collection.Tag)
                args.Tag = collection.Tag;
            end
            args.InvalidFileFoundAction = "warn";

            suiteOptions = namedargs2cell(args);
            
            [tests, options] = matlab.unittest.internal.parseInformalTestSuiteArguments(...
                collection.Tests.paths(), suiteOptions{:});

            options.ExternalParameters = collection.ExternalParameters;
            
            suite = matlab.unittest.internal.createTestSuite(tests, options);

            if ~isempty(collection.Selector)
                suite = selectIf(suite, collection.Selector);
            end
            collection.TestSuiteHolder.TestSuite = suite;
        end

        function trackedTestFiles = traceTestDerivatives(collection)
            % Derive the dependencies of the test files. This analysis
            % currently includes test files and their superclasses. For
            % tests in class folders, the whole class folder is tracked.

            suite = collection.TestSuite;

            if isempty(suite)
                trackedTestFiles = string.empty();
                return
            end

            % Test files
            testFilenames = [suite.Filename];

            % Superclass files
            baseFolders = string(unique({suite.BaseFolder}));
            locatedSuperclasses = arrayfun(@(bf)locateSuperclasses(suite, bf), baseFolders, UniformOutput=false);
            locatedSuperclasses = [locatedSuperclasses{:}];
            superClassFilesMask = isfile(locatedSuperclasses);
            superClassFiles = locatedSuperclasses(superClassFilesMask);

            % Class folders
            testFolders = fileparts([suite.Filename]);
            [~, parentFolders] = fileparts(testFolders);
            classFoldersMask = startsWith(parentFolders, "@");
            classFolders = testFolders(classFoldersMask);

            trackedTestFiles = [testFilenames superClassFiles classFolders];
            trackedTestFiles = unique(trackedTestFiles);
        end
    end
end

function locatedSuperclasses = locateSuperclasses(suite, baseFolder)
arguments (Output)
    locatedSuperclasses (1,:) string
end
import matlab.buildtool.internal.whichFile
import matlab.unittest.selectors.HasBaseFolder

origPath = path();
restorePath = onCleanup(@()path(origPath));
addpath(baseFolder);

subsuite = suite.selectIf(HasBaseFolder(baseFolder));
superClasses = vertcat(subsuite.Superclasses);
locatedSuperclasses = arrayfun(@whichFile, superClasses);
end
