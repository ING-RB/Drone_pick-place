classdef Matches < matlab.unittest.constraints.BooleanConstraint & ...
        matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
        matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin & ...
        matlab.unittest.internal.constraints.HybridCasualDiagnosticMixin & ...
        matlab.unittest.internal.mixin.IgnoringCaseMixin & ...
        matlab.unittest.internal.mixin.WithCountMixin
    % Matches - Constraint specifying a string or character vector matching a given regular expression
    %
    %   The Matches constraint produces a qualification failure for any actual
    %   value that is not a string scalar or character vector that matches a
    %   given regular expression.
    %
    %   Matches methods:
    %       Matches - Class constructor
    %
    %   Matches properties:
    %      Expression - Regular expression the value must match to satisfy the constraint
    %      IgnoreCase - Boolean indicating whether this instance is insensitive to case
    %
    %   Examples:
    %       import matlab.unittest.constraints.Matches;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat('SomeText', Matches('ext$'));
    %       testCase.assertThat("Sometext", Matches("^some",'IgnoringCase', true));
    %       testCase.fatalAssertThat("Someext", Matches("Some[Tt]?ext"));
    %       testCase.verifyThat('SomeText', Matches("some.*t", 'IgnoringCase', true));
    %       testCase.verifyThat('SomeText', Matches("Some.*t",'WithCount',1))
    %       testCase.verifyThat('SomeText', ~Matches("some.*t",'WithCount',5))
    %       testCase.verifyThat('dummy1 dummy2 dummy3', Matches('d[u]mmy','WithCount' ,3))
    %       testCase.verifyThat('dummy1 dummy2 dUmmy3', Matches('d[U]mmy','WithCount',3,'IgnoringCase', true))
    %       testCase.verifyThat('dummy1 dummy2 dummy3', Matches('d[u]mmy','WithCount',3,'IgnoringCase', false))
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.assumeThat('SomeTtext', Matches('Some[Tt]?ext'));
    %       testCase.assertThat("Sometext", Matches("Some$"));
    %       testCase.verifyThat('SomeText', Matches('Some[Tt]?ext','WithCount',5))
    %       testCase.verifyThat('dummy1 dummy2 dUmmy3 dummy4', Matches('d[u]mmy','WithCount',4))
    %       testCase.verifyThat('dummy1 dummy2 dUmmy3 dummy4', Matches('d[u]mmy','WithCount',4,'IgnoringCase', false))
    %
    %   See also:
    %       regexp
    %       ContainsSubstring
    %       IsSubstringOf
    %       StartsWithSubstring
    %       EndsWithSubstring
    
    %  Copyright 2010-2017 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        % Expression - Regular expression the value must match to satisfy the constraint
        %
        %   The Expression property can either be a string scalar or character
        %   vector. This property is read only and can be set only through the
        %   constructor.
        Expression
    end
    
    methods
        function constraint = Matches(expression, varargin)
            % Matches - Class constructor
            %
            %   Matches(EXPRESSION) creates a constraint that is able to determine
            %   whether an actual value is a string scalar or character vector that
            %   matches the regular expression provided.
            %
            %   Matches(EXPRESSION, 'IgnoringCase', true) creates a constraint that is
            %   able to determine whether an actual value is a string scalar or
            %   character vector that matches the regular expression provided, while
            %   ignoring any differences in case.
            %
            %   Matches(EXPRESSION, 'WithCount', NUMERICVALUE) creates a constraint
            %   that is able to determine whether an actual value is a string scalar or
            %   character vector that matches the regular expression the specified
            %   number of times.
            import matlab.unittest.internal.mustBeTextScalar;
            import matlab.unittest.internal.mustContainCharacters;
            mustBeTextScalar(expression,'Expression');
            mustContainCharacters(expression,'Expression');
            constraint.Expression = expression;
            constraint = constraint.parse(varargin{:});
        end
        
        function bool = satisfiedBy(constraint, actual)
            bool = isSupportedActualValue(actual) && ...
                constraint.matches(actual);
        end
    end
    
    methods(Access= private)
        function numOfOccurrences = getOccurrencesByRegex(actual,constraint)            
            numOfOccurrences = numel(regexp(actual, constraint.Expression, constraint.getCaseHandling));            
        end
        
        function countDiag = getTheDiagnosticsForCount(constraint, actual, description)                      
            numOfOccurrences = getOccurrencesByRegex(actual,constraint);
            countDiag = matlab.unittest.diagnostics.ConstraintDiagnostic;            
            countDiag.ActValHeader = getString(message('MATLAB:unittest:Matches:ActualElementCount'));
            countDiag.ExpValHeader = getString(message('MATLAB:unittest:Matches:ExpectedElementCount'));
            countDiag.DisplayDescription = true;
            countDiag.DisplayActVal = true;
            countDiag.ActVal = numOfOccurrences;
            countDiag.DisplayExpVal = true;
            countDiag.Description = description.getString;
            countDiag.ExpVal = constraint.Count;            
        end
    end
    
    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            if ~isSupportedActualValue(actual)
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual);
                diag.addCondition(message('MATLAB:unittest:Matches:ActualMustBeASupportedType',...
                    class(actual),mat2str(size(actual))));
            elseif ~constraint.matches(actual)
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual, constraint.Expression);
                diag.ExpValHeader = getString(message('MATLAB:unittest:Matches:RegularExpression'));
                if (constraint.CountValueProvidedExplicitly)
                    description = constraint.getDiagnosticCondition('IncorrectNumberOfOccurrences');
                    diag.addCondition(getTheDiagnosticsForCount(constraint, actual, description));
                else
                    diag.addCondition(constraint.getDiagnosticCondition('DoesNotMatchExpression'));
                end
            else
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual, constraint.Expression);
                diag.ExpValHeader = getString(message('MATLAB:unittest:Matches:RegularExpression'));
                diag.addCondition(constraint.getDiagnosticCondition('DoesMatchExpression'));
                if (constraint.CountValueProvidedExplicitly)
                    description = constraint.getDiagnosticCondition('CorrectNumberOfOccurrences');
                    diag.addCondition(getTheDiagnosticsForCount(constraint, actual, description));
                end
            end
        end
        
        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            if ~isSupportedActualValue(actual)
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual);
                diag.addCondition(getString(message('MATLAB:unittest:Matches:ActualIsNotASupportedType',...
                    class(actual),mat2str(size(actual)))));
            elseif ~constraint.matches(actual)
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual, constraint.Expression);
                diag.ExpValHeader = getString(message('MATLAB:unittest:Matches:RegularExpression'));
                if (constraint.CountValueProvidedExplicitly)
                    description = constraint.getDiagnosticCondition('IncorrectNumberOfOccurrences');
                    diag.addCondition(getTheDiagnosticsForCount(constraint, actual, description));
                else
                    diag.addCondition(constraint.getDiagnosticCondition('DoesNotMatchExpression'));
                end
            else
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual, constraint.Expression);
                diag.ExpValHeader = getString(message('MATLAB:unittest:Matches:RegularExpression'));
                diag.addCondition(constraint.getDiagnosticCondition('DoesMatchExpression'));
                if (constraint.CountValueProvidedExplicitly)
                    description = constraint.getDiagnosticCondition('CorrectNumberOfOccurrences');
                    diag.addCondition(getTheDiagnosticsForCount(constraint, actual, description));
                end
            end
        end
    end
    
    methods(Hidden,Sealed,Access=protected)
        function args = getInputArguments(constraint)
            args = {constraint.Expression};
            if constraint.IgnoreCase
                args = [args,{'IgnoringCase',true}];
            end
            
            if constraint.CountValueProvidedExplicitly
                args = [args,{'WithCount',constraint.Count}];
            end
        end
    end
    
    methods (Access = private)
        function bool = matches(constraint, actual)
            if constraint.CountValueProvidedExplicitly
                numOfOccurrences = getOccurrencesByRegex(actual,constraint);
                bool = isequal(constraint.Count, numOfOccurrences);
            else
                bool = ~isempty(regexp(actual, constraint.Expression, 'once', constraint.getCaseHandling));
            end
        end
        
        function cond = getDiagnosticCondition(constraint,keyPrefix)
            if constraint.IgnoreCase
                cond = message(['MATLAB:unittest:Matches:' keyPrefix 'IgnoringCase']);
            else
                cond = message(['MATLAB:unittest:Matches:' keyPrefix]);
            end
        end
        
        function caseHandling = getCaseHandling(constraint)
            if constraint.IgnoreCase
                caseHandling = 'ignorecase';
            else
                caseHandling = 'matchcase';
            end
        end
    end
end

function bool = isSupportedActualValue(value)
bool = isCharacterVector(value) || isStringScalar(value);
end

function bool = isStringScalar(value)
bool = isstring(value) && isscalar(value);
end

function bool = isCharacterVector(value)
bool = ischar(value) && (isrow(value) || strcmp(value,''));
end

% LocalWords:  Tt Sometext Someext Ttext ASupported ignorecase matchcase