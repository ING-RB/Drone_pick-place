classdef (Hidden) Assertable < ...
        matlab.mixin.Copyable & ...
        matlab.buildtool.internal.qualifications.PostFailureCallbackProvider
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    events (NotifyAccess = private)
        % AssertionFailed - Event triggered upon a failing assertion.
        %   The AssertionFailed event provides a means to observe and react to
        %   failing assertions.
        AssertionFailed
    end

    properties(Access = private)
        AssertionDelegate
    end

    methods(Sealed, Hidden)
        function assertTrue(assertable, condition, diag)
            % assertTrue - Assert condition is true
            %
            %   assertTrue(CONTEXT,CONDITION) asserts that CONDITION is
            %   true given the CONTEXT provided when a task runs. CONTEXT
            %   must be a matlab.buildtool.TaskContext object, which
            %   contains information about the task as well as the plan
            %   being run. CONDITION must be a scalar value of type logical
            %   or be convertible to logical. You can specify CONDITION as
            %   an expression that evaluates to a logical scalar.
            %
            %   assertTrue(CONTEXT,CONDITION,DIAGNOSTIC) also associates
            %   the diagnostic information in DIAGNOSTIC with the
            %   assertion. You can specify DIAGNOSTIC as a string array,
            %   character array, function handle or an array of
            %   matlab.automation.diagnostics.Diagnostic objects.
            %
            %   Examples:
            %
            %       % Assert that a condition is true
            %       str = ["Mary Ann Jones" "Paul Jay Burns"];
            %       pat = "Paul";
            %       context.assertTrue(any(contains(str,pat)))
            %
            %       % Assert using a textual diagnostic
            %       str = "data-analysis.txt";
            %       pat = "data";
            %       context.assertTrue(startsWith(str,pat), ...
            %                          "String must start with 'data'.")
            %
            %       % Assert using a matlab.automation.diagnostics.Diagnostic object
            %       import matlab.automation.diagnostics.FunctionHandleDiagnostic
            %
            %       context.assertTrue(isfolder("myfolder"), ...
            %                          FunctionHandleDiagnostic(@dir))
            %
            %   See also
            %       matlab.automation.diagnostics.Diagnostic

            arguments
                assertable (1,1) matlab.buildtool.internal.qualifications.Assertable
                condition (1,1) logical
                diag (1,:) {mustBeA(diag, ["char" "string" "function_handle" "matlab.automation.diagnostics.Diagnostic"])} = matlab.automation.diagnostics.Diagnostic.empty(1,0)
            end

            qualifyTrue(assertable.AssertionDelegate, ...
                assertable.getNotificationData(), ...
                condition, ...
                diag);
        end
    end

    methods (Access = private)
        function notificationData = getNotificationData(assertable)
            notificationData = struct( ...
                "NotifyFailed",@(evd)assertable.notify("AssertionFailed", evd),...
                "Qualifiable",assertable);
        end
    end

    methods(Hidden, Access = protected)
        function assertable = Assertable(delegate)
            arguments
                delegate (1,1) matlab.buildtool.internal.qualifications.AssertionDelegate = matlab.buildtool.internal.qualifications.AssertionDelegate;
            end
            assertable.AssertionDelegate = delegate;
        end
    end
end