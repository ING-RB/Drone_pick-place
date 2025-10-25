classdef CodeCoveragePlugin < matlab.unittest.internal.plugins.CodeCoverageCollectionPlugin & ...
        matlab.unittest.internal.mixin.CoverageFormatMixin
    % CodeCoveragePlugin - Plugin to produce code coverage results.
    %
    %   The CodeCoveragePlugin can be added to the TestRunner to produce
    %   code coverage results for MATLAB source code. The results show
    %   which portions of the code were executed by the tests that were
    %   run. The coverage results are based on source code
    %   located in one or more files, folders or namespaces.
    %
    %   To produce valid coverage results, the source code being
    %   measured must be on the path throughout the entire test suite run.
    %
    %   CodeCoveragePlugin methods:
    %       forFolder    - Construct a CodeCoveragePlugin for reporting on one or more folders.
    %       forNamespace - Construct a CodeCoveragePlugin for reporting on one or more namespaces.
    %       forFile      - Construct a CodeCoveragePlugin for reporting on one or more files.
    %
    %   Example:
    %
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.CodeCoveragePlugin;
    %       import matlab.unittest.plugins.codecoverage.CoberturaFormat;
    %
    %       % Create a TestSuite array
    %       suite = TestSuite.fromClass(?myproj.MyTestClass);
    %       % Create a TestRunner with no plugins
    %       runner = TestRunner.withNoPlugins;
    %
    %       % Add a new plugin to the TestRunner
    %       runner.addPlugin(CodeCoveragePlugin.forFolder('C:\projects\myproj'));
    %
    %       % Run the suite. A report is opened upon completion of testing.
    %       result = runner.run(suite)
    %
    %       % Create a new TestRunner instance with no plugins
    %       runner = TestRunner.withNoPlugins;
    %
    %       % Add a new plugin to the TestRunner with a coverage format
    %       runner.addPlugin(CodeCoveragePlugin.forNamespace('myproj.sources',...
    %            'Producing',CoberturaFormat('CoverageResults.xml')));
    %
    %       % Run the suite. Code coverage results conforming to the Cobertura XML format are
    %       % generated in 'CoverageResults.xml' after testing.
    %       result = runner.run(suite)
    %
    %   See also: TestRunnerPlugin, profile
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties (Access=private)
        % Sources - a matlab.unittest.internal.coverage.Sources instance.
        % Stores information about the source.
        Sources
    end

    properties (SetAccess = immutable, Hidden)
        Filters
    end
    
    properties (Access = private, Transient)
        RuntimeData = uint64.empty;
        StaticData = struct.empty;
    end

    properties(SetAccess=immutable)
        % MetricLevel - Highest level of coverage metrics
        %
        %   The MetricLevel property specifies the coverage metrics
        %   included in the coverage report. This list shows the possible
        %   values for MetricLevel and the corresponding metrics in the
        %   code coverage report:
        %   "statement" (default value) — Statement and function coverage
        %   "decision" — Statement, function, and decision coverage
        %   "condition" — Statement, function, decision, and condition coverage
        %   "mcdc" — Statement, function, decision, condition, and modified condition/decision coverage (MC/DC)
        MetricLevel= "statement";
    end
    
    methods (Static)
        function plugin = forFolder(folder, optionalArgs)
            % forFolder  - Construct a CodeCoveragePlugin for reporting on one or more folders.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forFolder(FOLDER)
            %   constructs a CodeCoveragePlugin and returns it as PLUGIN. The plugin
            %   reports on the source code residing inside FOLDER. FOLDER is the
            %   absolute or relative path to one or more folders, specified as a
            %   character vector, string array, or cell array of character
            %   vectors.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forFolder(FOLDER, 'IncludingSubfolders',true)
            %   constructs a CodeCoveragePlugin and returns it as PLUGIN. The plugin
            %   reports on the source code residing inside FOLDER and all its
            %   subfolders. FOLDER is the absolute or relative path to one or more
            %   folders, specified as a character vector, string array, or cell
            %   array of character vectors.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forFolder(FOLDER,'Producing',FORMAT)
            %   constructs a CodeCoveragePlugin that generates code coverage results in
            %   the style specified by FORMAT. FORMAT is an instance of a class in the
            %   matlab.unittest.plugins.codecoverage namespace.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forFolder(FOLDER,'MetricLevel',LEVEL)
            %   specifies the coverage types to include in the code
            %   coverage results. By default, at the lowest reporting
            %   level, the plugin includes coverage metrics on statement
            %   and function coverage. As you specify a higher level using
            %   LEVEL (requires MATLAB Test (TM)), the plugin includes
            %   additional coverage types in the results. This list shows
            %   the possible values for LEVEL and the corresponding
            %   coverage types in the code coverage results:
            %   "statement" (default value) — Statement and function coverage  
            %   "decision" — Statement, function, and decision coverage 
            %   "condition" — Statement, function, decision, and condition coverage
            %   "mcdc" — Statement, function, decision, condition, and modified condition/decision coverage (MC/DC)
            %
            %   Example:
            %       import matlab.unittest.plugins.CodeCoveragePlugin;
            %       plugin = CodeCoveragePlugin.forFolder('C:\projects\myproj');
            %
            %   See also: forNamespace, forFile
            
            arguments
                folder {validateFolder}
                optionalArgs.IncludingSubfolders {validateIncludeSub};
                optionalArgs.IncludeSubfolders {validateIncludeSub}
                optionalArgs.Producing (1,:) matlab.unittest.plugins.codecoverage.CoverageFormat {mustBeNonempty} = matlab.unittest.plugins.codecoverage.CoverageReport
                optionalArgs.MetricLevel {matlab.unittest.internal.mustBeTextScalar} = "statement";
                optionalArgs.Filter {matlab.unittest.internal.mustBeTextScalarOrTextArray} = string.empty;
            end

            import matlab.unittest.internal.coverage.folderParser;
            import matlab.unittest.internal.resolveAliasedLogicalParameters;

            metricLevel = lower(optionalArgs.MetricLevel);
            validateMetricLevel(metricLevel);
            justificationArray = validateFilterFile(optionalArgs.Filter, metricLevel);


            includeSubFolderBool = resolveAliasedLogicalParameters(optionalArgs, ["IncludingSubfolders","IncludeSubfolders"]);
            folders = cellstr(folder);
            folders = reshape(folders,1,[]);
            foldersObj  = folderParser(folders, includeSubFolderBool);
            format = optionalArgs.Producing;
            plugin = matlab.unittest.plugins.CodeCoveragePlugin(foldersObj, metricLevel,'Producing',format,'Filters',justificationArray);
        end
        
        function plugin = forNamespace(namespace, optionalArgs)
            % forNamespace - Construct a CodeCoveragePlugin for reporting on one or more namespaces.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forNamespace(NAMESPACE)
            %   constructs a CodeCoveragePlugin and returns it as PLUGIN. The plugin
            %   reports on the source code that makes up NAMESPACE. NAMESPACE is a
            %   character vector, string array, or cell array of character
            %   vectors containing the name of one or more namespaces.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forNamespace(NAMESPACE, 'IncludingInnerNamespaces',true)
            %   constructs a CodeCoveragePlugin and returns it as PLUGIN. The plugin
            %   reports on the source code that makes up NAMESPACE and all its
            %   inner namespaces. NAMESPACE is a character vector, string array, or cell
            %   array of character vectors containing the name of one or more namespaces.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forNamespace(NAMESPACE,'Producing',FORMAT)
            %   constructs a CodeCoveragePlugin that generates code coverage results in
            %   the style specified by FORMAT. FORMAT is an instance of a class in the
            %   matlab.unittest.plugins.codecoverage namespace.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forNamespace(NAMESPACE,'MetricLevel',LEVEL)
            %   specifies the coverage types to include in the code
            %   coverage results. By default, at the lowest reporting
            %   level, the plugin includes coverage metrics on statement
            %   and function coverage. As you specify a higher level using
            %   LEVEL (requires MATLAB Test (TM)), the plugin includes
            %   additional coverage types in the results. This list shows
            %   the possible values for LEVEL and the corresponding
            %   coverage types in the code coverage results:
            %   "statement" (default value) — Statement and function coverage  
            %   "decision" — Statement, function, and decision coverage 
            %   "condition" — Statement, function, decision, and condition coverage
            %   "mcdc" — Statement, function, decision, condition, and modified condition/decision coverage (MC/DC)
            %
            %   Example:
            %       import matlab.unittest.plugins.CodeCoveragePlugin;
            %       plugin = CodeCoveragePlugin.forNamespace('myproject.controller');
            %
            %   See also: forFolder, forFile

            arguments
                namespace {validateNamespace}
                optionalArgs.IncludingInnerNamespaces {validateIncludeSub};
                optionalArgs.IncludeInnerNamespaces {validateIncludeSub};
                optionalArgs.IncludingSubpackages {validateIncludeSub};
                optionalArgs.IncludeSubpackages {validateIncludeSub};
                optionalArgs.Producing (1,:) matlab.unittest.plugins.codecoverage.CoverageFormat {mustBeNonempty} = matlab.unittest.plugins.codecoverage.CoverageReport
                optionalArgs.MetricLevel {matlab.unittest.internal.mustBeTextScalar} = "statement";
                optionalArgs.Filter {matlab.unittest.internal.mustBeTextScalarOrTextArray} = string.empty;
            end

            import matlab.unittest.internal.coverage.Folder;
            import matlab.unittest.internal.coverage.addClassAndPrivateSubFolders;
            import matlab.unittest.internal.resolveAliasedLogicalParameters;

            metricLevel = lower(optionalArgs.MetricLevel);
            validateMetricLevel(metricLevel);
            justificationArray = validateFilterFile(optionalArgs.Filter, metricLevel);

            includeInnerNamespaces = resolveAliasedLogicalParameters(optionalArgs, ...
                ["IncludingInnerNamespaces", "IncludeInnerNamespaces", "IncludingSubpackages", "IncludeSubpackages"]);
            namespaces = cellstr(namespace);
            if includeInnerNamespaces
                namespaces = findAllInnerNamespaces(namespaces);
            end
            
            % Build up the list of all the folders that define all the namespaces.
            folders = cell(1, numel(namespaces));
            for idx = 1:numel(namespaces)
                folderName = ['+', strrep(namespaces{idx}, '.', [filesep, '+'])];
                info = what(folderName);
                folders{idx} = {info.path};
            end
            
            format = optionalArgs.Producing;
            folders = addClassAndPrivateSubFolders([folders{:}]);
            foldersObj = Folder(folders);
            plugin = matlab.unittest.plugins.CodeCoveragePlugin(foldersObj,metricLevel,'Producing',format,'Filters',justificationArray);
        end
        
        function plugin = forFile(file,optionalArgs)
            % forFile  - Construct a CodeCoveragePlugin for reporting on one or more files.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forFile(FILE)
            %   constructs a CodeCoveragePlugin and returns it as PLUGIN. The plugin
            %   reports the code coverage for FILE. FILE is the absolute or relative
            %   path to one or more .m, .mlx or .mlapp files, specified as a character
            %   vector, string array, or cell array of character vectors. 
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forFile(FILE,'Producing',FORMAT)
            %   constructs a CodeCoveragePlugin and generates code coverage results 
            %   in the style specified by FORMAT. FORMAT is an instance of 
            %   matlab.unittest.plugins.codecoverage.CoberturaFormat or 
            %   matlab.unittest.plugins.codecoverage.CoverageReport class.
            %
            %   PLUGIN = matlab.unittest.plugins.CodeCoveragePlugin.forFile(FILE,'MetricLevel',LEVEL) 
            %   specifies the coverage types to include in the code
            %   coverage results. By default, at the lowest reporting
            %   level, the plugin includes coverage metrics on statement
            %   and function coverage. As you specify a higher level using
            %   LEVEL (requires MATLAB Test (TM)), the plugin includes
            %   additional coverage types in the results. This list shows
            %   the possible values for LEVEL and the corresponding
            %   coverage types in the code coverage results:
            %   "statement" (default value) — Statement and function coverage  
            %   "decision" — Statement, function, and decision coverage 
            %   "condition" — Statement, function, decision, and condition coverage
            %   "mcdc" — Statement, function, decision, condition, and modified condition/decision coverage (MC/DC)
            %
            %   Example:
            %       import matlab.unittest.plugins.CodeCoveragePlugin;
            %       import matlab.unittest.plugins.codecoverage.CoberturaFormat;
            %
            %       plugin = CodeCoveragePlugin.forFile('C:\projects\foo.m');
            %
            %       plugin = CodeCoveragePlugin.forFile('C:\projects\bar.m',...
            %            'Producing',CoberturaFormat('CodeCoverageReport.xml'));
            %
            %   See also: forFolder, forNamespace
             arguments
                file {validateFile}
                optionalArgs.Producing (1,:) matlab.unittest.plugins.codecoverage.CoverageFormat {mustBeNonempty} = matlab.unittest.plugins.codecoverage.CoverageReport
                optionalArgs.MetricLevel {matlab.unittest.internal.mustBeTextScalar} = "statement";
                optionalArgs.Filter {matlab.unittest.internal.mustBeTextScalarOrTextArray} = string.empty;
            end
            import matlab.unittest.internal.coverage.File;
            import matlab.unittest.internal.fileResolver;       
            files = cellstr(file);
            files = cellfun(@fileResolver, files, 'UniformOutput',false);

            metricLevel = lower(optionalArgs.MetricLevel);
            validateMetricLevel(metricLevel);
            justificationArray = validateFilterFile(optionalArgs.Filter, metricLevel);
           
            format = optionalArgs.Producing;
            filesObj = File(files);
            plugin = matlab.unittest.plugins.CodeCoveragePlugin(filesObj,metricLevel,'Producing',format,'Filters',justificationArray);
        end
    end
    
    methods (Static,Hidden)
        function varargout = forPackage(varargin)
            % Undocumented alias; discouraged use.
            [varargout{1:nargout}] = matlab.unittest.plugins.CodeCoveragePlugin.forNamespace(varargin{:});
        end

        function plugin = forSource(source,optionalArgs)
             arguments
                source {validateSource}
                optionalArgs.Producing (1,:) matlab.unittest.plugins.codecoverage.CoverageFormat {mustBeNonempty} = matlab.unittest.plugins.codecoverage.CoverageReport
                optionalArgs.MetricLevel {matlab.unittest.internal.mustBeTextScalar} = "statement"
                optionalArgs.Filter {matlab.unittest.internal.mustBeTextScalarOrTextArray} = string.empty;
            end
            import matlab.unittest.internal.coverage.File;

            metricLevel = lower(optionalArgs.MetricLevel);
            validateMetricLevel(metricLevel);
            justificationArray = validateFilterFile(optionalArgs.Filter, metricLevel);
           
            validateSource(source);            
            format = optionalArgs.Producing;
            
            rawSourcesVec = reshape(string(source),1,[]);
            sources = cell(1,length(rawSourcesVec));
            
            for idx = 1:length(rawSourcesVec)
                sources{idx} = getFilesFromSource(rawSourcesVec(idx));                 
            end  
            
            coveredFiles = [string.empty, sources{:}];
            coveredFilesObj = File(unique(coveredFiles));
            plugin = matlab.unittest.plugins.CodeCoveragePlugin(coveredFilesObj,metricLevel,'Producing',format,'Filters',justificationArray);            
        end
    end
    
    methods (Access=private)
        function plugin = CodeCoveragePlugin(sources,metricLevel, additionalArgs)
            % Private constructor. Must use a static method to construct an instance.
             arguments
                sources
                metricLevel 
                additionalArgs.Producing
                additionalArgs.Filters
            end
            import matlab.unittest.internal.coverage.CodeCoverageCollector;
            import matlab.unittest.internal.coverage.NullCollector;

            sourceFileNames = arrayfun(@(x) x.getFiles, sources,'UniformOutput', false);
            sourceFileNames = unique([sourceFileNames{:}],'stable');
            if isempty(sourceFileNames)
                collector = NullCollector;
            else
                collector = CodeCoverageCollector(sourceFileNames,metricLevel);
            end
            
            locatedFilters = locateFiltersForSourcefilesInProject(sourceFileNames,metricLevel);

            plugin@matlab.unittest.internal.plugins.CodeCoverageCollectionPlugin(collector);
            plugin.MetricLevel = string(metricLevel);
            plugin.Sources = sources;
            plugin.Format = additionalArgs.Producing;
            plugin.Filters = [additionalArgs.Filters, locatedFilters];
        end
        
        function beforeRun(plugin, ~)
            plugin.RuntimeData = uint64.empty;
            plugin.StaticData = struct.empty;
            for idx = 1 : numel(plugin.Format)
                plugin.Format(idx).validateReportCanBeCreated();
            end
        end        
        
        function afterRun(plugin, ~)
            if isempty(plugin.RuntimeData) || isempty(plugin.StaticData)
                coverageResult = matlab.coverage.Result.empty(0,1);
            else
                coverageResult = matlab.coverage.internal.getResults(plugin.StaticData, plugin.RuntimeData);
            end
            [coverageResult, unappliedFilters] = plugin.applyFiltersToResultBasedOnServicesLocated(coverageResult);
            for format = plugin.Format
                format.generateCoverageReport(plugin.Sources,coverageResult,...
                    "MATLAB:unittest:CodeCoveragePlugin:ReportSaved", unappliedFilters);
            end
        end
    end
   
    methods(Hidden, Access=protected)
        function runSession(plugin,pluginData) 
            plugin.beforeRun(pluginData);
            runSession@matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
            plugin.afterRun(pluginData);
        end

        function runTestSuite(plugin,pluginData)
            runTestSuite@matlab.unittest.internal.plugins.CodeCoverageCollectionPlugin(plugin,pluginData);
        end

        function reportFinalizedSuite(plugin, pluginData)
            % If the group didn't even start, substitute empty results
            defaultCovData = struct('StaticData', {struct.empty},'RuntimeData', {0});
            covStruct = plugin.retrieveFrom(pluginData.CommunicationBuffer, DefaultData = defaultCovData);

            if isempty(plugin.RuntimeData)
                plugin.RuntimeData = covStruct.RuntimeData;
            else
                plugin.RuntimeData = plugin.RuntimeData + covStruct.RuntimeData;
            end

            if isempty(plugin.StaticData)
                plugin.StaticData = covStruct.StaticData;
            end

            reportFinalizedSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
        end
    end

    methods (Access = private)
        function [filteredResultArray, unappliedFiltersArray] = applyFiltersToResultBasedOnServicesLocated(plugin,resultArray)
            import matlab.unittest.internal.coverage.locateCoverageReportMetricServices;
            import matlab.unittest.internal.services.coverage.CoverageApplyFilterToResultLiaison

            coverageMetricsServices = locateCoverageReportMetricServices;
            liaison = CoverageApplyFilterToResultLiaison(resultArray, plugin.Filters);
            fulfillApplyFilterDuty(coverageMetricsServices,liaison);

            filteredResultArray = liaison.Result;
            unappliedFiltersArray = liaison.UnappliedFilters;
        end
    end
