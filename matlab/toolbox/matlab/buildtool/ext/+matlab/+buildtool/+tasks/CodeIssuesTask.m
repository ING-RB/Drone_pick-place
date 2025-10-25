classdef CodeIssuesTask < matlab.buildtool.Task
    % CodeIssuesTask - Task to identify code issues
    %
    %   The matlab.buildtool.tasks.CodeIssuesTask class provides a task to
    %   identify MATLAB code issues.
    %
    %   CodeIssuesTask properties:
    %      SourceFiles       - Source files and folders to analyze
    %      IncludeSubfolders - Whether to include subfolders in analysis
    %      Configuration     - Code Analyzer configuration settings
    %      ErrorThreshold    - Maximum number of errors allowed
    %      WarningThreshold  - Maximum number of warnings allowed
    %
    %   CodeIssuesTask methods:
    %      CodeIssuesTask - Class constructor
    %
    %   Examples:
    %
    %      % Import the CodeIssuesTask class
    %      import matlab.buildtool.tasks.CodeIssuesTask
    %
    %      % Create a task to analyze the code in your current folder and its
    %      % subfolders by using the current active configuration settings
    %      task = CodeIssuesTask();
    %
    %      % Create a task to analyze the code in myfolder excluding its
    %      % subfolders
    %      task = CodeIssuesTask("myfolder",IncludeSubfolders=false);
    %
    %      % Create a task to analyze several source files and folders
    %      task = CodeIssuesTask(["myfile1.m" "subfolder/myfile2.m"]);
    %
    %      % Create a task to analyze code using the default code analyzer
    %      % configuration settings
    %      task = CodeIssuesTask("myfile1.m",Configuration="factory");
    %
    %      % Create a task to analyze code using a custom configuration file
    %      task = CodeIssuesTask("myfolder",Configuration="mySettings.txt");
    %
    %      % Create a task that fails if it identifies any warnings
    %      task = CodeIssuesTask("myfolder",WarningThreshold=0);
    %
    %      % Create a task to store the identified code issues in a MAT-file
    %      task = CodeIssuesTask("myfolder",Results="issues.mat");
    %
    %      % Create a task to export the identified code issues in SARIF format
    %      task = CodeIssuesTask("myfolder",Results="report.sarif");
    %
    %      % Create a build plan
    %      plan = buildplan();
    %
    %      % Add a "lint" task to the plan
    %      plan("lint") = CodeIssuesTask(plan.RootFolder);
    %
    %      % Run the "lint" task
    %      plan.run("lint");
    %
    %   See also:
    %      codeIssues
    %      codeAnalyzer
    %

    %  Copyright 2022-2024 The MathWorks, Inc.

    properties (TaskInput)
        % SourceFiles - Source files and folders to analyze
        %
        %   Source files and folders to analyze, specified as a string
        %   array, character vector, cell array of character vectors, or
        %   vector of matlab.buildtool.io.FileCollection objects, and
        %   returned as a row vector of matlab.buildtool.io.FileCollection
        %   objects.
        SourceFiles (1,:) matlab.buildtool.io.FileCollection

        % IncludeSubfolders - Whether to include subfolders in analysis
        %
        %   Whether to include subfolders in the analysis, specified as a
        %   numeric or logical 1 (true) or 0 (false). By default, the task
        %   includes subfolders in the analysis.
        IncludeSubfolders  (1,1) logical {mustBeNonempty}

        % Configuration - Code Analyzer configuration settings
        %
        %   Code Analyzer configuration settings, specified as "active",
        %   "factory", or a filename. By default, the task uses the current
        %   active configuration settings.
        Configuration (1,1) string

        % ErrorThreshold - Maximum number of errors allowed
        %
        %   Maximum number of errors allowed for the task to pass,
        %   specified as a nonnegative integer scalar. By default, the
        %   error threshold is 0.
        ErrorThreshold (1,1) {mustBeNonnegative, mustBeNonNan, mustBeNumeric}

        % WarningThreshold - Maximum number of warnings allowed
        %
        %   Maximum number of warnings allowed for the task to pass,
        %   specified as a nonnegative integer scalar. By default, the
        %   warning threshold is Inf.
        WarningThreshold (1,1) {mustBeNonnegative, mustBeNonNan, mustBeNumeric}
    end

    properties (TaskOutput, SetAccess=private)
        % Results - Results of code analysis
        %
        %   Results of the code analysis, specified as a string scalar,
        %   character vector, cell vector of character vectors, or vector
        %   of matlab.buildtool.io.File objects, and returned as a row
        %   vector of matlab.buildtool.io.File objects.

        % This property is unsupported and might change or be removed
        % without notice in a future version.
        Results (1,:) matlab.buildtool.io.File
    end

    properties (Constant, Hidden)
        Catalog = "CodeIssuesTask"
    end

    properties (Constant, Access = private)
        DefaultCodeAnalyzerConfiguration = "active"
    end

    methods
        function task = CodeIssuesTask(sourceFiles, options)
            % CodeIssuesTask - Class constructor
            %
            %   TASK = matlab.buildtool.tasks.CodeIssuesTask() creates a
            %   task to analyze the MATLAB code in the current folder and its
            %   subfolders.
            %
            %   TASK = matlab.buildtool.tasks.CodeIssuesTask(SOURCE)
            %   creates a task to analyze the MATLAB source files and
            %   folders in SOURCE. You can specify SOURCE as a string
            %   array, character vector, cell array of character vectors,
            %   or vector of matlab.buildtool.io.FileCollection objects.
            %   The files and folders that you specify must belong to the
            %   plan root folder or any of its subfolders.
            %
            %   TASK = matlab.buildtool.tasks.CodeIssuesTask(...,Name=Value)
            %   creates a task with additional options specified by one or
            %   more of these name-value arguments:
            %
            %       * IncludeSubfolders - Whether to include subfolders in the
            %       analysis, specified as a numeric or logical 1 (true) or 0
            %       (false).
            %
            %       * Configuration - Code Analyzer configuration settings,
            %       specified as "active", "factory", or a filename.
            %
            %           * "active"   - Use the current active configuration settings.
            %           * "factory"  - Use the default configuration settings.
            %           * <filename> - Use settings in the specified configuration file.
            %
            %       * ErrorThreshold - Maximum number of errors allowed for the
            %       task to pass, specified as a nonnegative integer scalar.
            %       Use this argument to create a task that fails when the
            %       number of identified errors exceeds a threshold.
            %
            %       * WarningThreshold - Maximum number of warnings allowed for
            %       the task to pass, specified as a nonnegative integer
            %       scalar. Use this argument to create a task that fails when
            %       the number of identified warnings exceeds a threshold.
            %
            %       * Results - Results of the code analysis, specified as a
            %       string scalar, character vector, cell vector of
            %       character vectors, or vector of matlab.buildtool.io.File
            %       objects. Use this argument to output results in the
            %       following formats:
            %
            %           * SARIF - Export the code issues in SARIF format.
            %           * JSON  - Export the code issues in JSON format.
            %           * MAT   - Store the code issues in a MAT-file.
            %
            %   Examples:
            %
            %       % Import the CodeIssuesTask class
            %       import matlab.buildtool.tasks.CodeIssuesTask
            %
            %       % Create a task to analyze the code in your current folder
            %       % and its subfolders by using the current active
            %       % configuration settings
            %       task = CodeIssuesTask();
            %
            %       % Create a task to analyze several source files and folders
            %       task = CodeIssuesTask(["myfolder1" fullfile("myfolder2","myfile1.m")]);
            %
            %       % Create a task to analyze code using the default code analyzer
            %       % configuration settings
            %       task = CodeIssuesTask("myfile1.m",Configuration="factory");
            %
            %       % Create a task that fails if it identifies any warnings
            %       task = CodeIssuesTask("myfolder",WarningThreshold=0);
            %
            %       % Create a task to store the identified code issues in a MAT-file
            %       task = CodeIssuesTask("myfolder",Results="issues.mat");
            %
            %       % Create a task to produce a SARIF file as well as a MAT-file
            %      task = CodeIssuesTask("myfolder",Results=["report.sarif" "issues.mat"]);
            %            

            arguments
                sourceFiles (1,:) matlab.buildtool.io.FileCollection = pwd() %#ok<INUSA>
                options.SourceFiles (1,:) matlab.buildtool.io.FileCollection = sourceFiles
                options.Description (1,1) string = getDefaultDescription()
                options.Dependencies (1,:) string = string.empty(1,0)
                options.IncludeSubfolders (1,1) logical = true
                options.Configuration (1,1) string = matlab.buildtool.tasks.CodeIssuesTask.DefaultCodeAnalyzerConfiguration
                options.ErrorThreshold (1,1) {mustBeNonnegative, mustBeNonNan, mustBeNumeric} = 0
                options.WarningThreshold (1,1) {mustBeNonnegative, mustBeNonNan, mustBeNumeric} = Inf
                options.Results (1,:) matlab.buildtool.io.File
            end

            for prop = string(fieldnames(options))'
                task.(prop) = options.(prop);
            end
        end
    end

    methods (TaskAction, Sealed, Hidden)
        function analyze(task, context)
            import matlab.automation.Verbosity

            validateSource(task.SourceFiles.absolutePaths(), context.Plan.RootFolder);

            % Identify code issues
            issues = codeIssues(task.SourceFiles.absolutePaths(), ...
                IncludeSubfolders=task.IncludeSubfolders, ...
                CodeAnalyzerConfiguration=task.Configuration);

            % Sort issues by severity
            numFiles = numel(issues.Files);
            numErrors = countIssuesBySeverity(issues.Issues, "error");
            numWarnings = countIssuesBySeverity(issues.Issues, "warning");

            % Report out analysis summary
            analysiSummaryDiag = createAnalysisSummaryDiagnostic(numFiles, numErrors, task.ErrorThreshold, numWarnings, task.WarningThreshold, task.Configuration);
            context.log(Verbosity.Concise, analysiSummaryDiag);

            % Save and report out results
            resultPaths = task.Results.absolutePaths();
            if numel(resultPaths) > 0
                resultsHeaderDiag = FormattableStringDiagnostic(PlainString(sprintf("%s:", getStringFromCatalog("ResultsHeader"))));
                context.log(Verbosity.Concise, resultsHeaderDiag);

                sourceRoot = getSourceRootFromPlan(context.Plan);
                resultsSummaryDiag = saveResultsAndCreateSummaryDiagnostic(task, issues, sourceRoot);
                context.log(Verbosity.Concise, resultsSummaryDiag);
            end

            assertionID = "MATLAB:buildtool:CodeIssuesTask:ThresholdExceeded";
            context.assertTrue(...
                numErrors <= task.ErrorThreshold && numWarnings <= task.WarningThreshold, ...
                getString(message(assertionID)));
        end
    end

    methods
        function task = set.Results(task, results)
            task.Results = results.transform(@assignDefaultExtensionIfNeeded);
        end        
    end

    methods (Hidden)
        function tf = supportsIncremental(task) %#ok<MANU>
            tf = false;
        end
    end
    
    methods (Access = private)
        function diag = saveResultsAndCreateSummaryDiagnostic(task, issues, sourceRoot)
            import matlab.buildtool.internal.tasks.codeIssuesResultsExtensionServices
            import matlab.buildtool.internal.services.codeanalysis.ResultsExtensionLiaison

            services = codeIssuesResultsExtensionServices();
            resultPaths = task.Results.absolutePaths();

            formattedResultsStr = LabelAlignedListString;
            for i = 1:numel(resultPaths)
                liaison = ResultsExtensionLiaison(resultPaths(i), issues, sourceRoot);
                fulfill(services, liaison);
                supportingService = services.findServiceThatSupports(liaison.ResultsFile);
                if ~isempty(supportingService)
                    save(supportingService, liaison);
                    formattedResultsStr = supportingService.addLabelAndString(liaison, formattedResultsStr);
                end
            end
            diag = FormattableStringDiagnostic(PlainString(sprintf("%s\n", IndentedString(formattedResultsStr.Text))));
        end
    end
