classdef QualificationEventData < event.EventData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties(SetAccess = immutable)
        ActualValue (1,1) logical
        TaskDiagnostic (1,:) {mustBeA(TaskDiagnostic, ["char" "string" "function_handle" "matlab.automation.diagnostics.Diagnostic"])} = matlab.automation.diagnostics.Diagnostic.empty(1,0)
    end

    properties(Dependent, SetAccess = immutable)
        FormattableTaskDiagnosticResults
        Stack
    end

    properties (GetAccess = private, SetAccess = immutable)
        RawStack (1,:) struct
    end

    methods (Hidden)
        function evd = QualificationEventData(stack, actual, rawTaskDiag)
            arguments
                stack (1,:) struct {matlab.buildtool.internal.mustHaveField(stack,["file", "name", "line"])}
                actual (1,1) logical
                rawTaskDiag (1,:) {mustBeA(rawTaskDiag, ["char" "string" "function_handle" "matlab.automation.diagnostics.Diagnostic"])} = matlab.automation.diagnostics.Diagnostic.empty(1,0)
            end
            evd.RawStack = stack;
            evd.ActualValue = actual;
            evd.TaskDiagnostic = createTaskDiagnosticFromRawInput(rawTaskDiag);
        end
    end

    methods
        function results = get.FormattableTaskDiagnosticResults(evd)
            import matlab.unittest.internal.diagnostics.FormattableDiagnosticResult
            
            arrayfun(@diagnose, evd.TaskDiagnostic);
            results = arrayfun(@(d)FormattableDiagnosticResult(d.Artifacts, d.FormattableDiagnosticText), evd.TaskDiagnostic);
            results = [results FormattableDiagnosticResult.empty(1,0)];
        end

        function stack = get.Stack(evd)
            import matlab.buildtool.internal.trimStack
            stack = trimStack(evd.RawStack);
        end
    end
end

function taskDiag = createTaskDiagnosticFromRawInput(rawTaskDiag)
if ischar(rawTaskDiag) || isstring(rawTaskDiag)
    taskDiag = StringDiagnostic(rawTaskDiag);
elseif isa(rawTaskDiag, "function_handle")
    taskDiag = FunctionHandleDiagnostic(rawTaskDiag);
else
    taskDiag = rawTaskDiag;
end
end

function d = StringDiagnostic(varargin)
d = matlab.automation.diagnostics.StringDiagnostic(varargin{:});
end

function d = FunctionHandleDiagnostic(varargin)
d = matlab.automation.diagnostics.FunctionHandleDiagnostic(varargin{:});
end