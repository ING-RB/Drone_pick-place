classdef (Sealed) TaskGroup < matlab.buildtool.Task
    % TaskGroup - Group of tasks
    %
    %   The matlab.buildtool.TaskGroup class represents a collection of tasks
    %   that may be treated as a single unit in a plan.
    %
    %   Create a TaskGroup instance in two different ways:
    %
    %   - Add a task to a plan with a task name containing a colon. For
    %   example, plan("groupName:taskName") = Task adds a group named
    %   "groupName" with a subtask named "groupName:taskName" to the plan.
    %
    %   - Use the TaskGroup constructor.
    %
    %   The name of subtasks in a group starts with the group name, followed by
    %   a colon, followed by the subtask name. For example, "mygroup:mytask".
    %
    %   TaskGroup properties:
    %      Tasks - Subtasks of group
    %
    %   Example:
    %
    %      % Import the MexTask class.
    %      import matlab.buildtool.tasks.MexTask
    %
    %      % Create a plan with no tasks.
    %      plan = buildplan;
    %
    %      % Add a group named "mex" with two subtasks.
    %      plan("mex:explore") = MexTask("explore.c","out");
    %      plan("mex:yprime") = MexTask("yprime.c","out");
    %
    %      % Run the subtasks in the "mex" group.
    %      run(plan,"mex");
    %
    %      % Run the "mex:yprime" subtask.
    %      run(plan,"mex:yprime");
    %
    %   See also matlab.buildtool.Plan, matlab.buildtool.tasks.MexTask

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        % Tasks - Subtasks of group
        %
        %   Subtasks of the group, returned as a row vector of
        %   matlab.buildtool.Task objects.
        Tasks (1,:) matlab.buildtool.Task
    end

    properties (Access = private)
        TaskContainer (1,1) matlab.buildtool.internal.TaskContainer
    end

    methods
        function group = TaskGroup(tasks, options)
            % TaskGroup - Create task group
            %
            %   G = matlab.buildtool.TaskGroup creates a TaskGroup object with no
            %   subtasks.
            %
            %   G = matlab.buildtool.TaskGroup(TASKS) creates a TaskGroup object with
            %   the specified subtasks. The constructor creates subtask names as
            %   'task1',...,'taskN', where N is the number of subtasks.
            %
            %   G = matlab.buildtool.TaskGroup(TASKS,TaskNames=NAMES) creates a
            %   TaskGroup object with the specified subtask names. NAMES and TASKS must
            %   be the same size or TASKS must contain a single task. The specified
            %   subtask names are appended, with a colon, to the name of the group.
            %
            %   G = matlab.buildtool.TaskGroup(...,NAME=VALUE) sets the Description and
            %   Dependencies properties, which the class inherits from the
            %   matlab.buildtool.Task class, using one or more name-value arguments.
            %
            %   Example:
            %   
            %      % Import the classes used in this example.
            %      import matlab.buildtool.TaskGroup
            %      import matlab.buildtool.tasks.MexTask
            %
            %      % Create a plan with no tasks.
            %      plan = buildplan;
            %
            %      % Add a group named "mex" with two subtasks.
            %      tasks = [MexTask("explore.c","out"), MexTask("yprime.c","out")];
            %      plan("mex") = TaskGroup(tasks, ...
            %          TaskNames=["explore","yprime"]);
            %      
            %      % Run the subtasks in the "mex" group.
            %      run(plan,"mex");
            %
            %   See also matlab.buildtool.Plan, matlab.buildtool.tasks.MexTask

            arguments
                tasks matlab.buildtool.Task = matlab.buildtool.Task.empty()
                options.TaskNames string {mustBeValidTaskName, mustBeEqualSizeOrScalar(tasks,options.TaskNames)} = reshape("task"+(1:numel(tasks)),size(tasks))
                options.TaskContainer (1,1) matlab.buildtool.internal.TaskContainer = matlab.buildtool.internal.TaskContainer()
                options.Description (1,1) string {mustBeNonmissing}
                options.Dependencies (1,:) string {mustBeNonmissing}
            end

            group.TaskContainer = options.TaskContainer;

            group = group.insertTask(options.TaskNames, tasks);

            options = rmfield(options, ["TaskContainer","TaskNames"]);
            for prop = string(fieldnames(options))'
                group.(prop) = options.(prop);
            end
        end

        function tasks = get.Tasks(group)
            tasks = group.TaskContainer.Tasks;
            tasks = group.prependGroupName(tasks);
        end
    end
    
    methods (Hidden)
        function tf = isTask(group, name)
            arguments
                group (1,1) matlab.buildtool.TaskGroup
                name string
            end
            tf = group.TaskContainer.isTask(name);
        end

        function task = lookupTask(group, name)
            arguments
                group (1,1) matlab.buildtool.TaskGroup
                name string
            end
            task = group.TaskContainer.lookupTask(name);
            task = group.prependGroupName(task);
        end

        function group = insertTask(group, name, task, options)
            arguments
                group (1,1) matlab.buildtool.TaskGroup
                name string
                task matlab.buildtool.Task
                options.Overwrite (1,1) logical = false
            end
            group.TaskContainer = group.TaskContainer.insertTask(name, task, Overwrite=options.Overwrite);
        end

        function tf = isMatch(task, other)
            arguments
                task (1,1) matlab.buildtool.Task
                other (1,1) matlab.buildtool.Task
            end
            if isa(other, "matlab.buildtool.TaskGroup")
                match = false(size(other.Tasks));
                for i = 1:numel(other.Tasks)
                    match(i) = any(arrayfun(@(t)t.isMatch(other.Tasks(i)),task.Tasks));
                end
                tf = all(match);
            else
                tf = all(arrayfun(@(t)t.isMatch(other),task.Tasks));
            end
        end
    end

    methods (Access = protected)
        function validateActions(task, actions) %#ok<INUSD>
            error(message("MATLAB:buildtool:TaskGroup:ActionsNotSupported"));
        end

        function validateInputs(task, inputs) %#ok<INUSD>
            error(message("MATLAB:buildtool:TaskGroup:InputsNotSupported"));
        end

        function validateOutputs(task, outputs) %#ok<INUSD>
            error(message("MATLAB:buildtool:TaskGroup:OutputsNotSupported"));
        end
    end

    methods (Access = private)
        function tasks = prependGroupName(group, tasks)
            if group.Name == ""
                return;
            end
            names = group.Name+":"+[tasks.Name];
            [tasks.Name] = deal(names{:});
        end
    end
end

function mustBeValidTaskName(name)
matlab.buildtool.internal.mustBeValidTaskName(name);
end

function mustBeEqualSizeOrScalar(tasks, names)
if ~isscalar(tasks) && ~isequal(size(tasks), size(names))
    error(message("MATLAB:buildtool:TaskContainer:NameTaskDimsMustMatch"));
end
end