end


function validateFolder(folders)
import matlab.unittest.internal.mustBeTextScalarOrTextArray;
import matlab.unittest.internal.mustContainCharacters;
mustBeTextScalarOrTextArray(folders,'folder');
mustContainCharacters(folders,'folder');
if isempty(folders)
    error(message('MATLAB:unittest:CodeCoveragePlugin:EmptyFolder'));
end
folders = reshape(string(folders),1,[]);
for folder = folders
    if ~isfolder(folder)
        error(message('MATLAB:unittest:CodeCoveragePlugin:FolderDoesNotExist',folder));
    end
end
end

function validateNamespace(namespaces)
import matlab.unittest.internal.mustBeTextScalarOrTextArray;
import matlab.unittest.internal.mustContainCharacters;
mustBeTextScalarOrTextArray(namespaces,'namespace');
mustContainCharacters(namespaces,'namespace');
if isempty(namespaces)
    error(message("MATLAB:unittest:CodeCoveragePlugin:EmptyNamespace"));
end
namespaces = reshape(string(namespaces),1,[]);
for aNamespace = namespaces
    if isempty(meta.package.fromName(aNamespace))
        error(message("MATLAB:unittest:CodeCoveragePlugin:NamespaceDoesNotExist",aNamespace));
    end
end
end

