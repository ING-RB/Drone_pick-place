classdef FileResult
    %FileResult Holds the results of a file's help audit tests
    
    %Test results from tests on overall help text
    properties
        NoCopyright            % No copyright in help text
        UnderMaximumLineLength % All lines under 75 characters in help text
        NoTrailingWhitespace   % No trailing whitespace in help text
        UnderMaximumNumLines   % Number of lines is beneath limit in help text
        NoTabs                 % No tabs in help text
        NoHardcodedLinks       % No hardcoded links in help text
        NoEvalLinks            % No href= matlab:  evaluation links
    end

    %Test results from H1 line
    properties
        H1NoLeadingWhitespace % No leading whitespace in H1 line
        H1StartsWithFunction  % H1 line starts with function
        H1NoEndingPeriod      % H1 line does not end with period
        H1MatchesDoc          % Help text H1 line and reference page H1 line match
    end

    %Test results from see also & note line
    properties
        SeeAlsoCorrectNumItems % Number of functions linked in see also is within limits
        SeeAlsoOnlyOneLine     % Only one line for see also
        SeeAlsoNoEndingPeriod  % No period after see also line
        SeeAlsoMatchesDoc      % Number of see also's in doc match help text
        SeeAlsoCorrectFormat   % See also line formatted correctly within file
        NoteCorrectFormat      % Note line formatted correctly within file
    end
    
    %Overall test results
    properties
        SeeAlsoPassed
        NotePassed
        H1Passed
        GeneralCharacteristicsPassed
        HelpMatchesDoc
        AllTestsPassed
    end
    
    methods
        function obj = FileResult()
            %@FILERESULT Construct an instance of this class
            %Set default general characteristics
        obj.NoCopyright            = true;
        obj.UnderMaximumLineLength = true;
        obj.NoTrailingWhitespace   = true;
        obj.UnderMaximumNumLines   = true;
        obj.NoTabs                 = true;
        obj.NoHardcodedLinks       = true;
        obj.NoEvalLinks            = true;
        %Set default H1 characteristics
        obj.H1NoLeadingWhitespace  = true;
        obj.H1StartsWithFunction   = true;
        obj.H1NoEndingPeriod       = true;
        
        %Set default see also characteristics
        obj.SeeAlsoCorrectNumItems = true;
        obj.SeeAlsoOnlyOneLine     = true;
        obj.SeeAlsoNoEndingPeriod  = true;
        obj.SeeAlsoCorrectFormat   = true;
        %Set default note characteristics
        obj.NoteCorrectFormat      = true;
        %Set default doc-matching characteristics
        obj.H1MatchesDoc           = true;
        obj.SeeAlsoMatchesDoc      = true;
        end
        function result = get.SeeAlsoPassed(this)
            result = all([this.SeeAlsoCorrectNumItems, this.SeeAlsoOnlyOneLine, this.SeeAlsoNoEndingPeriod, this.SeeAlsoCorrectFormat]);
        end
        function result = get.HelpMatchesDoc(this)
            result = all([this.H1MatchesDoc, this.SeeAlsoMatchesDoc]);
        end
        function result = get.NotePassed(this)
            result = this.NoteCorrectFormat;
        end
        function result = get.H1Passed(this)
            result = all([this.H1NoEndingPeriod, this.H1NoLeadingWhitespace, this.H1StartsWithFunction]);
        end
        function result = get.GeneralCharacteristicsPassed(this)
            result = all([this.UnderMaximumLineLength, this.NoCopyright, this.NoTrailingWhitespace, this.NoTabs, this.NoHardcodedLinks, this.NoEvalLinks]);
        end
        function result = get.AllTestsPassed(this)
            result = all([this.SeeAlsoPassed, this.NotePassed, this.H1Passed, this.GeneralCharacteristicsPassed, this.HelpMatchesDoc]);
        end
    end
end