end

function desc = getDefaultDescription()
desc = getString(message("MATLAB:buildtool:CodeIssuesTask:DefaultDescription"));
end

function sourceFolders = validateSource(source, planRootFolder)
sourceFolders = resolveSourceFolders(source);

% Source should belong to root folder's directory tree
planRootFolder = matlab.automation.internal.folderResolver(planRootFolder);
areSourceFoldersValid = arrayfun(@(s)s.contains(fullfile(planRootFolder, filesep)), fullfile(sourceFolders, filesep), UniformOutput=false);

if all([areSourceFoldersValid{:}])
    return
end
error(message("MATLAB:buildtool:CodeIssuesTask:SourceNotWithinPlanRootFolderDirTree"))
end

function sourceFolders = resolveSourceFolders(source)
sourcesSpecifiedAsFolders = source(arrayfun(@isfolder, source));
sourcesSpecifiedAsFiles   = source(arrayfun(@isfile, source));

% resolve files and folders
sourceFolders = arrayfun(@matlab.automation.internal.folderResolver, sourcesSpecifiedAsFolders, UniformOutput=false);
sourceFiles   = arrayfun(@matlab.automation.internal.fileResolver, sourcesSpecifiedAsFiles, UniformOutput=false);

% get folder names for each specified source
sourceFolders = [sourceFolders string(cellfun(@fileparts, sourceFiles, UniformOutput=false))];
end

