classdef(Hidden,HandleCompatible) HybridCasualDiagnosticMixin < matlab.unittest.internal.constraints.CasualDiagnosticMixin
    % This class is undocumented and may change in a future release.
    
    %  Copyright 2017 The MathWorks, Inc.
    methods(Hidden,Abstract)
        diag = getConstraintDiagnosticFor(constraint,actual)
    end
    
    methods(Hidden,Sealed)
        function diag = getCasualDiagnosticFor(constraint,casualMethodName,actual,additionalArgs)
            import matlab.unittest.internal.diagnostics.FormattableStringDiagnostic;
            import matlab.unittest.internal.diagnostics.ReconstructedCasualCallDiagnostic;
            import matlab.unittest.internal.diagnostics.VerbosityDrivenDiagnostic;
            import matlab.unittest.diagnostics.FrameworkDiagnostic;
            
            constraintDiag = constraint.getCasualConstraintDiagnosticFor(casualMethodName,actual,additionalArgs);
            
            terseDiag = FormattableStringDiagnostic(constraintDiag.FormattableDescription);
            conciseDiag = ReconstructedCasualCallDiagnostic(casualMethodName,[{actual},additionalArgs],...
                constraintDiag.Passed);
            detailedDiag = constraintDiag;
            verboseDiag = constraintDiag;
            
            diag = VerbosityDrivenDiagnostic(terseDiag,conciseDiag,detailedDiag,verboseDiag);
            diag = FrameworkDiagnostic(diag);
        end
    end
    
    methods(Hidden,Access=protected)
        function constraintDiag = getCasualConstraintDiagnosticFor(constraint,fullCasualMethodName,actual,~)
            constraintDiag = constraint.getConstraintDiagnosticFor(actual);
            constraintDiag.applyAlias(fullCasualMethodName);
        end
    end
end