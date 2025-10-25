classdef CleanTask < matlab.buildtool.Task
    % CleanTask - Task to delete outputs and traces
    %
    %   The matlab.buildtool.tasks.CleanTask class provides a task to delete
    %   outputs and traces of tasks that support incremental builds.
    %
    %   CleanTask methods:
    %      CleanTask - Create task to delete outputs
    %
    %   Example:
    %
    %      % --buildfile.m
    %      function plan = buildfile
    %      import matlab.buildtool.tasks.CleanTask
    %
    %      plan = buildplan;
    %      plan("clean") = CleanTask;
    %      end
    %
    %      % Delete the outputs of all tasks
    %      >> buildtool clean
    %
    %      % Delete the outputs of "task1"
    %      >> buildtool clean("task1")
    %
    %      % Delete the outputs of "tasks1", "task2", and "task3"
    %      >> buildtool clean(["task1" "task2" "task3"])

    %   Copyright 2023-2024 The MathWorks, Inc.

    methods
        function task = CleanTask(options)
            % CleanTask - Create task to delete outputs
            %
            %   TASK = matlab.buildtool.tasks.CleanTask creates a CleanTask object
            %   whose properties have their default values.
            %
            %   TASK = matlab.buildtool.tasks.CleanTask(NAME=VALUE) sets properties
            %   using one or more name-value arguments. You can use this syntax to set
            %   the Description and Dependencies properties.

            arguments
                options.Description (1,1) string {mustBeNonmissing} = string(message("MATLAB:buildtool:CleanTask:DefaultDescription"))
                options.Dependencies (1,:) string {mustBeNonmissing} = string.empty()
            end

            task.Description = options.Description;
            task.Dependencies = options.Dependencies;
        end
    end

    methods (TaskAction, Sealed, Hidden)
        function clean(task, context, taskName)
            arguments
                task (1,1) matlab.buildtool.Task
                context (1,1) matlab.buildtool.TaskContext
                taskName (1,:) string = [context.Plan.Tasks.Name]
            end

            import matlab.buildtool.Task;
            import matlab.buildtool.internal.io.absolutePath;
            import matlab.buildtool.internal.findCacheWithContext;
            import matlab.buildtool.internal.fingerprints.PersistentTaskTraceRepository;
            import matlab.buildtool.internal.fingerprints.TaskTrace;

            tasks = collectTasksInSubtree(context.Plan, taskName);

            cacheFolder = findCacheWithContext(context);
            exceptions = MException.empty(1,0);

            repo = PersistentTaskTraceRepository(cacheFolder);

            if nargin < 3
                % >> buildtool clean
                traces = repo.allTraces();
                repo.removeAllTraces();
            else
                % >> buildtool clean(["mytask", "myothertask"])
                traces = TaskTrace.empty(1, 0);

                for t = tasks
                    traces = [traces repo.lookupTrace(t.Name)]; %#ok<AGROW
                    repo.removeTrace(t.Name);
                end
            end

            filesToClean = string.empty(1, 0);
            for t = traces
                fingerprints = [t.ClassOutputFingerprints.values()' t.DynamicOutputFingerprints.values()'];
                for fp = fingerprints
                    filesToClean = [filesToClean, fp.paths()]; %#ok<AGROW>
                end
            end
            
            try
                task.cleanFiles(context, absolutePath(filesToClean));
            catch ex
                exceptions(end+1) = ex;
            end

            for output = tasks.outputList()
                if isa(output.Value, "matlab.buildtool.io.FileCollection")
                    try
                        task.cleanFiles(context, output.Value.absolutePaths());
                    catch ex
                        exceptions(end+1) = ex; %#ok<AGROW>
                    end
                end
            end

            if ~isempty(exceptions)
                ex = MException(message("MATLAB:buildtool:CleanTask:DeleteFailed"));
                for cause = exceptions
                    ex = addCause(ex, cause);
                end
                throw(ex);
            end
        end
    end

    methods (Access=private)
        function cleanFiles(~, context, absPaths)
            arguments
                ~
                context (1,1) matlab.buildtool.TaskContext
                absPaths (1,:) string 
            end

            for p = absPaths
                if isfile(p)
                    delete(p);
                    if ~isfile(p)
                        context.log(string(message("MATLAB:buildtool:CleanTask:DeleteSuccessful", p)));
                    end
                elseif isfolder(p)
                    rmdir(p, "s");
                    context.log(string(message("MATLAB:buildtool:CleanTask:DeleteSuccessful", p)));
                end
            end
        end
    end
end

function tasks = collectTasksInSubtree(plan, taskName)
import matlab.buildtool.Task;
import matlab.buildtool.internal.allSubtasks;            

tasks = Task.empty(1,0);
for n = taskName
    t = plan(n);
    tasks = [tasks t allSubtasks(t)]; %#ok<AGROW>
end
end

% LocalWords:  buildfile buildplan