function numIssues = countIssuesBySeverity(issues, severity)
numIssues = height(issues(issues.Severity == severity, :));
end

function sourceRoot = getSourceRootFromPlan(plan)
arguments
    plan (1,1) matlab.buildtool.Plan
end
if ~isempty(plan.Project)
    sourceRoot = plan.Project.RootFolder;
else
    sourceRoot = plan.RootFolder;
end
end

function diag = createAnalysisSummaryDiagnostic(numFiles, numErrors, errorThreshold, numWarnings, warningThreshold, configuration)
headerDiag = FormattableStringDiagnostic(PlainString(sprintf("\n%s:", getStringFromCatalog("SummaryHeader"))));

summary = LabelAlignedListString;
summary = summary.addLabelAndString(...
    sprintf("%s:", getStringFromCatalog("TotalFiles")), num2str(numFiles));
summary = summary.addLabelAndString(...
    sprintf("%s:", getStringFromCatalog("Errors")), ...
    sprintf("%s (%s: %s)", num2str(numErrors), getStringFromCatalog("Threshold"), num2str(errorThreshold)));
summary = summary.addLabelAndString(...
    sprintf("%s:", getStringFromCatalog("Warnings")), ...
    sprintf("%s (%s: %s)", num2str(numWarnings), getStringFromCatalog("Threshold"), num2str(warningThreshold)));

