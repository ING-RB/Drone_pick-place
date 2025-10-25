classdef plannerBenchmark < nav.algs.internal.InternalAccess
%plannerBenchmark Benchmark path planners using generated metrics
%
%   plannerBenchmark object benchmarks the 2-D path planners by running
%   them on a specified ENVIRONMENT with specified START and GOAL poses.
%
%   The plannerBenchmark object calculates the following metrics:
%      clearance          - Minimum distance to obstacles in the
%                           environment
%      executionTime      - Time taken by plan function to execute
%      initializationTime - Time taken by initialization function to
%                           execute
%      isPathValid        - If true represent the path exists and is
%                           collision free
%      pathLength         - Length of the generated path
%      smoothness         - Smoothness of the path for all poses
%
%   The metrics are calculated during the execution of planners and also
%   from the resulting path outputs after executing planners. Calculated
%   metrics are statistically summarized as a table and can be visualized.
%
%   OBJ = plannerBenchmark(ENVIRONMENT, START, GOAL) creates a
%   plannerBenchmark object with the specified ENVIRONMENT, START and GOAL
%   poses. The inputs ENVIRONMENT, START, GOAL sets the Environment, Start,
%   and Goal properties respectively.
%
%   plannerBenchmark properties:
%      Environment   - Environment for benchmarking path planners
%      Start         - Start pose of path for all planners
%      Goal          - Goal pose of path for all planners
%      PlannerOutput - Output of planners after execution
%
%   plannerBenchmark methods:
%      addPlanner - Add planner for benchmarking
%      runPlanner - Run path planners
%      metric     - Return path planner metrics
%      show       - Visualize path planner metrics
%      report     - Create benchmark report
%      copy       - Create deep copy of plannerBenchmark object
%
%   Example:
%
%      % Create an occupancy map from an example map.
%      load exampleMaps.mat
%      map = occupancyMap(simpleMap);
%
%      % set the start and goal poses.
%      start = [5 8 pi/2];
%      goal = [7 18 pi/2];
%
%      % Create a state validator with stateSpaceSE2 using the map.
%      sv = validatorOccupancyMap(stateSpaceSE2, Map=map);
%
%      % Define function handles for initialization function of the
%      % planners
%      plannerHAFcn = @(sv)plannerHybridAStar(sv);
%      plannerRRTSFcn = @(sv)plannerRRTStar(sv.StateSpace, sv);
%
%      % Define function handle for plan function, which is common for both
%      % planners.
%      plnFcn = @(initOut,s,g)plan(initOut,s,g);
%
%      % Create a plannerBenchmark object.
%      pbo = plannerBenchmark(sv, start, goal);
%
%      % Add planners initialization and plan function handles.
%      addPlanner(pbo, plnFcn, plannerHAFcn);
%      addPlanner(pbo, plnFcn, plannerRRTSFcn, PlannerName='ppRRTStar');
%
%      % Set the rng for repetitive results.
%      rng('default')
%
%      % Run planners runCount number of times to collect metrics.
%      runCount = 5;
%      runPlanner(pbo, runCount);
%
%      % Access Path length for all runs on the Environment.
%      pLength = metric(pbo, 'pathLength');
%
%      % Visualize all the metrics
%      show(pbo);
%
%      % Create benchmark report
%      report(pbo);
%
%   See also pathmetrics

