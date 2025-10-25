classdef(Hidden,HandleCompatible) HybridCasualNegativeDiagnosticMixin < matlab.unittest.internal.constraints.CasualNegativeDiagnosticMixin
    % This class is undocumented and may change in a future release.
    
    %  Copyright 2017 The MathWorks, Inc.
    methods(Hidden,Abstract)
        diag = getNegativeConstraintDiagnosticFor(constraint,actual)
    end
    
    methods(Hidden,Sealed)
        function diag = getCasualNegativeDiagnosticFor(constraint,casualMethodName,actual,additionalArgs)
            import matlab.unittest.internal.diagnostics.FormattableStringDiagnostic;
            import matlab.unittest.internal.diagnostics.ReconstructedCasualCallDiagnostic;
            import matlab.unittest.internal.diagnostics.VerbosityDrivenDiagnostic;
            import matlab.unittest.diagnostics.FrameworkDiagnostic;
            
            constraintDiag = constraint.getCasualNegativeConstraintDiagnosticFor(casualMethodName,actual,additionalArgs);
            
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
        function constraintDiag = getCasualNegativeConstraintDiagnosticFor(constraint,casualMethodName,actual,~)
            constraintDiag = constraint.getNegativeConstraintDiagnosticFor(actual);
            constraintDiag.applyAlias(casualMethodName);
        end
    end
end