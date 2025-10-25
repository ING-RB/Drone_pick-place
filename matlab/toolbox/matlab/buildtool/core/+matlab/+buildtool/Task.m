classdef Task < ...
        matlab.mixin.Heterogeneous & ...
        matlab.buildtool.internal.TaskAttributable
    
    properties
        Description (1,1) string {mustBeNonmissing}
        Dependencies (1,:) string {mustBeNonmissing}
        Actions (1,:) matlab.buildtool.TaskAction
        Inputs {mustBeTaskInputsOrFileCollection} = matlab.buildtool.TaskInputs()
        Outputs {mustBeTaskOutputsOrFileCollection} = matlab.buildtool.TaskOutputs()
        DisableIncremental (1,1) logical = false
    end

    properties (Hidden)
        PreferredPredecessors (1,:) string {mustBeNonmissing}
        EssentialPredecessors (1,:) string {mustBeNonmissing}
    end

    properties (Hidden, Dependent, SetAccess = private)
        InferredDependencies (1,:) string {mustBeNonmissing}
    end

    methods
        function task = Task(options)
            arguments
                options.?matlab.buildtool.Task
            end

            taskAction = task.classTaskAction();
            if ~isempty(taskAction)
                task.Actions = taskAction;
            end

            for prop = string(fieldnames(options))'
                task.(prop) = options.(prop);
            end
        end

        function task = set.Actions(task, actions)
            task.validateActions(actions);
            
            taskAction = task.classTaskAction();
            if ~isempty(taskAction) && ~any(arrayfun(@(a)isequal(a,taskAction),actions))
                error(message("MATLAB:buildtool:Task:MustHaveClassTaskAction", taskAction.Name));
            end

            task.Actions = actions;
        end

        function task = set.Inputs(task, inputs)
            task.validateInputs(inputs);

            if isTaskInputs(inputs)
                task.Inputs = inputs;
            else
                task.Inputs = fileCollection(inputs);
            end
        end

        function task = set.Outputs(task, outputs)
            task.validateOutputs(outputs);

            if isTaskOutputs(outputs)
                task.Outputs = outputs;
            else
                task.Outputs = fileCollection(outputs);
            end
        end

        function outputs = get.Outputs(task)
            outputs = task.Outputs;
            if isTaskOutputs(outputs)
                for name = outputNames(outputs)'
                    [outputs.(name).BuildingTask] = deal(task.Name);
                end
            else
                [outputs.BuildingTask] = deal(task.Name);
            end
        end

        function deps = get.InferredDependencies(task)
            import matlab.buildtool.io.Buildable;
            
            deps = string.empty();
            for input = task.inputList()
                if isa(input.Value, "matlab.buildtool.io.Buildable")
                    deps = [deps input.Value.BuildingTask]; %#ok<AGROW>
                end
            end
            
            deps(strcmp(deps,"")) = [];
            deps = unique([deps string.empty(1,0)]);
        end
    end

    methods (Hidden)
        function tf = isMatch(task, other)
            arguments
                task (1,1) matlab.buildtool.Task %#ok<INUSA>
                other (1,1) matlab.buildtool.Task %#ok<INUSA>
            end
            tf = true;
        end

        function tf = supportsIncremental(task) %#ok<MANU>
            tf = true;
        end
    end

    methods (Sealed, Hidden)
        function list = inputList(task)
            list = inputStruct(cell(1,0));
            for t = task(:)'
                list = [list t.elementInputList()]; %#ok<AGROW>
            end
        end

        function list = outputList(task)
            list = outputStruct(cell(1,0));
            for t = task(:)'
                list = [list t.elementOutputList()]; %#ok<AGROW>
            end
        end
    end

    methods (Access = protected)
        function validateActions(task, actions) %#ok<INUSD>
        end

        function validateInputs(task, inputs) %#ok<INUSD>
        end

        function validateOutputs(task, outputs) %#ok<INUSD>
        end
    end

    methods (Access = private)
        function action = classTaskAction(task)
            arguments (Output)
                action {mustBeScalarOrEmpty}
            end

            import matlab.buildtool.tasks.MethodTaskAction;

            taskClass = metaclass(task);
            actionMethod = taskClass.MethodList.findobj("TaskAction", true);

            action = arrayfun(@(m)MethodTaskAction(taskClass.Name, m.Name), actionMethod);
            action = [action MethodTaskAction.empty(1,0)];
        end

        function list = elementInputList(task)
            arguments
                task (1,1) matlab.buildtool.Task
            end

            taskClass = metaclass(task);
            inputProps = taskClass.PropertyList.findobj("TaskInput", true);
            classInputList = arrayfun(@(p)inputStruct(string(p.Name),task.(p.Name),false), inputProps');
            
            inputs = task.Inputs;
            if isTaskInputs(inputs)
                dynamicInputList = arrayfun(@(n)inputStruct(n,inputs.(n),true), inputNames(inputs)');
            else
                dynamicInputList = inputStruct("", inputs, true);
            end

            list = [classInputList dynamicInputList inputStruct(cell(1,0))];
        end

        function list = elementOutputList(task)
            arguments
                task (1,1) matlab.buildtool.Task
            end

            taskClass = metaclass(task);
            outputProps = taskClass.PropertyList.findobj("TaskOutput", true);
            classOutputList = arrayfun(@(p)outputStruct(string(p.Name),task.(p.Name),false), outputProps');
            
            outputs = task.Outputs;
            if isTaskOutputs(outputs)
                dynamicOutputList = arrayfun(@(n)outputStruct(n,outputs.(n),true), outputNames(outputs)');
            else
                dynamicOutputList = outputStruct("", outputs, true);
            end

            list = [classOutputList dynamicOutputList outputStruct(cell(1,0))];
        end
    end
end

function mustBeTaskInputsOrFileCollection(value)
if ~isTaskInputs(value) && ~isConvertibleToFileCollection(value)
    throwAsCaller(MException(message("MATLAB:buildtool:Task:MustBeTaskInputsOrFileCollection")));
end
end

function mustBeTaskOutputsOrFileCollection(value)
if ~isTaskOutputs(value) && ~isConvertibleToFileCollection(value)
    throwAsCaller(MException(message("MATLAB:buildtool:Task:MustBeTaskOutputsOrFileCollection")));
end
end

function tf = isTaskInputs(value)
tf = isa(value, "matlab.buildtool.TaskInputs");
end

function tf = isTaskOutputs(value)
tf = isa(value, "matlab.buildtool.TaskOutputs");
end

function s = inputStruct(name, value, dynamic)
if nargin == 1
    value = [];
    dynamic = false;
end
s = struct("Name", name, "Value", {value}, "Dynamic", dynamic);
end

function s = outputStruct(name, value, dynamic)
if nargin == 1
    value = [];
    dynamic = false;
end
s = struct("Name", name, "Value", {value}, "Dynamic", dynamic);
end

function tf = isConvertibleToFileCollection(value)
try
    fileCollection(value);
    tf = true;
catch
    tf = false;
end
end

function f = fileCollection(f)
arguments
    f (1,:) matlab.buildtool.io.FileCollection
end
end

% Copyright 2021-2024 The MathWorks, Inc.
