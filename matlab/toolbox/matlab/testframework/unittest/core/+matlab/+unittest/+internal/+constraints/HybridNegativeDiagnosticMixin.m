classdef(Hidden,HandleCompatible) HybridNegativeDiagnosticMixin < matlab.unittest.internal.constraints.NegatableConstraint
    % This class is undocumented and may change in a future release.
    
    % Note that this class inherits from NegatableConstraint only to give
    % the NotConstraint class access to the getNegativeDiagnosticFor method.
    
    %  Copyright 2017 The MathWorks, Inc.
    methods(Hidden,Abstract)
        constraintDiag = getNegativeConstraintDiagnosticFor(constraint,actual)
    end
    
    methods(Hidden,Abstract,Access=protected)
        args = getInputArguments(constraint)
    end
    
    methods(Sealed, Access=protected)
        function diag = getNegativeDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.FormattableStringDiagnostic;
            import matlab.unittest.internal.diagnostics.ReconstructedFormalCallDiagnostic;
            import matlab.unittest.internal.diagnostics.VerbosityDrivenDiagnostic;
            import matlab.unittest.diagnostics.FrameworkDiagnostic;
            
            constraintDiag = constraint.getNegativeConstraintDiagnosticFor(actual);
            
            terseDiag = FormattableStringDiagnostic(constraintDiag.FormattableDescription);
            conciseDiag = ReconstructedFormalCallDiagnostic.forNegativeSense(class(constraint), actual,...
                constraint.getInputArguments(), constraintDiag.Passed);
            detailedDiag = constraintDiag;
            verboseDiag = constraintDiag;
            
            diag = VerbosityDrivenDiagnostic(terseDiag,conciseDiag,detailedDiag,verboseDiag);
            diag = FrameworkDiagnostic(diag);
        end
    end
end