classdef IsSubstringOf < matlab.unittest.internal.constraints.SubstringConstraint & ...
                         matlab.unittest.internal.mixin.WithCountMixin
    % IsSubstringOf - Constraint specifying a substring of a given string or character vector
    %
    %   The IsSubstringOf constraint produces a qualification failure for any
    %   actual value that is not a string scalar or character vector that is
    %   found within an expected superstring.
    %
    %   IsSubstringOf methods:
    %      IsSubstringOf - Class constructor
    %
    %   IsSubstringOf properties:
    %      Superstring      - Text a value must be found inside to satisfy the constraint
    %      IgnoreCase       - Boolean indicating whether this instance is insensitive to case
    %      IgnoreWhitespace - Boolean indicating whether this instance is insensitive to whitespace
    %
    %   Examples:
    %       import matlab.unittest.constraints.IsSubstringOf;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat('Long', IsSubstringOf('SomeLongText'));
    %
    %       testCase.fatalAssertThat("lonG", ...
    %           IsSubstringOf("SomeLongText", 'IgnoringCase', true));
    %
    %       testCase.assertThat('LongText', ...
    %           IsSubstringOf("Some Long Text", 'IgnoringWhitespace', true));
    %
    %       testCase.verifyThat('Hello', IsSubstringOf('H Ello1 He llo2 Hel lo3 Hul lo4',...
    %           'WithCount' ,3, 'IgnoringCase', true, 'IgnoringWhitespace',true))
    %
    %       testCase.verifyThat('Hello', IsSubstringOf('HEllo1 Hello2 Hello3 Hullo4',...
    %           'WithCount' ,3, 'IgnoringCase', true))
    %
    %       testCase.verifyThat('Hello', IsSubstringOf('He llo1 Hel lo2 Hello3 Hullo 4',...
    %           'WithCount' ,1, 'IgnoringWhitespace',false))
    %
    %       testCase.verifyThat('Hello', IsSubstringOf('Hello1 Hello2 Hello3 Hullo4',...
    %           'WithCount' ,3))
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.assertThat("lonG", IsSubstringOf('SomeLongText'));
    %
    %       testCase.verifyThat("OtherText", IsSubstringOf("SomeLongText"));
    %
    %       testCase.assumeThat('SomeLongTextThatIsLonger', IsSubstringOf('SomeLongText'));
    %
    %       testCase.verifyThat('Hello', IsSubstringOf('H Ello1 He llo2 Hel lo3 Hul lo4',...
    %           'WithCount' ,5, 'IgnoringCase', true, 'IgnoringWhitespace',false))
    %
    %       testCase.verifyThat('Hello', IsSubstringOf('HEllo1 Hello2 Hello3 Hullo4',...
    %           'WithCount' ,3, 'IgnoringCase', false))
    %
    %       testCase.verifyThat('Hello', IsSubstringOf('He llo1 Hel lo2 H ello3 Hullo 4',...
    %           'WithCount' ,3, 'IgnoringWhitespace',false))
    %
    %       testCase.verifyThat('Hello', IsSubstringOf('Hello1 Hello2 Hello3 Hullo4',...
    %           'WithCount' ,6))
    %
    %   See also:
    %       ContainsSubstring
    %       StartsWithSubstring
    %       EndsWithSubstring
    %       Matches
    
    %  Copyright 2010-2019 The MathWorks, Inc.
    
    properties (Dependent, SetAccess = immutable)
        % Superstring - Text that a value must be found inside to satisfy the constraint
        %
        %   The Superstring property can either be a string scalar or character
        %   vector. This property is read only and can be set only through the
        %   constructor.
        Superstring
    end
    
    properties(Hidden,Constant,GetAccess=protected)
        PropertyName = 'Superstring';
    end
    
    methods
        function constraint = IsSubstringOf(varargin)
            % IsSubstringOf - Class constructor
            %
            %   IsSubstringOf(SUPERSTRING) creates a constraint that is able to
            %   determine whether an actual value is a string scalar or character
            %   vector that is found within the SUPERSTRING provided.
            %
            %   IsSubstringOf(SUPERSTRING, 'IgnoringCase', true) creates a constraint
            %   that is able to determine whether an actual value is a string scalar or
            %   character vector found within the SUPERSTRING provided, while ignoring
            %   any differences in case.
            %
            %   IsSubstringOf(SUPERSTRING, 'IgnoringWhitespace', true) creates a
            %   constraint that is able to determine whether an actual value is a
            %   string scalar or character vector found within the SUPERSTRING
            %   provided, while ignoring whitespace differences.
            %
            %   IsSubstringOf(SUPERSTRING,'WithCount',NUMERICVALUE) creates a constraint 
            %   that identifies a substring of another string scalar or character vector, 
            %   specified by SUPERSTRING. The constraint is satisfied only if the value is 
            %   contained within SUPERSTRING a specified number of times, NUMERICVALUE.
            
            constraint = constraint@matlab.unittest.internal.constraints.SubstringConstraint(varargin{:});
        end
        
        function value = get.Superstring(constraint)
            value = constraint.ExpectedValue;
        end
    end
    
    methods(Hidden, Access = protected)
        function diag = getNotSatisfiedByTextCondition(constraint, actual)
            if(constraint.CountValueProvidedExplicitly)
                diag = constraint.getNotSatisfiedByCountDiagnostic(actual);
            else
                diag = getNotSatisfiedByTextCondition@matlab.unittest.internal.constraints.SubstringConstraint(constraint, actual);
            end
        end
        
        function diag = getSatisfiedByTextCondition(constraint, actual)
            if(constraint.CountValueProvidedExplicitly)
                diag = constraint.getSatisfiedByCountDiagnostic(actual);
            else
                diag = getSatisfiedByTextCondition@matlab.unittest.internal.constraints.SubstringConstraint(constraint, actual);
            end
        end
        
        function diagCount = getNotSatisfiedByCountDiagnostic (constraint, actual)
            description = constraint.getDiagnosticCondition('IncorrectNumberOfOccurrences');
            numOfOcc = constraint.getNumOfOccurrences(actual);
            diagCount = constraint.getCountDiag(numOfOcc, description);
        end
        
        function diagCount = getSatisfiedByCountDiagnostic (constraint, actual)
            description = constraint.getDiagnosticCondition('CorrectNumberOfOccurrences');
            numOfOcc = constraint.getNumOfOccurrences(actual);
            diagCount = constraint.getCountDiag(numOfOcc, description);
        end
        
        function countDiag = getCountDiag(constraint, numOfOcc, description)
            countDiag = matlab.unittest.diagnostics.ConstraintDiagnostic;
            countDiag.ActValHeader = getString(message('MATLAB:unittest:IsSubstringOf:ActualElementCount'));
            countDiag.ExpValHeader = getString(message('MATLAB:unittest:IsSubstringOf:ExpectedElementCount'));
            countDiag.DisplayDescription = true;
            countDiag.DisplayActVal = true;
            countDiag.ActVal = numOfOcc;
            countDiag.DisplayExpVal = true;
            countDiag.Description = description;
            countDiag.ExpVal = constraint.Count;
        end
    end
    
    methods(Hidden, Access = protected)
        function [actual, superstring] = removeWhitespaceIfNeeded(constraint, actual)
            superstring = constraint.ExpectedValue;
            if constraint.IgnoreWhitespace
                actual = constraint.removeWhitespaceFrom(actual);
                superstring = constraint.removeWhitespaceFrom(superstring);
            end
        end
        
        function numOfOcc = getNumOfOccurrences(constraint, actual)
            [actual, superstring] = constraint.removeWhitespaceIfNeeded(actual);
            numOfOcc = count(superstring, actual, "IgnoreCase",constraint.IgnoreCase);
        end
    end
    
    methods (Hidden, Access = protected)
        function catalog = getMessageCatalog(~)
            catalog = matlab.internal.Catalog('MATLAB:unittest:IsSubstringOf');
        end
        
        function bool = satisfiedByText(constraint, actual)
            if (constraint.CountValueProvidedExplicitly)
                actCount = constraint.getNumOfOccurrences(actual);
                bool = constraint.Count==actCount;
            else
                [actual, superstring] = constraint.removeWhitespaceIfNeeded(actual);
                bool = contains(superstring, string(actual),'IgnoreCase',constraint.IgnoreCase);
            end
        end
    end
    
    methods(Hidden, Access = protected)
        function args = getInputArguments(constraint)
            args = getInputArguments@matlab.unittest.internal.constraints.SubstringConstraint(constraint);
            if (constraint.CountValueProvidedExplicitly)                       
                args = [args,{'WithCount',constraint.Count}];
            end
        end
    end
end

% LocalWords:  superstring lon ASupported