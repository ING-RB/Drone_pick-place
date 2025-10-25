classdef (Sealed) Plan < ...
        matlab.mixin.Scalar & ...
        matlab.mixin.CustomDisplay & ...
        matlab.mixin.indexing.RedefinesParen & ...
        matlab.buildtool.internal.PlanExtension

    properties
        DefaultTasks (1,:) string {mustBeNonmissing}
    end

    properties (Dependent, SetAccess = private)
        Tasks (1,:) matlab.buildtool.Task
    end

    properties (SetAccess = immutable)
        RootFolder (1,1) string {mustBeNonmissing}
        Project {mustBeScalarOrEmpty}
    end

    properties (Hidden, SetAccess = private)
        Fixtures (1,:) matlab.buildtool.internal.fixtures.Fixture
    end

    properties (Access = private)
        TaskContainer (1,1) matlab.buildtool.internal.TaskContainer
        Conventions (1,1) dictionary = dictionary(string.empty, matlab.buildtool.conventions.Convention.empty)
    end

    properties (Hidden)
        ImplicitTaskGroups (1,1) logical
    end
    
    methods (Static)
        function plan = load(fileName, options)
            arguments
                fileName (1,1) string = "buildfile.m"
                options.LoadProject (1,1) logical = true
            end
            
            import matlab.buildtool.internal.whichFile;
            import matlab.automation.internal.fileResolver;
            import matlab.buildtool.internal.isFunctionBasedBuildFile;

            % Plan.load(folder) is shorthand for folder/buildfile.m
            if isfolder(fileName)
                fileName = fullfile(fileName, "buildfile.m");
            end
            
            try
                fileName = fileResolver(fileName);
            catch e
                if strcmp(e.identifier, 'MATLAB:automation:io:FileIO:InvalidFile')
                    error(message("MATLAB:buildtool:Plan:BuildFileNotFound", fileName))
                else
                    rethrow(e);
                end
            end

            try 
                parseTree = mtree(fileName, "-file");
            catch
                error(message("MATLAB:buildtool:Plan:NonBuildFile", fileName));
            end

            builtin("_mcheck", fileName);

            [folder,name,ext] = fileparts(fileName);

            if ~isFunctionBasedBuildFile(parseTree) || strcmpi(ext, ".mlx")
                error(message("MATLAB:buildtool:Plan:NonBuildFile", fileName));
            end

            if contains(folder, filesep() + "@")
                error(message("MATLAB:buildtool:Plan:ClassFoldersNotSupported"))
            end
            if contains(folder, filesep() + "+")
                error(message("MATLAB:buildtool:Plan:NamespaceFoldersNotSupported"))
            end
            if endsWith(folder, filesep() + "private")
                error(message("MATLAB:buildtool:Plan:PrivateFoldersNotSupported"))
            end

            currentFolder = pwd();
            restoreFolder = onCleanup(@()cd(currentFolder));

            if options.LoadProject && isfile(which("matlab.buildtool.internal.loadProjectForPlan"))
                matlab.buildtool.internal.loadProjectForPlan(fileparts(fileName));
            end

            cd(folder);

            fschange(fileName);
            locatedFile = whichFile(name);
            if locatedFile ~= fileName
                error(message("MATLAB:buildtool:Plan:FileShadowedByFile", fileName, locatedFile))
            end

            if nargin(name) ~= 0 || nargout(name) ~= 1
                error(message("MATLAB:buildtool:Plan:MustHaveBuildFileSignature"));
            end

            [inFAV,outFAV] = builtin("_get_function_metadata", char(name));
            if ~isempty(inFAV) || ~isempty(outFAV)
                error(message("MATLAB:buildtool:Plan:FunctionArgumentValidationNotSupported"));
            end

            plan = feval(name);
            if ~isa(plan, "matlab.buildtool.Plan")
                error(message("MATLAB:buildtool:Plan:NonBuildFile", fileName));
            end
        end
    end

    methods
        function tasks = get.Tasks(plan)
            tasks = plan.TaskContainer.Tasks;
        end
    end

    methods (Hidden)
        function tf = isTask(plan, name)
            arguments
                plan (1,1) matlab.buildtool.Plan
                name string
            end
            tf = plan.TaskContainer.isTask(name);
        end

        function task = lookupTask(plan, name)
            arguments
                plan (1,1) matlab.buildtool.Plan
                name string
            end
            task = plan.TaskContainer.lookupTask(name);
        end
        
        function plan = insertTask(plan, name, task, options)
            arguments
                plan (1,1) matlab.buildtool.Plan
                name string
                task matlab.buildtool.Task
                options.Overwrite (1,1) logical = false
            end
            plan.TaskContainer = plan.TaskContainer.insertTask(name, task, ...
                ImplicitTaskGroups=plan.ImplicitTaskGroups, ...
                Overwrite=options.Overwrite);
        end

        function plan = addFixture(plan, fixture)
            arguments
                plan (1,1) matlab.buildtool.Plan
                fixture (1,:) matlab.buildtool.internal.fixtures.Fixture
            end
            plan.Fixtures = [fixture plan.Fixtures];
        end

        function plan = applyConvention(plan, convention)
            arguments
                plan (1,1) matlab.buildtool.Plan
                convention (1,:) {mustBeConventionOrString}
            end
            convention = convertCharsToStrings(convention);
            strict = true;
            if isa(convention, "string")
                strict = false;
                convention = arrayfun(@lookupConventionByName, convention, UniformOutput=false);
                convention = [matlab.buildtool.conventions.Convention.empty, convention{:}];
            end
            for c = convention
                className = class(c);
                if isKey(plan.Conventions, className)
                    % error if a convention is provided as a class with
                    % conflicting property values
                    if strict && ~isequal(c, plan.Conventions(className))
                        error(message("MATLAB:buildtool:Convention:ConfigurationConflict", className));
                    end
                else 
                    plan = c.apply(plan);
                    plan.Conventions(className) = c;
                end
            end
        end
    end

    methods (Hidden, Static)
        function plan = withRootFolder(folder, options)
            arguments
                folder (1,1) string
                options.TaskContainer (1,1) matlab.buildtool.internal.TaskContainer = matlab.buildtool.internal.TaskContainer()
                options.ImplicitTaskGroups (1,1) logical = false
            end
            plan = matlab.buildtool.Plan( ...
                RootFolder=folder, ...
                TaskContainer=options.TaskContainer, ...
                ImplicitTaskGroups=options.ImplicitTaskGroups);
        end
    end
    
    methods (Hidden, Access = protected)
        function varargout = parenReference(plan, indexOp)
            validateIndices(indexOp(1).Indices);

            try
                name = string(indexOp(1).Indices{1});
            catch ex
                exception = MException(message("MATLAB:buildtool:Plan:UnableToIndex", class(indexOp(1).Indices{1})));
                exception = addCause(exception, ex);
                throw(exception);
            end

            try
                if isscalar(indexOp)
                    nargoutchk(0, 1);
                    varargout{1} = plan.lookupTask(name);
                else
                    [varargout{1:nargout}] = plan.lookupTask(name).(indexOp(2:end));
                end
            catch ex
                throw(ex);
            end
        end

        function plan = parenAssign(plan, indexOp, varargin)
            validateIndices(indexOp(1).Indices);

            try
                name = string(indexOp(1).Indices{1});
            catch ex
                exception = MException(message("MATLAB:buildtool:Plan:UnableToIndex", class(indexOp(1).Indices{1})));
                exception = addCause(exception, ex);
                throw(exception);
            end

            try
                if isscalar(indexOp)
                    narginchk(3, 3);
                    task = varargin{1};
                    if ~isa(task, "matlab.buildtool.Task")
                        error(message("MATLAB:buildtool:Plan:ValueMustBeTask"));
                    end
                    plan = plan.insertTask(name, task);
                else
                    task = plan.lookupTask(name);
                    [task.(indexOp(2:end))] = varargin{:};
                    plan = plan.insertTask(name, task, Overwrite=true);
                end
            catch ex
                throw(ex);
            end
        end

        function n = parenListLength(plan, indexOp, indexingContext)
            validateIndices(indexOp(1).Indices);

            if numel(indexOp) <= 2
                n = numel(convertCharsToStrings(indexOp(1).Indices{1}));
            else
                n = listLength(plan.(indexOp(1:end-1)), indexOp(end), indexingContext);
            end
        end

        function displayScalarObject(plan)
            import matlab.buildtool.internal.displayTasks;
            fprintf("%s", plan.getHeader());
            if ~isempty(plan.Tasks)
                fprintf("\n");
                displayTasks(plan.Tasks, Indent=4);
            end
            footer = plan.getFooter(inputname(1));
            if ~isempty(footer)
                fprintf("\n%s", footer);
            end
            if strcmp(settings().matlab.commandwindow.DisplayLineSpacing.ActiveValue, "loose")
                fprintf("\n");
            end
        end
        
        function header = getHeader(plan)
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(plan);
            if isempty(plan.Tasks)
                msgId = "MATLAB:buildtool:Plan:ScalarHeaderNoTasks";
            else
                msgId = "MATLAB:buildtool:Plan:ScalarHeader";
            end
            header = sprintf('  %s\n', getString(message(msgId, className)));
        end

        function footer = getFooter(plan, varname)
            if nargin < 2
                varname = inputname(1);
            end
            if any(arrayfun(@isTaskGroup, plan.Tasks))
                allTasksLink = sprintf([ ...
                    '<a href ="matlab:' ...
                    'if exist(''%s'',''var''),' ...
                    'matlab.buildtool.internal.displayTasksForPlanVariable(''%s'',%s),' ...
                    'else,' ...
                    'matlab.buildtool.internal.displayTasksForPlanVariable(''%s''),' ...
                    'end' ...
                    '">%s</a>'], ...
                    varname, varname, varname, varname, getString(message("MATLAB:buildtool:Plan:AllTasks")));
                footer = sprintf('  %s\n', getString(message("MATLAB:buildtool:Plan:Show", allTasksLink)));
            else
                footer = '';
            end
        end
    end

    methods (Access = private)
        function plan = Plan(options)
            arguments
                options.RootFolder (1,1) string {mustBeNonmissing} = pwd()
                options.TaskContainer (1,1) matlab.buildtool.internal.TaskContainer = matlab.buildtool.internal.TaskContainer()
                options.ImplicitTaskGroups (1,1) logical = false
            end
            
            import matlab.buildtool.internal.io.absolutePath;
            
            plan.RootFolder = absolutePath(options.RootFolder);
            plan.TaskContainer = options.TaskContainer;
            plan.ImplicitTaskGroups = options.ImplicitTaskGroups;

            if isfile(which("matlab.buildtool.internal.getProjectForPlan"))
                plan.Project = matlab.buildtool.internal.getProjectForPlan(plan.RootFolder);
            end
        end
    end
end

function convention = lookupConventionByName(name)
namespace = matlab.metadata.Namespace.fromName("matlab.buildtool.conventions");
classes = namespace.ClassList;
classes = classes(classes < ?matlab.buildtool.conventions.Named);
for c = classes'
    props = c.PropertyList;
    idx = string({props.Name}) == "Name";
    if strcmpi(props(idx).DefaultValue, name)
        convention = feval(c.Name);
        return;
    end
end
error(message("MATLAB:buildtool:Convention:NameNotFound", name));
end

function validateIndices(indices)
if numel(indices) ~= 1
    throwAsCaller(MException(message("MATLAB:buildtool:Plan:IndicesMustBeOneDimensional")));
end
end

function tf = isTaskGroup(obj)
tf = isa(obj, "matlab.buildtool.TaskGroup");
end

function mustBeConventionOrString(obj)
obj = convertCharsToStrings(obj);
if ~isa(obj, "string") && ~isa(obj, "matlab.buildtool.conventions.Convention")
    throwAsCaller(MException(message("MATLAB:buildtool:Plan:MustBeConventionOrString")));
end
end

% Copyright 2021-2024 The MathWorks, Inc.

% LocalWords:  buildfile mcheck mlx