function validateFile(files)
import matlab.unittest.internal.mustBeTextScalarOrTextArray;
import matlab.unittest.internal.fileResolver;
mustBeTextScalarOrTextArray(files,'file');
mustBeNonempty(files);
for file = reshape(string(files),1,[])
    if ~endsWith(fileResolver(file),[".m",".mlx",".mlapp"])
        error(message('MATLAB:unittest:CodeCoveragePlugin:InvalidFileType',file));
    end
end
end

function validateIncludeSub(value)
validateattributes(value,{'logical'},{'scalar'})
end

function allNamespaces = findAllInnerNamespaces(namespaces)
allNamespaces = matlab.unittest.internal.findAllSubcontent(namespaces, @getInnerNamespaces);
end

function innerNamespaces = getInnerNamespaces(namespace)
namespaceInfo = meta.package.fromName(namespace);
innerNamespaces = {namespaceInfo.PackageList.Name};
end

function validateSource(sources)
import matlab.unittest.internal.mustBeTextScalarOrTextArray;
import matlab.unittest.internal.mustContainCharacters;
mustBeTextScalarOrTextArray(sources,'source');
mustContainCharacters(sources,'source');
if isempty(sources)
    error(message('MATLAB:unittest:CodeCoveragePlugin:EmptyFileOrFolder'));
