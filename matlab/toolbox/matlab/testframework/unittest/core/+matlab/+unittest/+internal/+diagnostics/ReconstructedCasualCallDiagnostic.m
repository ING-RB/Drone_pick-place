classdef ReconstructedCasualCallDiagnostic < matlab.unittest.diagnostics.Diagnostic
    % This class is undocumented and may change in a future release
    
    % Copyright 2017 The MathWorks, Inc.
    properties(SetAccess=immutable)
        CasualMethodName (1,:) char
        InputArguments (1,:) cell
        ConditionWasSatisfied (1,1) logical
    end
    
    methods
        function diag = ReconstructedCasualCallDiagnostic(casualMethodName,inputArgs,wasSatisfied)
            diag.CasualMethodName = casualMethodName;
            diag.InputArguments = inputArgs;
            diag.ConditionWasSatisfied = wasSatisfied;
        end
    end
    
    methods(Sealed)
        function diagnose(diag)
            import matlab.unittest.internal.getOneLineSummary;
            import matlab.unittest.internal.diagnostics.createClassNameForCommandWindow;
            import matlab.unittest.internal.diagnostics.createPassFailStatementString;
            reconstructedCallStr = createClassNameForCommandWindow(diag.CasualMethodName) + ...
                "(" + strjoin(cellfun(@getOneLineSummary,diag.InputArguments),",") + ")";
            
            diag.DiagnosticText = createPassFailStatementString(...
                reconstructedCallStr, diag.ConditionWasSatisfied);
        end
    end
end