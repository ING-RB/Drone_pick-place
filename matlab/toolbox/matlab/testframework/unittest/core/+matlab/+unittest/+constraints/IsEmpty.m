classdef IsEmpty < matlab.unittest.constraints.BooleanConstraint & ...
                   matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
                   matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin & ...
                   matlab.unittest.internal.constraints.HybridCasualDiagnosticMixin & ...
                   matlab.unittest.internal.constraints.HybridCasualNegativeDiagnosticMixin
                   
    % IsEmpty - Constraint specifying an empty value
    %
    %   The IsEmpty constraint produces a qualification failure for
    %   any non-empty actual value array.
    %
    %   IsEmpty methods:
    %       IsEmpty - Class constructor
    %
    %   Examples:
    %       import matlab.unittest.constraints.IsEmpty;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat(ones(2, 5, 0, 3), IsEmpty);
    %       testCase.assertThat('', IsEmpty);
    %       testCase.assumeThat(MException.empty, IsEmpty);
    %
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.fatalAssertThat([2 3], IsEmpty);
    %       testCase.verifyThat({[], [], []}, IsEmpty);
    %
    %   See also:
    %       HasElementCount
    %       HasLength
    %       HasSize
    %       isempty
    
    %  Copyright 2010-2017 The MathWorks, Inc.
    methods
        function constraint = IsEmpty
            % IsEmpty - Class constructor
            %
            %   IsEmpty creates a constraint that is able to determine
            %   whether an actual value is empty.
        end
            
        function tf = satisfiedBy(~, actual)
            tf = isempty(actual);
        end
    end
    
    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            if constraint.satisfiedBy(actual)
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual);
            else
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual);
                diag.addCondition(message('MATLAB:unittest:IsEmpty:MustBeEmpty'));
            end
            
            diag.addCondition(message('MATLAB:unittest:IsEmpty:ActualSize', int2str(size(actual))));
        end
        
        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            if constraint.satisfiedBy(actual)
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual);
                diag.addCondition(message('MATLAB:unittest:IsEmpty:MustNotBeEmpty'));
            else
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual);
            end
            
            diag.addCondition(message('MATLAB:unittest:IsEmpty:ActualSize', int2str(size(actual))));
        end
    end
end