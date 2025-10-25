classdef ContainsSubstring < matlab.unittest.internal.constraints.SubstringConstraint & ...
                             matlab.unittest.internal.constraints.HybridCasualDiagnosticMixin & ...
                             matlab.unittest.internal.mixin.WithCountMixin
    % ContainsSubstring - Constraint specifying a string or character vector containing a given substring
    %
    %   The ContainsSubstring constraint produces a qualification failure for
    %   any actual value that is not a string scalar or character vector that
    %   contains an expected substring.
    %
    %   ContainsSubstring methods:
    %       ContainsSubstring - Class constructor
    %
    %   ContainsSubstring properties:
    %       Substring        - Text that a value must contain to satisfy the constraint
    %       IgnoreCase       - Boolean indicating whether this instance is insensitive to case
    %       IgnoreWhitespace - Boolean indicating whether this instance is insensitive to whitespace
    %
    %   Examples:
    %       import matlab.unittest.constraints.ContainsSubstring;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat('SomeLongText', ContainsSubstring('Long'));
    %
    %       testCase.fatalAssertThat("SomeLongText", ...
    %           ContainsSubstring("lonG",'IgnoringCase', true));
    %
    %       testCase.assumeThat("SomeLongText", ...
    %           ContainsSubstring('Some Long Text','IgnoringWhitespace', true));
    %
    %       testCase.verifyThat('H Ello1 He llo2 Hel lo3 Hul lo4', ContainsSubstring('Hello',...
    %           'WithCount' ,3, 'IgnoringCase', true, 'IgnoringWhitespace',true))
    %
    %       testCase.verifyThat('HEllo1 Hello2 Hello3 Hullo4', ContainsSubstring('Hello',...
    %           'WithCount' ,3, 'IgnoringCase', true))
    %
    %       testCase.verifyThat('He llo1 Hel lo2 Hello3 Hullo 4', ContainsSubstring('Hello',...
    %           'WithCount' ,1, 'IgnoringWhitespace',false))
    %
    %       testCase.verifyThat('Hello1 Hello2 Hello3 Hullo4', ContainsSubstring('Hello',...
    %           'WithCount' ,3))
    %
    %       % Failing scenarios %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat('SomeLongText', ContainsSubstring("lonG"));
    %
    %       testCase.assertThat("SomeLongText", ContainsSubstring("OtherText"));
    %
    %       testCase.verifyThat('SomeLongText', ContainsSubstring('SomeLongTextThatIsLonger'));
    %
    %       testCase.verifyThat('H Ello1 He llo2 Hel lo3 Hul lo4', ContainsSubstring('Hello',...
    %           'WithCount' ,5, 'IgnoringCase', true, 'IgnoringWhitespace',false))
    %
    %       testCase.verifyThat('HEllo1 Hello2 Hello3 Hullo4', ContainsSubstring('Hello',...
    %           'WithCount' ,6, 'IgnoringCase', true))
    %
    %       testCase.verifyThat('He llo1 Hel lo2 H ello3 Hullo 4', ContainsSubstring('Hello',...
    %           'WithCount' ,30, 'IgnoringWhitespace',false))
    %
    %       testCase.verifyThat('He llo1 Hel lo2 Hel lo3 Hul lo4', ContainsSubstring('Hello',...
    %           'WithCount' ,3))
    %
    %   See also:
    %       IsSubstringOf
    %       StartsWithSubstring
    %       EndsWithSubstring
    %       Matches
    
    %  Copyright 2010-2019 The MathWorks, Inc.
    
    properties (Dependent, SetAccess = immutable)
        % Substring - Text that a value must contain to satisfy the constraint
        %
        %   The Substring property can either be a string scalar or character
        %   vector. This property is read only and can be set only through the
        %   constructor.
        Substring
    end
    
    properties(Hidden,Constant,GetAccess=protected)
        PropertyName = 'Substring';
    end
    
    methods
        function constraint = ContainsSubstring(varargin)
            % ContainsSubstring - Class constructor
            %
            %   ContainsSubstring(SUBSTRING) creates a constraint that is able to
            %   determine whether an actual value is a string scalar or character
            %   vector that contains the SUBSTRING provided.
            %
            %   ContainsSubstring(SUBSTRING, 'IgnoringCase', true) creates a constraint
            %   that is able to determine whether an actual value is a string scalar or
            %   character vector that contains the SUBSTRING provided, while ignoring
            %   any differences in case.
            %
            %   ContainsSubstring(SUBSTRING, 'IgnoringWhitespace', true) creates a
            %   constraint that is able to determine whether an actual value is a
            %   string scalar or character vector that contains the SUBSTRING provided,
            %   while ignoring any whitespace differences.
            %
            %   ContainsSubstring(SUBSTRING,'WithCount',NUMERICVALUE) creates a 
            %   constraint that identifies a superstring of another string scalar or 
            %   character vector, specified by SUBSTRING. The constraint is satisfied 
            %   only if the value contains SUBSTRING a specified number of
            %   times, NUMERICVALUE.
            
            constraint = constraint@matlab.unittest.internal.constraints.SubstringConstraint(varargin{:});
        end
        
        function value = get.Substring(constraint)
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
            countDiag.ActValHeader = getString(message('MATLAB:unittest:ContainsSubstring:ActualElementCount'));
            countDiag.ExpValHeader = getString(message('MATLAB:unittest:ContainsSubstring:ExpectedElementCount'));
            countDiag.DisplayDescription = true;
            countDiag.DisplayActVal = true;
            countDiag.ActVal = numOfOcc;
            countDiag.DisplayExpVal = true;
            countDiag.Description = description;
            countDiag.ExpVal = constraint.Count;
        end
    end
    
    methods(Hidden, Access = protected)
        function [actual, substring] = removeWhitespaceIfNeeded(constraint, actual)
            substring = constraint.ExpectedValue;
            if constraint.IgnoreWhitespace
                actual = constraint.removeWhitespaceFrom(actual);
                substring = constraint.removeWhitespaceFrom(substring);
            end
        end
        
        function numOfOcc = getNumOfOccurrences(constraint, actual)
            [actual, substring] = constraint.removeWhitespaceIfNeeded(actual);
            numOfOcc = count(actual, substring, "IgnoreCase", constraint.IgnoreCase);
        end
    end
    
    methods (Hidden, Access = protected)
        function catalog = getMessageCatalog(~)
            catalog = matlab.internal.Catalog('MATLAB:unittest:ContainsSubstring');
        end
        
        function bool = satisfiedByText(constraint, actual)
            if (constraint.CountValueProvidedExplicitly)
                actCount = constraint.getNumOfOccurrences(actual);
                bool = constraint.Count==actCount;
            else
                [actual, substring] = constraint.removeWhitespaceIfNeeded(actual);
                bool = contains(string(actual), substring, 'IgnoreCase', constraint.IgnoreCase);
            end
        end
    end
    
    methods(Hidden, Access = protected)
        function args = getInputArguments(constraint)
            args = getInputArguments@matlab.unittest.internal.constraints.SubstringConstraint(constraint);
            if constraint.CountValueProvidedExplicitly
                args = [args,{'WithCount',constraint.Count}];
            end
        end
    end
end

% LocalWords:  lon ASupported
