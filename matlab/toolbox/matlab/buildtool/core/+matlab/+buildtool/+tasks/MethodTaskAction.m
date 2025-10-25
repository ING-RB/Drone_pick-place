classdef (Hidden) MethodTaskAction < matlab.buildtool.TaskAction
    % MethodTaskAction - Action defined by method
    %
    %   The matlab.buildtool.tasks.MethodTaskAction class defines a method that
    %   executes when a task runs.
    %
    %   The build tool instantiates this class. You cannot create an object of
    %   the class directly.
    %
    %   See also matlab.buildtool.TaskAction

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (Access = private)
        ClassName (1,1) string {mustBeNonmissing}
        MethodName (1,1) string {mustBeNonmissing}
    end

    methods (Hidden)
        function action = MethodTaskAction(className, methodName)
            arguments
                className (1,1) string {mustDeriveFromTask(className)}
                methodName (1,1) string {mustBeNonmissing}
            end

            action.Name = methodName;
            action.ClassName = className;
            action.MethodName = methodName;
        end

        function evaluate(action, context, arg)
            arguments
                action (1,1) matlab.buildtool.tasks.MethodTaskAction
                context (1,1) matlab.buildtool.TaskContext
            end
            arguments (Repeating)
                arg
            end
            
            context.Task.(action.MethodName)(context, arg{:});
        end

        function i = info(action)
            arguments
                action (1,1) matlab.buildtool.tasks.MethodTaskAction
            end

            i = struct();
            i.Function = action.MethodName;
            i.Type = "method";
            i.File = string(which(action.ClassName));
            i.DefiningClass = meta.class.fromName(action.ClassName);
        end
    end
end

function mustDeriveFromTask(className)
mc = meta.class.fromName(className);
if isempty(mc) || ~(mc <= ?matlab.buildtool.Task)
    throwAsCaller(MException(message("MATLAB:buildtool:MethodTaskAction:MustDeriveFromTask")));
end
end
