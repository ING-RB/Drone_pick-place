classdef(Sealed) FrameworkDiagnostic < matlab.unittest.internal.diagnostics.DiagnosticDecorator
    % FrameworkDiagnostic - Diagnostic provided by the testing framework
    % 
    %   A FrameworkDiagnostic object provides a diagnostic result from select
    %   testing framework comparators, constraints, and tolerances. The testing
    %   framework creates the FrameworkDiagnostic object, so there is no need
    %   to construct this class directly.
    %
    %   See also:
    %       matlab.unittest.diagnostics.Diagnostic
    
    %  Copyright 2017 The MathWorks, Inc.
    
    methods(Hidden)
        function diag = FrameworkDiagnostic(innerDiag)
            validateattributes(innerDiag,{'matlab.unittest.diagnostics.Diagnostic'},{'scalar'});
            diag = diag@matlab.unittest.internal.diagnostics.DiagnosticDecorator(innerDiag);
        end
    end
    
    methods(Hidden, Access=protected)
        function diagText = createDiagnosticText(diag)
            diagText = diag.ComposedDiagnostic.FormattableDiagnosticText;
        end
    end
end