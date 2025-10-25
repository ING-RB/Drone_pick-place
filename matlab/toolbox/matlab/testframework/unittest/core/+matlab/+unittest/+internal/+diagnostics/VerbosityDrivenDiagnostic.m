classdef(Sealed) VerbosityDrivenDiagnostic < matlab.unittest.diagnostics.ExtendedDiagnostic & ...
                                             matlab.unittest.internal.diagnostics.ConditionsSupplier
    % This class is undocumented and may change in a future release
    
    % Copyright 2017-2018 The MathWorks, Inc.
    properties(GetAccess=private,SetAccess=immutable)
        Diagnostics (1,5) matlab.unittest.diagnostics.Diagnostic = ...
            repmat(matlab.unittest.internal.diagnostics.EmptyDiagnostic,1,5);
    end
    
    methods
        function diag = VerbosityDrivenDiagnostic(terseDiag,conciseDiag,detailedDiag,verboseDiag)
            import matlab.unittest.diagnostics.Diagnostic;
            diag.Diagnostics = Diagnostic.join("",terseDiag,conciseDiag,detailedDiag,verboseDiag);
        end
    end
    
    methods(Hidden, Sealed)
        function diagnoseWith(diag,diagData)
            chosenDiag = diag.Diagnostics(double(diagData.Verbosity)+1);
            chosenDiag.diagnoseWith(diagData);
            diag.DiagnosticText = chosenDiag.FormattableDiagnosticText;
            diag.Artifacts = chosenDiag.Artifacts;
        end
        
        function bool = producesSameResultFor(diag,diagData1,diagData2)
            chosenDiag1 = diag.Diagnostics(double(diagData1.Verbosity)+1);
            chosenDiag2 = diag.Diagnostics(double(diagData2.Verbosity)+1);
            bool = chosenDiag1 == chosenDiag2 && ...
                chosenDiag1.producesSameResultFor(diagData1,diagData2);
        end
        
        function conditions = getConditions(diag,diagData)
            import matlab.unittest.diagnostics.Diagnostic;
            chosenDiag = diag.Diagnostics(double(diagData.Verbosity)+1);
            if isa(chosenDiag,'matlab.unittest.internal.diagnostics.ConditionsSupplier')
                conditions = chosenDiag.getConditions(diagData);
            else
                conditions = Diagnostic.empty(1,0);
            end
        end
    end
end
