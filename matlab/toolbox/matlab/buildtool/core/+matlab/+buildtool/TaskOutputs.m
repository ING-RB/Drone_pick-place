classdef (Sealed) TaskOutputs < ...
        matlab.mixin.Scalar & ...
        matlab.mixin.CustomDisplay & ...
        matlab.mixin.indexing.RedefinesDot & ...
        matlab.mixin.indexing.OverridesPublicDotMethodCall & ...
        matlab.mixin.internal.indexing.DisallowCompletionOfDotMethodNames
    % TaskOutputs - Task outputs container
    %
    %   The matlab.buildtool.TaskOutputs class is a container for defining and
    %   grouping outputs of a task.
    %
    %   A TaskOutputs object behaves like a structure. To add, modify, or return
    %   an output in the container, use dot notation.
    %
    %   - To add or modify an output, use the outputs.OutputName = value syntax.
    %
    %   - To return an output, use the value = outputs.OutputName syntax.
    %
    %   TaskOutputs methods:
    %      TaskOutputs - Create task outputs container
    %      outputNames - Names of task outputs
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
    %   See also matlab.buildtool.Task, matlab.buildtool.TaskInputs

    %   Copyright 2023 The MathWorks, Inc.

    properties (Access = private)
        Outputs (1,1) struct
    end

    methods
        function outputs = TaskOutputs(name, value)
            % TaskOutputs - Create task outputs container
            %
            %   OUTPUTS = matlab.buildtool.TaskOutputs creates a TaskOutputs object
            %   with no outputs.
            %
            %   OUTPUTS = matlab.buildtool.TaskOutputs(NAME1,VALUE1,...,NAMEN,VALUEN)
            %   creates a TaskOutputs object with the specified output names and values.

            arguments (Repeating)
                name (1,1) string {mustBeValidVariableName}
                value {mustBeBuildable}
            end

            for i = 1:numel(name)
                outputs.Outputs.(name{i}) = value{i};
            end
        end

        function names = outputNames(outputs)
            % outputNames - Names of task outputs
            %
            %   outputNames(OUTPUTS) returns the output names of OUTPUTS as a string
            %   column vector.
            
            names = string(fieldnames(outputs.Outputs));
        end
    end

    methods (Hidden)
        function p = properties(outputs)
            import matlab.internal.display.lineSpacingCharacter;
            names = fieldnames(outputs.Outputs);
            if nargout == 0
                fprintf(lineSpacingCharacter+"%s\n"+lineSpacingCharacter, string(message("MATLAB:ClassUstring:PROPERTIES_FUNCTION_LABEL",class(outputs))));
                fprintf("    %s\n", names{:});
                fprintf(lineSpacingCharacter);
            else
                p = names;
            end
        end
    end

    methods (Access = protected)
        function varargout = dotReference(outputs, indexOp)
            name = indexOp(1).Name;
            if ~isTextScalar(name)
                error(message("MATLAB:buildtool:TaskOutputs:MustBeOutputName"));
            end
            if ~isfield(outputs.Outputs, name)
                error(message("MATLAB:buildtool:TaskOutputs:UnrecognizedOutputName", name));
            end

            [varargout{1:nargout}] = outputs.Outputs.(indexOp);
        end

        function outputs = dotAssign(outputs, indexOp, varargin)
            name = indexOp(1).Name;
            if ~isTextScalar(name)
                error(message("MATLAB:buildtool:TaskOutputs:MustBeOutputName"));
            end
            if ~isvarname(name)
                error(message("MATLAB:buildtool:TaskOutputs:InvalidOutputName", name));
            end

            [outputs.Outputs.(indexOp)] = varargin{:};

            mustBeBuildable(outputs.Outputs.(name));
        end

        function n = dotListLength(outputs, indexOp, indexContext)
            n = listLength(outputs.Outputs, indexOp, indexContext);
        end

        function groups = getPropertyGroups(outputs)
            groups = matlab.mixin.util.PropertyGroup(outputs.Outputs);
        end

        function header = getHeader(outputs)
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(outputs);
            if isempty(outputNames(outputs))
                msgId = "MATLAB:buildtool:TaskOutputs:ScalarHeaderNoOutputs";
            else
                msgId = "MATLAB:buildtool:TaskOutputs:ScalarHeader";
            end
            header = sprintf('  %s\n', getString(message(msgId, className)));
        end
    end
end

function tf = isTextScalar(value)
str = convertCharsToStrings(value);
tf = isstring(str) && isscalar(str);
end

function mustBeBuildable(value)
if ~isa(value, "matlab.buildtool.io.Buildable")
    throwAsCaller(MException(message("MATLAB:buildtool:TaskOutputs:ValueMustBeBuildable")));
end
end

% LocalWords:  NAMEN VALUEN buildplan
