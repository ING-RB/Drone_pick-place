classdef(Hidden,HandleCompatible) HybridDiagnosticMixin
    % This class is undocumented and may change in a future release.
    
    %  Copyright 2017 The MathWorks, Inc.
    methods(Hidden, Abstract)
        constraintDiag = getConstraintDiagnosticFor(constraint,actual)
    end
    
    methods(Sealed)
        function diag = getDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.FormattableStringDiagnostic;
            import matlab.unittest.internal.diagnostics.ReconstructedFormalCallDiagnostic;
            import matlab.unittest.internal.diagnostics.VerbosityDrivenDiagnostic;
            import matlab.unittest.diagnostics.FrameworkDiagnostic;
            
            constraintDiag = constraint.getConstraintDiagnosticFor(actual);
            
            terseDiag = FormattableStringDiagnostic(constraintDiag.FormattableDescription);
            conciseDiag = ReconstructedFormalCallDiagnostic.forPositiveSense(class(constraint), actual,...
                constraint.getInputArguments(), constraintDiag.Passed);
            detailedDiag = constraintDiag;
            verboseDiag = constraintDiag;
            
            diag = VerbosityDrivenDiagnostic(terseDiag,conciseDiag,detailedDiag,verboseDiag);
            diag = FrameworkDiagnostic(diag);
        end
    end
    
    methods(Hidden,Access=protected)
        function args = getInputArguments(constraint) %#ok<MANU>
            args = {};
        end
    end
end