end
end

function files = getFilesFromSource(source)
import matlab.unittest.internal.coverage.resolveFileToSourceFile;
import matlab.unittest.internal.coverage.resolveFolderToSourceFiles;

% file
if isfile(source)
    files = resolveFileToSourceFile(source);
    return
end   

% folder
if isfolder(source)
    files = resolveFolderToSourceFiles(source);
    return;
end

me = MException(message('MATLAB:unittest:CodeCoveragePlugin:InvalidSource',source));
throwAsCaller(me);
end

function validateMetricLevel(metricLevel)
import matlab.unittest.internal.services.coverage.CoverageMetricsLiaison
import matlab.unittest.internal.coverage.locateCoverageReportMetricServices;

coverageMetricsServices = locateCoverageReportMetricServices;
liaison = CoverageMetricsLiaison(metricLevel);
fulfill(coverageMetricsServices,liaison);
end

function justificationArray = validateFilterFile(filterFileArray, metricLevel)
import matlab.unittest.internal.mustBeTextScalarOrTextArray;
import matlab.unittest.internal.fileResolver;

if isempty(filterFileArray)
    justificationArray = [];
    return;
end

mustBeTextScalarOrTextArray(filterFileArray,'filter file');
filterFileArray = reshape(string(filterFileArray),1,[]);
for file = filterFileArray
    if ~endsWith(fileResolver(file),[".xml",".mat"]) % filter file should be a XML file or a .MAT file (supported until R2025b)
        error(message('MATLAB:unittest:CodeCoveragePlugin:InvalidFilterFileType',file));
    end