isDefaultConfig = configuration == matlab.buildtool.tasks.CodeIssuesTask.DefaultCodeAnalyzerConfiguration;
if ~isDefaultConfig
    summary = summary.addLabelAndString(sprintf("%s:", getStringFromCatalog("Configuration")), configuration);
end

summaryDiag = FormattableStringDiagnostic(PlainString(sprintf("%s\n", IndentedString(summary.Text))));

diag = [headerDiag summaryDiag];
end

function d = FormattableStringDiagnostic(varargin)
d = matlab.automation.internal.diagnostics.FormattableStringDiagnostic(varargin{:});
end

function fs = LabelAlignedListString(varargin)
fs = matlab.automation.internal.diagnostics.LabelAlignedListString(varargin{:});
end

function fs = IndentedString(varargin)
fs = matlab.automation.internal.diagnostics.IndentedString(varargin{:});
end

function fs = PlainString(varargin)
fs = matlab.automation.internal.diagnostics.PlainString(varargin{:});
end

function str = getStringFromCatalog(id)
str = matlab.buildtool.internal.tasks.getStringFromCatalog(matlab.buildtool.tasks.CodeIssuesTask.Catalog, id);
end

function p = assignDefaultExtensionIfNeeded(p)
import matlab.buildtool.internal.services.codeanalysis.MATFileResultsService
[fp, fn, fe] = fileparts(p);
fe(fe == "") = MATFileResultsService.Extension;
p = fullfile(fp, fn + fe);
end