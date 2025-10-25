classdef TaskContext < ...
        matlab.buildtool.internal.Loggable & ...
        matlab.buildtool.internal.BuildContent & ...
        matlab.buildtool.internal.qualifications.Assertable

    properties (SetAccess = immutable)
        Task (1,1) matlab.buildtool.Task
        Plan (1,1) matlab.buildtool.Plan = buildplan()
    end

    properties (SetAccess = immutable, Hidden)
        TaskChanges (1,1) matlab.buildtool.fingerprints.TaskChanges
        BuildOptions (1,1) struct
    end
    
    methods (Hidden)
        function context = TaskContext(task, plan, options)
            arguments
                task (1,1) matlab.buildtool.Task
                plan (1,1) matlab.buildtool.Plan
                options.TaskChanges (1,1) matlab.buildtool.fingerprints.TaskChanges
                options.BuildOptions (1,1) struct
            end

            context.Task = task;
            context.Plan = plan;
            
            for prop = string(fieldnames(options))'
                context.(prop) = options.(prop);
            end
        end
    end
end

% Copyright 2022-2024 The MathWorks, Inc.
