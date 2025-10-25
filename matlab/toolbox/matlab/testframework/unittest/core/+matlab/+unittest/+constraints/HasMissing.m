classdef HasMissing < matlab.unittest.constraints.BooleanConstraint & ...
        matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
        matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin
    % HasMissing - Test if value has missing elements
    %
    %   The matlab.unittest.constraints.HasMissing class provides a
    %   constraint to test if a value has any missing elements. The
    %   constraint uses the "ismissing" function to determine what values
    %   are missing.
    %
    %   HasMissing methods:
    %       HasMissing - Class constructor
    %
    %   Examples:
    %       import matlab.unittest.constraints.HasMissing;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat([1 1 1 NaN], HasMissing);
    %       testCase.verifyThat(["a";missing;"c";"d"], HasMissing);
    %       testCase.verifyThat([datetime(2015,1:4,15)], ~HasMissing);
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat([1 1 1 1], HasMissing);
    %       testCase.verifyThat(["e";"f";"g";"h"], HasMissing);
    %       testCase.verifyThat([datetime(2015,5:7,15),NaT], ~HasMissing);
    %
    %   See also:
    %       ismissing
    %       HasNaN
    %       HasInf

    %  Copyright 2022 The MathWorks, Inc.

    methods
        function constraint = HasMissing
            % HasMissing - Class constructor
            %
            % c = matlab.unittest.constraints.HasMissing creates a
            % constraint to test if a value has any missing elements. The
            % constraint uses the "ismissing" function to determine what
            % values are missing. The constraint is satisfied if any
            % element of the value is missing.
        end

        function tf = satisfiedBy(~, actual)
            mask = ismissing(actual);
            tf = any(mask(:));
        end
    end

    methods(Hidden, Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            import matlab.unittest.internal.diagnostics.indent;
            import matlab.unittest.internal.supportsArrayIndexing;

            if constraint.satisfiedBy(actual)
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint,...
                    DiagnosticSense.Positive, actual);
                if ~isscalar(actual)
                    if supportsArrayIndexing(actual)
                        indicesString = indicesOfMissingString(actual);
                        diag.addCondition(message('MATLAB:unittest:HasMissing:HasMissingValues', indent(indicesString)));
                    end
                end
            else
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint,...
                    DiagnosticSense.Positive, actual);
                if isscalar(actual)
                    diag.addCondition(message('MATLAB:unittest:HasMissing:MustBeMissingScalar'));
                else
                    diag.addCondition(message('MATLAB:unittest:HasMissing:MustContainMissing'));
                end
            end
        end

        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            import matlab.unittest.internal.diagnostics.indent;
            import matlab.unittest.internal.supportsArrayIndexing;

            if constraint.satisfiedBy(actual)
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint,...
                    DiagnosticSense.Negative, actual);
                if isscalar(actual)
                    diag.addCondition(message('MATLAB:unittest:HasMissing:MustNotBeMissingScalar'));
                else
                    if supportsArrayIndexing(actual)
                        indicesString = indicesOfMissingString(actual);
                        diag.addCondition(message('MATLAB:unittest:HasMissing:MustNotContainMissing', indent(indicesString)));
                    end
                end
            else
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint,...
                    DiagnosticSense.Negative, actual);
                if isscalar(actual)
                    diag.addCondition(message('MATLAB:unittest:HasMissing:NotAMissingValue'));
                else
                    diag.addCondition(message('MATLAB:unittest:HasMissing:NoMissingValues'));
                end
            end
        end
    end
end

%% Local indicesOfMissingString function
function str = indicesOfMissingString(actual)
str = mat2str(reshape(find(ismissing(actual)), 1, []));
end
