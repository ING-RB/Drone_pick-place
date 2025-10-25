classdef TaskContainer
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        Tasks (1,:) matlab.buildtool.Task
    end

    properties (Access = private)
        TaskDictionary (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.Task.empty())
    end
    
    methods
        function tasks = get.Tasks(container)
            tasks = container.TaskDictionary.values()';
        end
    end

    methods
        function tf = isTask(container, name)
            arguments
                container (1,1) matlab.buildtool.internal.TaskContainer
                name string
            end

            tf = false(size(name));
            for i = 1:numel(name)
                segments = split(name(i), ":");
                if isscalar(segments)
                    tf(i) = container.TaskDictionary.isKey(segments);
                else
                    tf(i) = container.TaskDictionary.isKey(segments(1)) ...
                        && isTaskGroup(container.TaskDictionary(segments(1))) ...
                        && container.TaskDictionary(segments(1)).isTask(join(segments(2:end),":"));
                end
            end
        end

        function task = lookupTask(container, name)
            arguments
                container (1,1) matlab.buildtool.internal.TaskContainer
                name string
            end

            tf = container.isTask(name);
            if ~all(tf)
                name = fillmissing(name, "constant", "<missing>");
                error(message("MATLAB:buildtool:TaskContainer:TaskNotFound", name(find(~tf,1))));
            end
            
            task = matlab.buildtool.Task.empty();
            for i = 1:numel(name)
                segments = split(name(i), ":");
                if isscalar(segments)
                    task(i) = container.TaskDictionary(segments);
                else
                    task(i) = container.TaskDictionary(segments(1)).lookupTask(join(segments(2:end),":"));
                end
            end
            task = reshape(task, size(name));
        end

        function container = insertTask(container, name, task, options)
            arguments
                container (1,1) matlab.buildtool.internal.TaskContainer
                name string
                task matlab.buildtool.Task
                options.Overwrite (1,1) logical = false
                options.ImplicitTaskGroups (1,1) logical = false
            end

            import matlab.buildtool.TaskGroup;
            import matlab.buildtool.internal.mustBeValidTaskName;

            if isscalar(name) && ~isscalar(task) && options.ImplicitTaskGroups
                task = TaskGroup(task);
            end
            if isscalar(task) && ~isscalar(name)
                task = repmat(task, size(name));
            end
            if ~isequal(size(name),size(task))
                error(message("MATLAB:buildtool:TaskContainer:NameTaskDimsMustMatch"));
            end

            % Remove duplicates
            d = dictionary(name, task);
            name = d.keys();
            task = d.values();

            taskExists = container.isTask(name);
            mustBeValidTaskName(name(~taskExists));

            if ~options.Overwrite
                if any(taskExists)
                    error(message("MATLAB:buildtool:TaskContainer:TaskAlreadyExists", name(find(taskExists,1))));
                end
            end

            for i = 1:numel(name)
                segments = split(name(i), ":");
                if isscalar(segments)
                    task(i).Name = segments;
                    container.TaskDictionary(segments) = task(i);
                else
                    group = container.TaskDictionary.lookup(segments(1), FallbackValue=TaskGroup());
                    if ~isTaskGroup(group)
                        if options.Overwrite
                            group = TaskGroup();
                        else
                            error(message("MATLAB:buildtool:TaskContainer:NonGroupParent"));
                        end
                    end
                    group.Name = segments(1);
                    container.TaskDictionary(segments(1)) = group.insertTask(join(segments(2:end),":"), task(i), Overwrite=options.Overwrite);
                end
            end
        end
    end
end

function tf = isTaskGroup(obj)
tf = isa(obj, "matlab.buildtool.TaskGroup");
end