end

if strcmp(metricLevel, "statement")
    error(message('MATLAB:unittest:CodeCoveragePlugin:InvalidMetricToLoadFilterFile'));
end
justificationArray = getJustificationArrayFromFilterFiles(filterFileArray);
end

function justificationArray = locateFiltersForSourcefilesInProject(sourceFileStringArray, metricLevel)
if strcmp(metricLevel, "statment") || isempty(sourceFileStringArray)
    justificationArray = [];
    return;
end

[isInProjectMask,projectRootArray] = matlab.project.isFileInProject(sourceFileStringArray);
uniqueProjectRoots = unique(projectRootArray(isInProjectMask));

filterFilesForProjectSources = arrayfun(@(f) findCoverageFilterFilesInProjectRoot(f),uniqueProjectRoots,'UniformOutput', false);
filterFilesForProjectSources = filterFilesForProjectSources(~cellfun(@isempty,filterFilesForProjectSources));  % remove empty entries (i.e. projects that may not have filter files return empty filter files)
justificationArray = getJustificationArrayFromFilterFiles(string(filterFilesForProjectSources));
end

function filterfile = findCoverageFilterFilesInProjectRoot(projectRoot)
filterfile = string.empty;
if isfile(fullfile(projectRoot, "resources", "CodeCoverageFilter.xml"))
    filterfile = fullfile(projectRoot, "resources", "CodeCoverageFilter.xml");
elseif isfile(fullfile(projectRoot, "derived", "codecoverage", "Filter.mat")) % look for a MAT filter file if a XML filter file does not exist.
    filterfile = fullfile(projectRoot, "derived", "codecoverage", "Filter.mat");
end
end

function justificationArray = getJustificationArrayFromFilterFiles(filterFileArray)
import matlab.unittest.internal.coverage.locateCoverageReportMetricServices;
import matlab.unittest.internal.services.coverage.CoverageFilterLoadingLiaison

coverageMetricsServices = locateCoverageReportMetricServices;
liaison = CoverageFilterLoadingLiaison(filterFileArray);
fulfillFilterLoadingDuty(coverageMetricsServices,liaison);

justificationArray = liaison.JustificationArray;
end

% LocalWords:  myproj myproject noaddressbox Subfolders subfolders Subpackages codecoverage mcdc Vec
% LocalWords:  Subcontent subcontent varname CoberturaFormat Cobertura mlx mlapp lang
% LocalWords:  isfolder isfile
