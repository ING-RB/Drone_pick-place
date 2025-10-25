classdef (Hidden) TaskChangeDiagnostic < matlab.automation.diagnostics.Diagnostic
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Property (1,1) string
    end

    properties (Dependent, SetAccess = immutable)
        ChangeType (1,1) matlab.buildtool.fingerprints.ChangeType
    end

    properties (SetAccess = immutable, GetAccess = private)
        Change matlab.buildtool.fingerprints.FingerprintChange {mustBeScalarOrEmpty}
    end

    methods
        function diag = TaskChangeDiagnostic(property, change)
            arguments
                property (1,1) string
                change (1,1) matlab.buildtool.fingerprints.FingerprintChange
            end
            diag.Property = property;
            diag.Change = change;
        end

        function t = get.ChangeType(diag)
            t = diag.Change.Type;
        end

        function diagnose(diag)
            import matlab.automation.internal.diagnostics.indentWithArrow;

            id = "MATLAB:buildtool:TaskChangeDiagnostic:Property" + string(diag.ChangeType);
            descriptionText = getString(message(id, diag.Property));

            conditionsText = '';
            for condition = diag.Change.conditions()
                condition.diagnose();
                line = sprintf("\n%s", indentWithArrow(condition.DiagnosticText));
                conditionsText = strcat(conditionsText, line);
            end

            diag.DiagnosticText = strcat(descriptionText, conditionsText);
        end
    end
end