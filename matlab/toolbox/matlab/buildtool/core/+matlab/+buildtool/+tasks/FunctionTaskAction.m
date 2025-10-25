classdef (Hidden) FunctionTaskAction < matlab.buildtool.TaskAction
    % FunctionTaskAction - Action defined by function
    %
    %   The matlab.buildtool.tasks.FunctionTaskAction class defines a function
    %   that executes when a task runs.
    %
    %   The build tool instantiates this class. You cannot create an object of
    %   the class directly.
    %
    %   See also matlab.buildtool.TaskAction

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (Access = private)
        FunctionHandle function_handle {mustBeScalarOrEmpty}
    end
    
    methods (Hidden)
        function action = FunctionTaskAction(functionHandle)
            arguments
                functionHandle {mustBeFunctionHandles}
            end

            import matlab.buildtool.tasks.FunctionTaskAction;

            if isempty(functionHandle)
                action = FunctionTaskAction.empty();
                return;
            end

            if ~iscell(functionHandle)
                action.FunctionHandle = functionHandle;
                action.Name = func2str(functionHandle);
                return;
            end

            % Construct object array
            action = cellfun(@FunctionTaskAction, functionHandle);
            action = reshape(action, size(functionHandle));
        end

        function evaluate(action, context, arg)
            arguments
                action (1,1) matlab.buildtool.tasks.FunctionTaskAction
                context (1,1) matlab.buildtool.TaskContext
            end
            arguments (Repeating)
                arg
            end
            
            action.FunctionHandle(context, arg{:});
        end

        function i = info(action)
            arguments
                action (1,1) matlab.buildtool.tasks.FunctionTaskAction
            end

            funcInfo = functions(action.FunctionHandle);

            i = struct();
            i.Function = string(funcInfo.function);
            i.Type = string(funcInfo.type);
            i.File = string(funcInfo.file);
            
            if isfield(funcInfo, "workspace")
                i.Workspace = funcInfo.workspace;
            end
        end
    end
end

function mustBeFunctionHandles(value)
if ~iscell(value)
    value = {value};
end
for i = numel(value)
    if ~isa(value{i}, "function_handle")
        throwAsCaller(MException(message("MATLAB:buildtool:TaskAction:MustBeFunctionHandles")));
    end
end
end