%   Copyright 2021-2024 The MathWorks, Inc.

    properties
        %Environment Environment for benchmarking path planners
        %   Environment for benchmarking path planners, specified as
        %   occupancyMap, binaryOccupancyMap, or validatorOccupancyMap.
        Environment

        %Start Start pose of path for all planners
        %   Start pose of path for all planners, specified as a
        %   vector of the form [x y] or [x y theta].
        Start

        %Goal Goal pose of path for all planners
        %   Goal pose of path for all planners, specified as a vector of
        %   the form [x y] or [x y theta].
        Goal

    end

    properties (GetAccess=public, SetAccess=private)

        %PlannerOutput Output of planners after execution
        %   Output of planners after execution, returned as a structure
        %   that contains the initialization function output and plan
        %   function output for all planners. The fields of the structure
        %   are named by planner name specified in addPlanner function.
        %   Each structure contains an initialization output and a plan
        %   function output. The plan function output is further a
        %   structure containing plan function output for each run of the
        %   planner.
        PlannerOutput

    end

    properties (Access=?nav.algs.internal.InternalAccess)

        %MetricType Indicate whether a metric is plot using boxchart or bar
        % graph. MetricType with 0 indicates the metric is plot with boxchart
        % and 1 indicates the metric is plot using bar graph.
        MetricType

        %PlannerInfo store the plan, initialization function handles of all
        % planners
        PlannerInfo

        %RunCount Number of times of execution of planners
        %   Number of times of execution of planners, specified as a
        %   positive scalar. Use the runPlanner function to set this value.
        %   Default: 1
        RunCount

        %MarkupString contain the markup code in string for generating .mlx in
        % report method.
        MarkupString

    end

    properties(Access = private)

        %MetricTable store the metric result and statistical summary in table
        MetricTable

        %MetricMapContainer store the metric result as an array in a
        % Container.Map. The keys corresponds to the metric name
        MetricMapContainer

        %IsRunPlannerInvoked return true if the method runPlanner is
        % invoked atleast once.
        IsRunPlannerInvoked

    end

    methods

        function obj = plannerBenchmark(environment, start, goal)
        %plannerBenchmark constructor

            obj.Environment = environment;
            obj.Start = start;
            obj.Goal = goal;

            obj.PlannerInfo = struct();
            obj.PlannerOutput = struct();
            obj.MetricTable = table();
            obj.MetricType = struct();
            obj.IsRunPlannerInvoked = false;
        end

        function addPlanner(obj, planFcn, varargin)
        %addPlanner Add path planner for benchmarking
        %   addPlanner(OBJ, planFcn) adds the plan function of a planner as
        %   a function handle planFcn to the plannerBenchmark object.
        %
        %   addPlanner(OBJ, planFcn, initializationFcn) also adds the
        %   initialization function of a planner as a function handle
        %   initializationFcn to the plannerBenchmark object.
        %
        %   addPlanner(___,Name=Value) specifies options using one
        %   or more name-value pair arguments in addition to any
        %   combination of input arguments from previous syntaxes.
        %
        %   Input arguments for the function:
        %
        %   planFcn           Plan function of path planner
        %                     Plan function of path planner, specified as a
        %                     function handle.
        %                     The function handle should be of the form
        %                     @(initOut, START, GOAL)planFcn(...) where
        %                     initOut is the output of the initialization
        %                     function. If the initializationFcn input is
        %                     not specified, the function handle should be
        %                     @(ENV, START, GOAL)planFcn(...), where ENV is
        %                     the Environment property of plannerBenchmark.
        %
        %                     The first output of planFcn must be either a
        %                     navPath object, m-by-2, or m-by-3 matrix.
        %
        %   initializationFcn Initialization function of path planner.
        %                     Initialization function of path planner
        %                     specified as a function handle.
        %                     The function handle should be of the form
        %                     @(ENV)initializationFcn(...). The
        %                     initializationFcn should take Environment
        %                     as the first argument.
        %                     The output of initializationFcn will be the
        %                     first input to plan function handle.
        %
        %   Name-Value pairs for the function:
        %
        %   PlannerName -   Name of planner
        %                   Name of planner, specified as character vector
        %                   or string scalar.
        %                   Default: If workspace variable name of
        %                   initializationFcn and planFcn are initVar and
        %                   planVar respectively the default PlannerName
        %                   will be initVar_planVar.
        %
        %                   If the optional initializationFcn is not
        %                   specified then the default plannerName will be
        %                   planVar.
        %
        %                   If the function handles are specified as
        %                   anonymous functions directly inside the
        %                   addPlanner function the default PlannerName will
        %                   be 'CustomInitFcn_CustomPlanFcn'
        %
        %                   If the optional initializationFcn is not
        %                   specified and the plan function handle is
        %                   specified as an anonymous function directly
        %                   then the default plannerName will be
        %                   'CustomPlanFcn'.
        %
        %   NumPlanOutput - Number of expected output from plan function
        %                   Number of expected output from plan function
        %                   specified as a positive scalar
        %                   Default: 1

            narginchk(2,7);
            [nvStartIdx, initFcn] = obj.parseAddPlannerFcnHandles(planFcn, varargin);

            plannerInfo = struct();
            plannerInfo.PlanFcn = planFcn;
            isInitFcnExist = false;
            hasInitFcnInput = ~isempty(initFcn);
            if(hasInitFcnInput)
                plannerInfo.InitializationFcn = initFcn;
                isInitFcnExist = true;
            else
                plannerInfo.InitializationFcn = [];
            end
            %if the user provide function handle directly instead of
            % providing variable which store the function handle then
            % inputname returns empty. Generating a custom name in that
            % case.
            if(isempty(inputname(2)))
                planFcnName = 'CustomPlanFcn';
            else
                planFcnName = inputname(2);
            end
            if(isInitFcnExist)
                if(isempty(inputname(3)))
                    initFcnName = 'CustomInitFcn';
                else
                    initFcnName = inputname(3);
                end
                defaultName = [initFcnName '_' planFcnName];
            else
                defaultName = planFcnName;
            end
            names = {'PlannerName','NumPlanOutput'};
            % Default NumPlanOutput is set to 1
            defaults = {defaultName,1};

            % Create a parser
            parser = robotics.core.internal.NameValueParser(names,defaults);
            %parse till nargin-2 since nargin count planFcn as well as obj
            parse(parser, varargin{nvStartIdx:nargin-2});

            plannerName = parameterValue(parser,'PlannerName');
            validateattributes(plannerName,{'string','char'},{'scalartext'},'addPlanner','PlannerName');
            if(~isvarname(plannerName))
                error(message('nav:navalgs:plannerBenchmark:InvalidVariableName'));
            end
            if(isfield(obj.PlannerInfo,plannerName))
                error(message('nav:navalgs:plannerBenchmark:PlannerAlreadyExist', plannerName));
            end

            numPlanOutput = parameterValue(parser,'NumPlanOutput');
            validateattributes(numPlanOutput,'numeric',{'finite','integer','scalar','positive'},'addPlanner','NumPlanOutput');

            plannerInfo.NumPlanOutput = numPlanOutput;
            obj.PlannerInfo.(plannerName) =  plannerInfo;
        end

        function runPlanner(obj, varargin)
        %runPlanner Run path planners
        %
        %   runPlanner(OBJ) runs all the path planners once.
        %
        %   runPlanner(OBJ, RunCount) specifies the number of times to run
        %   all the path planners. The function collects outputs of
        %   initialization function and plan function. The function also
        %   calculates the executionTime for the plan function and
        %   initializationTime for the initialization function.
        %
        %   runPlanner(___,Verbose=Value) specifies verbose which display
        %   function progress. Value of verbose is specified as "on" or
        %   "off". The default value is "on".

            narginchk(1,4);
            numArgs = nargin;
            [runCount, verbose] = obj.parseRunPlannerInput(varargin, numArgs);
            obj.RunCount = runCount;

            % clear the output of the planners as well as Metrics Results
            % when runPlanner is called.
            obj.PlannerOutput = struct();
            obj.MetricTable = table();
            obj.MetricMapContainer = containers.Map;

            start = obj.Start;
            goal = obj.Goal;
            plannerNames = fieldnames(obj.PlannerInfo);
            numPlanners = numel(plannerNames);
            execTime = nan(numPlanners, runCount);
            initTime = nan(numPlanners,1);
            planFcnsOutput = cell(numPlanners,runCount);

            for i=1:numPlanners
                plannerName = plannerNames{i};
                plannerInit = obj.PlannerInfo.(plannerName).InitializationFcn;

                if(~isempty(plannerInit))
                    msg = message('nav:navalgs:plannerBenchmark:PlannerInitialize',plannerName);
                    obj.displayProgress(msg,verbose);
                    tic;
                    initOutput = plannerInit(obj.Environment);
                    planFcnInput = initOutput;
                    initTime(i,1) = toc;
                    msg = message('nav:navalgs:plannerBenchmark:PlannerInitDone');
                    obj.displayProgress(msg,verbose);
                else
                    initOutput = [];
                    planFcnInput = obj.Environment;
                end
                planFcn = obj.PlannerInfo.(plannerName).PlanFcn;
                numPlanOutput = obj.PlannerInfo.(plannerName).NumPlanOutput;
                planOutput = cell(1, numPlanOutput);
                %Display 'Planning with ...' message on the console
                msg = obj.getVerboseMessage(plannerName, 'planFcnRunning', runCount);
                obj.displayProgress(msg,verbose);

                for runCount = 1:obj.RunCount
                    % Display 'At run 1.' message on the console
                    msg = message('nav:navalgs:plannerBenchmark:PlanFcnRunCount', runCount);
                    obj.displayProgress(msg,verbose);
                    try
                        tic;
                        [planOutput{1:numPlanOutput}] = planFcn(planFcnInput, start, goal);
                        execTime(i, runCount) = toc;
                    catch ME
                        msg = obj.getVerboseMessage(plannerName, 'planFcnError', runCount);
                        warning(msg);
                        ident = ME.identifier;
                        disp(ident);
                        planOutput = cell(1,numPlanOutput);
                    end
                    planFcnsOutput{i,runCount} = planOutput;
                end
                % During each run in RunCount, the planner configurations
                % does not change. Hence using the first non empty output to
                % determine which planner metric interface object to create.
                emptyCheck = @(x) ~isempty(x{1});
                validPlanOutIdx = find(cellfun(emptyCheck,planFcnsOutput(i,:)),1);
                pathOutput = [];
                if ~isempty(validPlanOutIdx)
                    pathOutput = planFcnsOutput{i,validPlanOutIdx}{1};
                end
                createPlannerMetricObj(obj, pathOutput, plannerName);
                obj.createPlannerOutputStruct(plannerName, ...
                                              planFcnsOutput(i,:), initOutput);
            end
            % assign the executionTime result to MetricMapContainer property and
            % set the MetricType property to 0
            assignPlannerMetrics(obj, 'executionTime', execTime, 0);
            % assign the initializationTime result to MetricMapContainer property
            % and set the MetricType property to 0
            assignPlannerMetrics(obj, 'initializationTime', initTime, 0);
            %calculates the path metrics from the planner output
            obj.calculatePathMetrics();
            obj.IsRunPlannerInvoked = true;
        end

        function [metricSummary,metricData] = metric(obj, varargin)
        %metric Return path planner metrics as table
        %   metricSummary = metric(OBJ) return the summary of all the path
        %   planner metrics as a table. The summary includes Mean, Median
        %   Standard Deviation, and sampleSize for metrics of numeric type.
        %   For the metrics of logical type, the summary includes the
        %   TrueCount, FalseCount, and SuccessRate. TrueCount is the number
        %   of times the metric value is true. FalseCount is the number of
        %   times the metric value is false. SuccessRate is the ratio of
        %   TrueCount to total runs of planner expressed in percentage.
        %
        %   metricSummary = metric(OBJ, metricName) return the summary of
        %   a specific metric. Metric name is specified as "clearance",
        %   "executionTime", "initializationTime", "isPathValid",
        %   "pathLength", or "smoothness".
        %
        %   [metricSummary, metricData] = metric(OBJ) returns
        %   metricData table with the metric values across each run for all
        %   metrics and metricSummary table with the summary of all
        %   metrics.
        %
        %   [metricSummary, metricData] = metric(OBJ, metricName) returns
        %   the summary and the values of a specific metric.
        %
        %   Note:
        %       - If the metric value can not be computed due to empty
        %         states in path output or error during plan function
        %         execution, NaN is returned for corresponding values in
        %         metric data tables.
        %         The show function will not display any value for metrics
        %         with NaN value.
        %       - If the path output is navPath, metrics are calculated
        %         using the state space in navPath.
        %       - If the path output is a vector of size m-by-2, state
        %         space is assumed as stateSpaceSE2 with theta as 0 for
        %         all poses.
        %       - If the path output is a vector of size m-by-3, the third
        %         column in the path output is assumed as theta and
        %         subsequently stateSpaceSE2 is assumed as the state space.
        %       - If environment is validatorOccupancyMap, the metric
        %         isPathValid is computed using the specified environment.
        %       - If environment is occupancyMap or binaryOccupancyMap,
        %         default validatorOccupancyMap is created using the
        %         specified environment as Map and state space is derived
        %         as above.
        %       - The ValidationDistance is assumed as
        %         0.1*(1/resolution of map).

            narginchk(1,2);
            if(~obj.IsRunPlannerInvoked)
                error(message('nav:navalgs:plannerBenchmark:RunPlannerNotInvoked', ...
                              'metric'));
            end
            if(nargin == 2)
                metricName = varargin{1};
                metricName = obj.validateMetricName(metricName, 'metric');
            end

            metricData = table();
            metricSummary = table();
            %Create metric tables corresponding to each metric
            obj.createMetricTables();
            if nargin == 1
                numMetrics = obj.MetricMapContainer.Count;
                metricNames = keys(obj.MetricMapContainer);
                for i=1:numMetrics
                    metricName = metricNames{i};
                    metricData.(metricName) = obj.MetricTable.(metricName);
                    metricSummaryName = append(metricName, 'Summary');
                    metricSummary.(metricSummaryName) = obj.MetricTable.(metricSummaryName);
                end

            else
                metricData = obj.MetricTable.(metricName);
                metricSummaryName = append(metricName, 'Summary');
                metricSummary = obj.MetricTable.(metricSummaryName);

            end
        end

        function  axisOut = show(obj, metricName)
        %show Visualize path planner metrics
        %   show(OBJ) visualizes all the path planner metrics in a figure
        %   as boxplots and bar graphs.
        %
        %   axHandle = show(OBJ) returns the axes handle of the figure used
        %   to plot all the metrics.
        %
        %   [...] = show(OBJ, metricName) visualizes metric.
        %   Metric name can be a string scalar, character vector,
        %   string array, or cell array of character vectors.
        %   The supported metric names are "clearance", "executionTime",
        %   "initializationTime", "isPathValid", "pathLength", or
        %   "smoothness".

            narginchk(1,2);
            if(~obj.IsRunPlannerInvoked)
                error(message('nav:navalgs:plannerBenchmark:RunPlannerNotInvoked', ...
                              'show'));
            end

            tiledLayout = tiledlayout('flow');
            % if no metricName is given by the user, then display all the
            % supported metrics.
            if (nargin == 1)
                numMetrics = obj.MetricMapContainer.Count;
                metricNames = keys(obj.MetricMapContainer);
            else
                metricNames = validateMetricInput(obj, metricName, 'show');
                numMetrics = length(metricNames);
            end
            % Iterate over the metrics and display them in a tiled chart.
            for i=1:numMetrics
                axis = nexttile(tiledLayout);
                displayMetric(obj, axis, metricNames{i});
                title(metricNames{i});
            end

            if(nargout == 1)
                axisOut = tiledLayout;
            end
        end

        function report(obj, filename, varargin)
        %report Create benchmark report
        %   report(OBJ) creates and opens a benchmark report as a
        %   live script (.mlx) in the MATLAB editor. The function saves the
        %   report in the current working directory with the default file
        %   name.
        %
        %   report(OBJ, FILENAME) creates a benchmark report with the name
        %   specified by FILENAME. The file name can include an absolute
        %   path, relative path, or no path. Specifying the (.mlx)
        %   extension is optional.
        %
        %   report(OBJ, FILENAME, Name=Value) specifies options using one
        %   or more name-value pair arguments in addition to the name of
        %   the report file.
        %
        %   Note: The report function also exports the plannerBenchmark
        %   object to a MAT-file and place the file in a folder called
        %   plannerBenchmark, in the current working directory or to the
        %   specified path.
        %
        %   Input arguments for the function:
        %
        %   FILENAME  Name of report
        %             Name of report, specified as string scalar, or
        %             character vector.
        %             Default: report.mlx
        %
        %   Name-Value arguments for the function:
        %
        %   Metric -  Name of metric to add to report.
        %             Name of metric to add to report, specified as a
        %             string scalar, character vector, string array, or cell
        %             array of character vectors of supported metrics.
        %             The supported metrics are "clearance",
        %             "executionTime", "initializationTime", "isPathValid",
        %             "pathLength", and "smoothness".
        %             Default: {'clearance','executionTime',
        %             'initializationTime', 'isPathValid', 'pathLength',
        %             'smoothness'}
        %
        %   Exclude - Content section to exclude from the report.
        %             Content section to exclude from the report, specified
        %             as a string scalar, character vector, string array,
        %             or a cell array of character vectors of supported
        %             contents of exclusion. The Supported contents of
        %             exclusion are "PathVisualization" and
        %             "DetailedTable".
        %             "PathVisualization" excludes the "Visualize Path on
        %             Map" section from the report.
        %             "DetailedTable" exclude all the metric tables that
        %             contains the metric result from individual
        %             executions.
        %             Default: 'None'
        %
        %   Open -    Open report in editor.
        %             Open report in editor, specified as true or false.
        %             When set to true, the function opens the report in
        %             the MATLAB editor. Otherwise, it does not open the
        %             report in the editor.
        %             Default: true




        % Error when report function is invoked before benchmarking.
            if(~obj.IsRunPlannerInvoked)
                error(message("nav:navalgs:plannerBenchmark:RunPlannerNotInvoked", 'report'));
            end
            narginchk(1,8);

            numInputs = nargin;
            % Assign default file name if fileName argument is missing
            defaultFileName = 'report';
            if nargin == 1
                filename = defaultFileName;
            end
            % Valid value for the Exclude name-value pair
            validExcludeContent = ["DetailedTable", "PathVisualization", "None"];
            %fileparts expect filename input as a character vector
            filename = convertStringsToChars(filename);
            % Parse input
            [metricsInReport, isEditorOpen, contentExclude] = ...
                parseAndValidateReportInput(obj, filename, varargin, ...
                                            validExcludeContent, numInputs);

            [filePath, fileNameNoExtn, extn] = fileparts(filename);

            % Retrieve absolute path and full file name with extension
            [absoluteFilePath, fullFileName] = obj.validateAndGetFileDetail(filePath, ...
                                                                            fileNameNoExtn, extn);
            plannerNames = fieldnames(obj.PlannerInfo);
            % plannerBenchmark object is saved in a folder named
            % "plannerBenchmark". The object is named by concatenating 'Object'
            % to fileName without extension.
            benchmarkObjName = [fileNameNoExtn 'Object'];
            folderName = 'plannerBenchmark';

            % Return the markup code for generating the mlx report
            markupCode = getMarkupCodeReport(obj, plannerNames, ...
                                             metricsInReport, contentExclude, folderName, benchmarkObjName);
            % Indent the markup code
            % indentCode functionality is not supported by compiler
            if ~(ismcc || isdeployed)
                markupCode.indentCode;
            end
            markupStr = markupCode.string;

            % If plannerBenchmark folder does not exist, create a new
            % folder
            if(~isfolder(fullfile(absoluteFilePath, folderName)))
                mkdir(fullfile(absoluteFilePath, folderName))
            end

            benchmark = obj;
            obj.MarkupString = markupStr;
            % save the plannerBenchmark object in the folder
            save(fullfile(absoluteFilePath, folderName, benchmarkObjName),'benchmark');

            % Convert the markup string to mlx and save in the file path
            status = matlab.internal.livecode.FileModel.convertTextToLiveCode ...
                     (markupStr, absoluteFilePath, fullFileName);

            if isempty(status)
                error(message('nav:navalgs:plannerBenchmark:CanNotSaveReport', fullFileName));
            end

            % Open the generated report in the editor if the Open
            % name-value pair is true.
            if isEditorOpen && ~(ismcc || isdeployed)
                % openDocument functionality is not supported by compiler
                matlab.desktop.editor.openDocument(fullFileName);
            end
        end

        function newObj = copy(obj)
        %copy Create deep copy of plannerBenchmark object
        % plannerBenchmark2 = copy(plannerBenchmark1) creates a deep
        % copy of the plannerBenchmark object with the same properties.

            environment = obj.Environment.copy;
            start = obj.Start;
            goal = obj.Goal;
            runCount = obj.RunCount;
            plannerOutput = obj.PlannerOutput;
            newObj = plannerBenchmark(environment, start, goal);
            newObj.RunCount = runCount;
            newObj.PlannerOutput = plannerOutput;
            newObj.MetricType = obj.MetricType;
            newObj.MetricTable = obj.MetricTable;
            newObj.PlannerInfo = obj.PlannerInfo;
            newObj.MetricMapContainer = obj.MetricMapContainer;
            newObj.IsRunPlannerInvoked = obj.IsRunPlannerInvoked;
            newObj.MarkupString = obj.MarkupString;
        end

        %% SET functions and input validation
        function set.Environment(obj,input)
        %set assign the Environment property to the plannerBenchmark object
            validateattributes(input,...
                               {'binaryOccupancyMap', ...
                                'occupancyMap','validatorOccupancyMap'}, {'scalar'}, 'plannerBenchmark', 'Environment');
            obj.Environment = input;
        end

        function set.Start(obj, input)
        %set assign the Start property to the plannerBenchmark object
            if(size(input,2) == 3)
                validateattributes(input, {'double'}, {'finite','row'}, 'plannerBenchmark', 'Start');
            else
                validateattributes(input, {'double'}, {'finite','row','ncols',2}, 'plannerBenchmark', 'Start');
            end
            obj.Start = input;
        end

        function set.Goal(obj, input)
        %set assign the Goal property to the plannerBenchmark object

            if(size(input,2) == 3)
                validateattributes(input, {'double'}, {'finite','row'}, 'plannerBenchmark', 'Goal');
            else
                validateattributes(input, {'double'}, {'finite','row','ncols',2}, 'plannerBenchmark', 'Goal');
            end
            obj.Goal = input;
        end
    end

    methods(Access = 'private')

        function createPlannerMetricObj(obj, plannerOutput, plannerName)
        %createPlannerMetricObj create geometricPlannerMetrics object
            dimPlannerOutput = size(plannerOutput,2);
            if(isa(plannerOutput, 'navPath') || ((dimPlannerOutput == 2) || (dimPlannerOutput == 3)))
                metricObj = nav.algs.internal.geometricPlannerMetrics(obj.Environment);
                obj.PlannerInfo.(plannerName).MetricObj = metricObj;
            else
                % If the planner output is not navPath object or an array
                % of size m-by-2 or m-by-3 assign metric object an empty
                % array.
                obj.PlannerInfo.(plannerName).MetricObj = [];
            end
        end

        function calculatePathMetrics(obj)
        %calculatePathMetrics calculates the metrics for every planner
        % across every run
            plannerNames = fieldnames(obj.PlannerInfo);
            % Number of planners for benchmarking
            numPlanners = numel(plannerNames);
            runCount = obj.RunCount;

            %calculate metrics for each planner and run in RunCount
            for i=1:numPlanners
                plannerName = plannerNames{i};
                metricObj = obj.PlannerInfo.(plannerName).MetricObj;
                if(~isempty(metricObj))
                    metricList = metricObj.MetricList;
                    numMetrics = numel(metricList);
                    metricResult = nan(numPlanners, runCount);

                    for j=1:numMetrics
                        metricName = metricList{j};
                        if(isKey(obj.MetricMapContainer, metricName))
                            metricResult = obj.MetricMapContainer(metricName);
                        end
                        for k=1:runCount
                            runCountStr = ['Run' num2str(k)];
                            planOutput = obj.PlannerOutput.( ...
                                plannerName).PlanOutput.(runCountStr);
                            initOutput = obj.PlannerOutput.( ...
                                plannerName).InitializationOutput;
                            %The first output from plan function is the
                            % path output.
                            if ~(isempty(planOutput{1}))
                                assignPlannerOutput(metricObj,planOutput,initOutput);
                                metricFcnHandle = str2func(metricName);
                                metricValue = metricFcnHandle(metricObj);
                                metricResult(i,k) = metricValue;
                            end
                        end
                        obj.MetricMapContainer(metricName) = metricResult;
                        obj.MetricType.(metricName) = metricObj.MetricType(j);
                    end
                end
            end
        end

        function createMetricTables(obj)
        %createMetricTables create summary and data tables for
        % individual metrics

            runs = 1:obj.RunCount;
            varNames = append(repmat("Run",1,obj.RunCount),string(runs));
            plannerNames = fieldnames(obj.PlannerInfo);
            numMetrics = obj.MetricMapContainer.Count;
            metricNames = keys(obj.MetricMapContainer);
            for i=1:numMetrics
                metricName = metricNames{i};
                if(strcmp(metricName,'initializationTime'))
                    obj.createInitTimeTables(metricName);
                else
                    metricVal = obj.MetricMapContainer(metricName);
                    metricTable = array2table(metricVal,'VariableNames',varNames,'RowNames',plannerNames);
                    obj.MetricTable.(metricName) = metricTable;
                end
                if(obj.MetricType.(metricName) == 0)
                    metricSummary = createMetricSummary(obj, metricName);
                    str = append(metricName, 'Summary');
                    obj.MetricTable.(str) = metricSummary;

                else
                    metricSummary = createBooleanMetricSummary(obj, metricName);
                    str = append(metricName, 'Summary');
                    obj.MetricTable.(str) = metricSummary;
                end
            end

        end

        function createInitTimeTables(obj, metricName)
        %createInitTimeTables create tables for
        %initialization time of the planner.

            metricVal = obj.MetricMapContainer(metricName);
            varNames = "Time";
            plannerNames = fieldnames(obj.PlannerInfo);
            metricTable = array2table(metricVal,'VariableNames',varNames,'RowNames',plannerNames);
            obj.MetricTable.(metricName) = metricTable;

        end

        function metricSummary = createMetricSummary(obj, metricName)
        %createMetricSummary return summary table for metrics
            plannerNames = fieldnames(obj.PlannerInfo);
            metric = obj.MetricMapContainer(metricName);
            numPlanners = size(metric,1);
            Mean = nan(numPlanners,1);
            Median = nan(numPlanners,1);
            StdDev = nan(numPlanners,1);
            runCount = obj.RunCount;
            sampleSize = runCount*ones(numPlanners,1);

            for i=1:numPlanners
                metricVal = metric(i,:);
                inValidRunIdx = isnan(metricVal);
                % sampleSize as a column vector represent the number of
                % runs where a valid metric value is calculated.
                sampleSize(i) = sampleSize(i) - sum(inValidRunIdx);
                metricVal(inValidRunIdx) = [];
                % if metricVal is empty, then mean, median, stdDev will
                % return NaN. To show zero for Mean, Median and StdDev
                % make metric an array of zero.
                if(isempty(metricVal))
                    metricVal = zeros(1,runCount);
                end
                Mean(i) = mean(metricVal);
                Median(i) = median(metricVal);
                StdDev(i) = std(metricVal,1,2);
            end
            metricSummary = table(Mean, Median, StdDev, sampleSize);
            metricSummary.Properties.RowNames = plannerNames;
        end

        function metricSummary = createBooleanMetricSummary(obj, metricName)
        %createBooleanMetricSummary return summary table for metrics of
        % type boolean
            plannerNames = fieldnames(obj.PlannerInfo);
            metric = obj.MetricMapContainer(metricName);
            metric(isnan(metric)) = 0;
            TrueCount = sum(metric,2);
            runCount = obj.RunCount;
            FalseCount = runCount - TrueCount;
            SuccessRate = (TrueCount/runCount)*100;
            metricSummary = table(TrueCount, FalseCount, SuccessRate);
            metricSummary.Properties.RowNames = plannerNames;
        end

        function imageHandle = displayMetric(obj, axis, metricName)
        %displayMetric return the axis object of the metric displayed
            metric = obj.MetricMapContainer(metricName);
            %MetricType 0 indicates double values, 1 indicates boolean
            if(obj.MetricType.(metricName) == 0)
                %if metric is a vector (when RunCount = 1, metric will be
                % a column vector) boxchart return a single box chart.
                % Hence duplicate metric to create correct boxchart
                % representation
                if(size(metric,2) == 1)
                    metric = [metric,metric];
                end
                %metric contains each planner as a row and number of runs as column
                imageHandle = boxchart(axis,metric');
                labels = fieldnames(obj.PlannerInfo);
                set(gca,'xticklabel', labels, "XTickLabelRotation", 0, ...
                        'TickLabelInterpreter','none');
                xlabel(message('nav:navalgs:plannerBenchmark:FigureXLabel').getString);
                ylabel(metricName,'Interpreter','none');
            else
                metricSummary = createBooleanMetricSummary(obj, metricName);
                successRate = metricSummary.SuccessRate;
                imageHandle = bar(axis,successRate);
                labels = fieldnames(obj.PlannerInfo);
                set(gca,'xticklabel', labels, "XTickLabelRotation", 0, ...
                        'TickLabelInterpreter','none');
                xlabel(message('nav:navalgs:plannerBenchmark:FigureXLabel').getString);
                label = append(metricName,' (SuccessRate)');
                ylabel(label,'Interpreter','none');

            end
        end

        function metricNameMatch = validateMetricName(obj, metricName,funcName)
        % validateMetricName validate metricName
        % This Method check whether metric name supplied by the user is
        % a supported metric name.

            validateattributes(metricName,{'string','char'},{'scalartext'},funcName,'metricName');
            validMetricNames = keys(obj.MetricMapContainer);
            metricNameMatch = validatestring(metricName, validMetricNames, funcName, 'metricName');
        end

        function metricsInCell = validateMetricInput(obj, metricsInput, functionName)
        % validateMetricInput validate the metric input.
        % Validates that the input type is of supported type. Also
        % validates whether metric names are supported and removes any
        % duplicate metric name.

            validateattributes(metricsInput,{'cell','string','char'}, {'nonempty','vector'}, functionName,'Metric');
            % Convert metrics to cell array for further processing
            metricsInCell = cellstr(metricsInput);
            % Validate each input in cell array is a valid metric name
            for i=1:length(metricsInCell)
                metricsInCell{i} = validateMetricName(obj, metricsInCell{i}, functionName);
            end
            % If user provide same metric name multiple times, include only one metric in the report
            metricsInCell = unique(metricsInCell);
        end


        function [runCount, verbose] = parseRunPlannerInput(obj, vararginIn, numArgs)
        %parseRunPlannerInput parse and validate the input to runPlanner method

            plannerNames = fieldnames(obj.PlannerInfo);
            % Number of planners for benchmarking
            numPlanners = numel(plannerNames);
            if(numPlanners == 0)
                error(message('nav:navalgs:plannerBenchmark:PlannersNotAdded','runPlanner'));
            end

            %start index of name-value pairs
            nvStartIndex = 2;
            %If the first argument in varargin is a string scalar or a
            % character array then name-value pair starts at index 1 and
            % optional argument RunCount is not present
            if((numArgs == 1)||isStringScalar(vararginIn{1})|| ...
               ischar(vararginIn{1}))
                nvStartIndex = 1;
                %Default value of RunCount is 1
                runCount = 1;
            else
                runCount = vararginIn{1};
                validateattributes(runCount,'numeric',{'finite','integer', ...
                                                       'scalar','positive'},'runPlanner','runCount');
            end
            validateattributes(runCount,'numeric',{'finite','integer','scalar','positive'});

            names = {'Verbose'};
            defaults = {'on'};
            parser = robotics.core.internal.NameValueParser(names,defaults);
            %The number of elements in varargin is numArgs-1
            parse(parser, vararginIn{nvStartIndex:numArgs-1});

            verbose = parameterValue(parser,'Verbose');
            validateattributes(verbose,{'string','char'},{'scalartext'}, 'runPlanner');
            if(~any(strcmp(verbose,{'on','off'})))
                error(message('nav:navalgs:plannerBenchmark:IncorrectVerbose'));
            end
        end

        function createPlannerOutputStruct(obj, plannerName, planFcnsOutput, initOutput)
        %createPlannerOutputStruct assign PlannerOutput property with the
        % output of initialization function and plan function as a
        % structure.
            runCount = obj.RunCount;
            runs = 1:runCount;
            varNames = append(repmat("Run",1,runCount),string(runs));
            PlanOutStruct = cell2struct(planFcnsOutput,varNames,2);
            obj.PlannerOutput.(plannerName).PlanOutput = struct(PlanOutStruct);
            obj.PlannerOutput.(plannerName).InitializationOutput = initOutput;
        end

        function assignPlannerMetrics(obj, metricName, metricVal, metricType)
        %assignPlannerMetrics assign the metricName to MetricMapContainer property
        % Also set the MetricType property.

            obj.MetricMapContainer(metricName) = metricVal;
            obj.MetricType.(metricName) = metricType;
        end

        function msg = getVerboseMessage(obj, plannerName, status, runCount)
        %getVerboseMessage return the verbose message during runPlanner
        % method
            start = obj.Start;
            goal = obj.Goal;
            startLength = numel(start);

            if(strcmp(status, 'planFcnRunning'))
                if(startLength == 3)
                    msg = message('nav:navalgs:plannerBenchmark:PlanFcnRunningStartSize3', ...
                                  plannerName, num2str(start(1,1)), num2str(start(1,2)), ...
                                  num2str(start(1,3)), num2str(goal(1,1)), ...
                                  num2str(goal(1,2)), num2str(goal(1,3)));
                else
                    msg = message('nav:navalgs:plannerBenchmark:PlanFcnRunningStartSize2', ...
                                  plannerName, num2str(start(1,1)), num2str(start(1,2)), ...
                                  num2str(goal(1,1)), num2str(goal(1,2)));
                end
            else
                if(startLength == 3)
                    msg = message('nav:navalgs:plannerBenchmark:PlanFcnErrorStartSize3', ...
                                  plannerName, num2str(start(1,1)), num2str(start(1,2)), ...
                                  num2str(start(1,3)), num2str(goal(1,1)), ...
                                  num2str(goal(1,2)), num2str(goal(1,3)), ...
                                  num2str(runCount));
                else
                    msg = message('nav:navalgs:plannerBenchmark:PlanFcnErrorStartSize2', ...
                                  plannerName, num2str(start(1,1)), num2str(start(1,2)), ...
                                  num2str(goal(1,1)), num2str(goal(1,2)), ...
                                  num2str(runCount));
                end

            end
        end

        function [metricsInReportCell, editorOpen, matchExcludeContent] = ...
                parseAndValidateReportInput(obj, fileName, varInput, validExcludeContent, numInputsReport)
        %parseAndValidateReportInput parse and validate the Name-Value pairs
        % and validate FILENAME.

        % Validate fileName
            validateattributes(fileName,{'string','char'},{'scalartext', 'nonempty'},'report','fileName');

            % fileName is not an optional argument with name-value pairs
            if numInputsReport > 2 && mod(numInputsReport,2) > 0
                error(message("nav:navalgs:plannerBenchmark:FileNameMissing"));
            end

            %Name-value pair names
            names = ["Metric", "Open", "Exclude"];

            % By default all the metrics will be added to the report. Also
            % by default the report is open in the editor and none of the
            % content is excluded from the report.
            defaultMetrics = keys(obj.MetricMapContainer);
            defaultEditorOpen = true;
            defaultExclude = "None";

            defaults = {defaultMetrics, defaultEditorOpen, defaultExclude};
            parser = robotics.core.internal.NameValueParser(names,defaults);
            % Number of arguments in variable input.
            numArgs = numInputsReport - 2;
            parse(parser, varInput{1:numArgs});

            metricsInReport = parameterValue(parser,"Metric");
            metricsInReportCell = validateMetricInput(obj, metricsInReport, 'report');

            editorOpen = parameterValue(parser,"Open");
            validateattributes(editorOpen,{'logical'},{'scalar','nonempty'},'report','isEditorOpen');

            excludeContent = parameterValue(parser,"Exclude");
            % Validate contentExclude
            validateattributes(excludeContent,{'cell','string','char'}, {'nonempty', 'vector'}, 'report','Exclude');
            % Convert excludeContent to cell array for further processing
            excludeContentCell = cellstr(excludeContent);
            % Validate that each input in cell array is a valid exclude content.
            % Matching of partial string is also supported.
            matchExcludeContent = obj.validateExcludeContent(excludeContentCell,validExcludeContent);

        end

        function markupCode = getMarkupCodeReport(obj, plannerNames, ...
                                                  metricsInReport, contentExclude, folderName, benchmarkObjName)
        %getMarkupCodeReport return the markup string for creating the
        %report

            markupCode = StringWriter;

            %Section Report title
            markupCode.addcr('%% Planner Benchmark Report');
            markupCode.addcr(['% Generated on ' char(datetime('now')) '.']);
            markupCode.addcr('%');
            markupCode.addcr('% This report contains the benchmark results of these 2-D path planners:');
            markupCode.addcr('%%');
            for i = 1:length(plannerNames)
                markupCode.addcr(['% * |' plannerNames{i} '|']);
            end
            markupCode.addcr('%%');
            markupCode.addcr('% The benchmarks are performed using these metrics:');
            markupCode.addcr('%%');
            for i = 1:length(metricsInReport)
                markupCode.addcr(['% * |' metricsInReport{i} '|']);
            end

            % Section Environment, start, and goal location
            markupCode.addcr('%% Environment *and Robot Poses*');
            str = ['% Load the |plannerBenchmark| object from the MAT file. This ' ...
                   'object contains the benchmark results of the planners, as well as ' ...
                   'the environment and start and goal poses used to benchmark them. Extract ' ...
                   'the benchmark data and benchmarking environment from the object.'];
            markupCode.addcr(str);
            str = ['benchmarkData = load(fullfile("' folderName '","' benchmarkObjName '"));'];
            markupCode.addcr(str);
            markupCode.addcr('benchmark = benchmarkData.benchmark;');

            % Fetch map from validator if environment is
            % validatorOccupancyMap
            if isa(obj.Environment, 'validatorOccupancyMap')
                markupCode.addcr('map = benchmark.Environment.Map;');
            else
                markupCode.addcr('map = benchmark.Environment;');
            end
            % '%%%' Adds a dummy section without title and section break for
            % markup to work
            markupCode.addcr('%%%');
            markupCode.addcr('% Visualize the map used for benchmarking the planners.');
            markupCode.addcr('show(map)');
            markupCode.addcr('%%%');
            markupCode.addcr('% Display the start and goal poses.');
            markupCode.addcr('start = benchmark.Start;');

            % Display the start location based on start size
            if size(obj.Start,2) == 3
                markupCode.addcr('fprintf("Start pose is [%f %f %f]\n", start)');
            else
                markupCode.addcr('fprintf("Start pose is [%f %f]\n", start)');
            end
            markupCode.addcr('goal = benchmark.Goal;');
            markupCode.addcr('%%%');
            if size(obj.Goal,2) == 3
                markupCode.addcr('fprintf("Goal pose is [%f %f %f]\n", goal)');
            else
                markupCode.addcr('fprintf("Goal pose is [%f %f]\n", goal)');
            end


            % Section visualizing path on the map
            if(~any(strcmp(contentExclude, 'PathVisualization')))

                % Choose the first metric from the metric list to be visualized in the report
                chosenMetric = metricsInReport{1};

                markupCode.addcr('%% Visualize Path on Map');
                str = ['% The benchmark results contain all the paths generated by each planner ' ...
                       'for the specified start-goal pair across all runs in the environment. ' ...
                       'This code visualizes the planned path from each planner that returns ' ...
                       'the minimum value for the specified metric |' chosenMetric '|. You can modify ' ...
                       'this code to visualize your desired metric and conditions.'];
                markupCode.addcr(str);
                markupCode.addcr(['metricName = "' chosenMetric '";']);
                % Retrieve the detailed metric table
                str = '[~,metricDetailedTable] = metric(benchmark,metricName);';
                markupCode.addcr(str);
                % Convert detailed metric table to array
                str = 'metricValues = table2array(metricDetailedTable);';
                markupCode.addcr(str);
                % Find indexes in which selected metric is minimum
                markupCode.addcr('% Find the index in which metric value is minimum.');
                str = '[~,runIndexes] = min(metricValues,[],2);';
                markupCode.addcr(str);
                %Display path of each run when selected metric is minimum
                %for each planner.
                markupCode.addcr('% Display path output by each planner that produced minimum metric value.');
                markupCode.addcr('mapAxis = show(map);');
                markupCode.addcr('hold on');
                markupCode.addcr('plannerNames = fieldnames(benchmark.PlannerOutput);');
                markupCode.addcr('for i = 1:length(runIndexes)');
                markupCode.addcr(['plotPath(benchmark,mapAxis,' ...
                                  'plannerNames{i},runIndexes(i))']);
                markupCode.addcr('end');
                markupCode.addcr('legend("Interpreter","none")');
                markupCode.addcr('hold off');
            end


            % Section Benchmark results
            markupCode.addcr('%% Benchmark Results');
            runCount = obj.RunCount;
            str = ['% For benchmarking, MATLAB runs each planner ' num2str(runCount) ...
                   ' times. You can visualize the benchmark results for each metric ' ...
                   'as a summary table, detailed table, or plot. The summary table ' ...
                   'contains the statistical summary of the metric across all  ' ...
                   'the runs. The detailed table contains the value of the metric for each run of ' ...
                   'the planners. The plot is a box chart or bar graph that represents the statistical ' ...
                   'summary of the metric.'];
            markupCode.addcr(str);

            numMetrics = size(metricsInReport,2);
            % For each metric, display the show method output, metric
            % summary table and detailed metric table
            for i=1:numMetrics
                metricName = metricsInReport{i};
                markupCode.addcr(['%% |' metricName '|']);
                markupCode.addcr(['% Visualize the |' metricName '| metric.']);
                markupCode.addcr('figure');
                % Display show method output
                str = ['show(benchmark,"' metricName '")'];
                markupCode.addcr(str);
                % Display summary table
                markupCode.addcr('%%%');
                markupCode.addcr(['% Display the statistical summary of the |' metricName '| metric.']);
                str = [metricName  ' = metric(benchmark,"' metricName '")'];
                markupCode.addcr(str);
                % Display detailed table only when not excluded by
                % name-value pair Exclude
                if(~any(strcmp(contentExclude, 'DetailedTable')))
                    markupCode.addcr('%%%');
                    markupCode.addcr(['% Display the values of the |' metricName '| metric for each run.']);
                    str = ['[~,' metricName 'Detailed] = metric(benchmark,"' metricName '")'];
                    markupCode.addcr(str);
                end
            end
            % Add the local function plotPath when PathVisualization is not
            % excluded
            if(~any(strcmp(contentExclude, 'PathVisualization')))
                markupCode.addcr('%%%');
                fcnPlotPathStr = obj.generatePlotPathFcnStr();
                markupCode.addcr(fcnPlotPathStr);
            end
        end

    end

    methods(Static, Access=private)

        function displayProgress(msg,verbose)
        %displayProgress display the message if Verbose in 'on'
            if(strcmp(verbose,'on'))
                disp(msg.getString);
            end
        end

        function [nvStartIdx, initFcn] = parseAddPlannerFcnHandles(planFcn, varInput)
        %parseAddPlannerFcnHandles parse and validate the inputs of addPlanner
        % This method returns the name-value pair start index nvStartIdx
        % and optional argument initFcn

            validateattributes(planFcn, {'function_handle'},"scalar",'addPlanner','planFcn',2);
            namePair = {'PlannerName', 'NumPlanOutput'};
            nvStartIdx = 2;
            nargs = numel(varInput);
            initFcn = [];

            if(nargs > 0)
                %find the start index of the name-value pair
                if(any(strcmp(varInput{1},namePair)))
                    nvStartIdx = 1;
                else
                    initFcn = varInput{1};
                    validateattributes(initFcn, {'function_handle'},"scalar",'addPlanner','initFcn',3);
                end
            end
        end

        function plotPathFcnStr = generatePlotPathFcnStr()
        %generatePlotPathFcnStr return plotPath local function which plot path
        % on the map for a given plannerName and corresponding run

            plotPathFcnStr = StringWriter;

            plotPathFcnStr.addcr('%%%');
            plotPathFcnStr.addcr(['%plotPath - The plotPath helper function plots a path ' ...
                                  'generated by a planner ']);
            plotPathFcnStr.addcr('%in the specified environment.');
            plotPathFcnStr.addcr('function plotPath(benchmark,mapHandle,plannerName,run)');
            % Find the path output for plannerName and run
            plotPathFcnStr.addcr('runStr = strcat("Run",num2str(run));');
            plotPathFcnStr.addcr('path = benchmark.PlannerOutput.(plannerName).PlanOutput.(runStr);');
            % Retrieve the path states from planner output
            plotPathFcnStr.addcr('if isa(path{1},"navPath")');
            plotPathFcnStr.addcr('states = path{1}.States;');
            plotPathFcnStr.addcr('else');
            plotPathFcnStr.addcr('states = path{1};');
            plotPathFcnStr.addcr('end');
            plotPathFcnStr.addcr('if ~(isempty(states))');
            plotPathFcnStr.addcr('mapAxis = mapHandle.Parent;');
            % Define the string for legend
            plotPathFcnStr.addcr('displayStr = sprintf("%s Run %d",plannerName,run);');
            % plot the path on the map
            plotPathFcnStr.addcr('plot(mapAxis,states(:,1),states(:,2),"-",DisplayName=displayStr);');
            plotPathFcnStr.addcr('end');
            plotPathFcnStr.addcr('end');

        end

        function matchExcludeContent = validateExcludeContent(excludeContent, validExcludeContent)
        %validateExcludeContent validate the Exclude name-value pair.

            len = length(excludeContent);
            matchExcludeContent = strings(1,len);
            for i=1:length(excludeContent)
                matchExcludeContent(i) = validatestring(excludeContent{i}, validExcludeContent, "report", "Exclude");
            end
        end

        function [absoluteFilePath, fullFileName] = validateAndGetFileDetail(filePath, fcnName, extn)
        %validateAndGetFileDetail validate the file path and return the
        % absolute path and file name with extension.

            if ~isempty(filePath)
                if ~isfolder(filePath)
                    % Throw error when path is not valid.
                    error(message("nav:navalgs:plannerBenchmark:InvalidReportPath"));
                else
                    absoluteFilePath = dir(filePath).folder;
                end
            else
                % if path of file is empty, file is stored in the current
                % working directory
                absoluteFilePath = pwd;
            end
            % Assign extension as "mlx" if not supplied by user
            if(isempty(extn))
                extn = '.mlx';

                % Throw error if user supplied extension other than ".mlx"
            elseif ~strcmp(extn, '.mlx')
                error(message("nav:navalgs:plannerBenchmark:InvalidFileExtension"));
            end

            fileName = [fcnName extn];
            fullFileName = fullfile(absoluteFilePath,fileName);

            [~,attribs] = fileattrib(absoluteFilePath);
            if ~attribs.UserWrite
                error(message('nav:navalgs:plannerBenchmark:PermissionDenied', fullFileName));
            end
        end
    end
end
