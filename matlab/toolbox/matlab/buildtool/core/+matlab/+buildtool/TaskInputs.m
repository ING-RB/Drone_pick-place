classdef (Sealed) TaskInputs < ...
        matlab.mixin.Scalar & ...
        matlab.mixin.CustomDisplay & ...
        matlab.mixin.indexing.RedefinesDot & ...
        matlab.mixin.indexing.OverridesPublicDotMethodCall & ...
        matlab.mixin.internal.indexing.DisallowCompletionOfDotMethodNames
    % TaskInputs - Task inputs container
    %
    %   The matlab.buildtool.TaskInputs class is a container for defining and
    %   grouping inputs of a task.
    %
    %   A TaskInputs object behaves like a structure. To add, modify, or return
    %   an input in the container, use dot notation.
    %
    %   - To add or modify an input, use the inputs.InputName = value syntax.
    %
    %   - To return an input, use the value = inputs.InputName syntax.
    %
    %   TaskInputs methods:
    %      TaskInputs - Create task inputs container
    %      inputNames - Names of task inputs
    %
    %   Example:
    %
    %      % Import the Task class.
    %      import matlab.buildtool.Task
    %
    %      % Create a plan with no tasks.
    %      plan = buildplan;
    %
    %      % Add a "mex" task to the plan.
    %      plan("mex") = Task;
    %
    %      % Add a "SourceFiles" input.
    %      plan("mex").Inputs.SourceFiles = files(plan,"explore.c");
    %
    %      % Add a "MexOptions" input.
    %      plan("mex").Inputs.MexOptions = ["-g","-v"];
    %
    %      % Add a "MexFile" output.
    %      plan("mex").Outputs.MexFile = files(plan,"explore."+mexext);
    %
    %      % Add an "ObjectFile" output.
    %      plan("mex").Outputs.ObjectFile = files(plan,"explore.o");
    %
    %      % Add an action to the task.
    %      plan("mex").Actions = @(c)mex(c.Task.Inputs.SourceFiles.paths,c.Task.Inputs.MexOptions{:});
    %
    %      % Run the task.
    %      result = run(plan,"mex");
    %
    %   See also matlab.buildtool.Task, matlab.buildtool.TaskOutputs

    %   Copyright 2023 The MathWorks, Inc.

    properties (Access = private)
        Inputs (1,1) struct
    end

    methods
        function inputs = TaskInputs(name, value)
            % TaskInputs - Create task inputs container
            %
            %   INPUTS = matlab.buildtool.TaskInputs creates a TaskInputs object with
            %   no inputs.
            %
            %   INPUTS = matlab.buildtool.TaskInputs(NAME1,VALUE1,...,NAMEN,VALUEN)
            %   creates a TaskInputs object with the specified input names and values.

            arguments (Repeating)
                name (1,1) string {mustBeValidVariableName}
                value
            end

            for i = 1:numel(name)
                inputs.Inputs.(name{i}) = value{i};
            end
        end

        function names = inputNames(inputs)
            % inputNames - Names of task inputs
            %
            %   inputNames(INPUTS) returns the input names of INPUTS as a string column
            %   vector.
            
            names = string(fieldnames(inputs.Inputs));
        end
    end

    methods (Hidden)
        function p = properties(inputs)
            import matlab.internal.display.lineSpacingCharacter;
            names = fieldnames(inputs.Inputs);
            if nargout == 0
                fprintf(lineSpacingCharacter+"%s\n"+lineSpacingCharacter, string(message("MATLAB:ClassUstring:PROPERTIES_FUNCTION_LABEL",class(inputs))));
                fprintf("    %s\n", names{:});
                fprintf(lineSpacingCharacter);
            else
                p = names;
            end
        end
    end

    methods (Access = protected)
        function varargout = dotReference(inputs, indexOp)
            name = indexOp(1).Name;
            if ~isTextScalar(name)
                error(message("MATLAB:buildtool:TaskInputs:MustBeInputName"));
            end
            if ~isfield(inputs.Inputs, name)
                error(message("MATLAB:buildtool:TaskInputs:UnrecognizedInputName", name));
            end

            [varargout{1:nargout}] = inputs.Inputs.(indexOp);
        end

        function inputs = dotAssign(inputs, indexOp, varargin)
            name = indexOp(1).Name;
            if ~isTextScalar(name)
                error(message("MATLAB:buildtool:TaskInputs:MustBeInputName"));
            end
            if ~isvarname(name)
                error(message("MATLAB:buildtool:TaskInputs:InvalidInputName", name));
            end
            
            [inputs.Inputs.(indexOp)] = varargin{:};
        end

        function n = dotListLength(inputs, indexOp, indexContext)
            n = listLength(inputs.Inputs, indexOp, indexContext);
        end

        function groups = getPropertyGroups(inputs)
            groups = matlab.mixin.util.PropertyGroup(inputs.Inputs);
        end

        function header = getHeader(inputs)
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(inputs);
            if isempty(inputNames(inputs))
                msgId = "MATLAB:buildtool:TaskInputs:ScalarHeaderNoInputs";
            else
                msgId = "MATLAB:buildtool:TaskInputs:ScalarHeader";
            end
            header = sprintf('  %s\n', getString(message(msgId, className)));
        end
    end
end

function tf = isTextScalar(value)
str = convertCharsToStrings(value);
tf = isstring(str) && isscalar(str);
end

% LocalWords:  NAMEN VALUEN buildplan
