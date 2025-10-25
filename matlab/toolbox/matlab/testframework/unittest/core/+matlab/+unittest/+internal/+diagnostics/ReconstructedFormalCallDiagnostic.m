classdef ReconstructedFormalCallDiagnostic < matlab.unittest.diagnostics.Diagnostic
    % This class is undocumented and may change in a future release
    
    % Copyright 2017 The MathWorks, Inc.
    properties(SetAccess=immutable)
        ConstraintName (1,:) char
        ActualValue
        ConstraintArguments (1,:) cell
        ConstraintWasSatisfied (1,1) logical
        IsPositive (1,1) logical
    end
    
    methods(Access=private, Hidden)
        function diag = ReconstructedFormalCallDiagnostic(constraintName,actual,constraintArgs,wasSatisfied,isPositive)
            diag.ConstraintName = constraintName;
            diag.ActualValue = actual;
            diag.ConstraintArguments = constraintArgs;
            diag.ConstraintWasSatisfied = wasSatisfied;
            diag.IsPositive = isPositive;
        end
    end
    
    methods(Static)
        function diag = forPositiveSense(constraintName,actual,constraintArgs,wasSatisfied)
            import matlab.unittest.internal.diagnostics.ReconstructedFormalCallDiagnostic;
            diag = ReconstructedFormalCallDiagnostic(constraintName,actual,constraintArgs,wasSatisfied,true);
        end
        
        function diag = forNegativeSense(constraintName,actual,constraintArgs,wasSatisfied)
            import matlab.unittest.internal.diagnostics.ReconstructedFormalCallDiagnostic;
            diag = ReconstructedFormalCallDiagnostic(constraintName,actual,constraintArgs,wasSatisfied,false);
        end
    end
    
    methods
        function diagnose(diag)
            import matlab.unittest.internal.getOneLineSummary;
            import matlab.unittest.internal.diagnostics.createClassNameForCommandWindow;
            import matlab.unittest.internal.diagnostics.createPassFailStatementString;

            actValTxt = getOneLineSummary(diag.ActualValue);
            
            constraintTxt = createClassNameForCommandWindow(diag.ConstraintName);
            if ~diag.IsPositive
                constraintTxt = "~" + constraintTxt;
            end
            if ~isempty(diag.ConstraintArguments)
                constraintTxt = constraintTxt + "(" + ...
                    strjoin(cellfun(@getOneLineSummary,diag.ConstraintArguments),",") + ")";
            end
            
            diag.DiagnosticText = createPassFailStatementString( ...
                actValTxt + " " + constraintTxt, diag.ConstraintWasSatisfied);
        end
    end
end