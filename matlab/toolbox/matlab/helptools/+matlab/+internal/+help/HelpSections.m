classdef HelpSections < handle
    %HELPSECTIONS parses help command into its various parts, including:
    % - The H1 Line
    % - The See Also section
    % - The note section
    % - The syntax section
    % - The example section
    % - Invalid help sections
    % - Blank lines between sections
    % - Overloaded methods
    % - Links to published demos
    % - Folders

    % Copyright 2009-2024 The MathWorks, Inc.

    properties % arrays of matlab.internal.help.AtomicHelpSections
        Raw               (1,1) matlab.internal.help.AtomicHelpSections % Input help text
        H1                (1,:) char                                    % H1 Line
        SeeAlso           (1,:) matlab.internal.help.AtomicHelpSections % See Also section.
        Note              (1,:) matlab.internal.help.AtomicHelpSections % Note section under See Also section
        Usages            (1,:) string                                  % usage headers
        Syntax            (1,:) matlab.internal.help.AtomicHelpSections % Syntax section
        Example           (1,:) matlab.internal.help.AtomicHelpSections % Examples
        ClassMembers      (1,:) matlab.internal.help.AtomicHelpSections % ClassMembers
        Invalid           (1,:) matlab.internal.help.AtomicHelpSections % invalid help part
        FoldersNamed      (1,1) matlab.internal.help.AtomicHelpSections % Folders named section
        Demo              (1,1) matlab.internal.help.AtomicHelpSections % Demo section
        OverloadedMethods (1,1) matlab.internal.help.AtomicHelpSections % Overloaded Methods
    end


    methods
        function this = HelpSections(fullHelpText, fcnName, packageName, inClass)
            arguments
                fullHelpText {mustBeTextScalar};
                fcnName      {mustBeTextScalar} = '\w+';
                packageName  {mustBeTextScalar} = '';
                inClass      (1,1) logical      = false;
            end
            % Constructor takes help comments and extracts specific parts

            fullHelpText = convertStringsToChars(fullHelpText);
            fcnName      = convertStringsToChars(fcnName);
            packageName  = convertStringsToChars(packageName);

            this.Raw = matlab.internal.help.AtomicHelpSections([],fullHelpText, 0);
            helpForBanner = getString(message('MATLAB:help:HelpForBanner', ''));
            bannerPrefix = append(extractBefore(helpForBanner, ' '), ' ');
            if startsWith(fullHelpText, bannerPrefix)
                n2 = append(newline, newline);
                banner = append(extractBefore(fullHelpText, n2), n2);
                fullHelpText = extractAfter(fullHelpText, n2);
            else
                isBothBanner = getString(message('MATLAB:help:IsBothBanner', fcnName));
                if startsWith(fullHelpText, isBothBanner)
                    fullHelpText = extractAfter(fullHelpText, isBothBanner);
                    banner = isBothBanner;
                else
                    banner = '';
                end
            end
            if contains(fullHelpText, newline)
                this.H1 = extractBefore(fullHelpText, newline);
                this.H1 = append(this.H1, newline);
                rest = extractAfter(fullHelpText, newline);
            else
                this.H1 = fullHelpText;
                rest = '';
            end
            this.H1 = append(banner, this.H1);

            % Getting out overloaded methods
            this = getProcessedHelpPart(this, message('MATLAB:introspective:help:OverloadedMethods', fcnName), 'OverloadedMethods');
            this = getProcessedHelpPart(this, message('MATLAB:introspective:displayHelp:PublishedOutputInTheHelpBrowser'), 'Demo');
            this = getProcessedHelpPart(this, message('MATLAB:helpUtils:displayHelp:FoldersNamed', regexptranslate('flexible', fcnName, '[\\/]')), 'FoldersNamed');

            % Get out paragraphs
            [paragraphs, blankLines] = split(rest, newline + optionalPattern(whitespacePattern) + newline);
            paragraphs = append(paragraphs, [blankLines; {''}]);

            lastKind = "Invalid";

            if inClass
                classMembersPattern = generateHotlinkMatchPattern(packageName, fcnName);
            else
                classMembersPattern = '';
            end

            packagedName = matlab.lang.internal.introspective.makePackagedName(packageName, fcnName);
            seeAlsoEnglish = getString(message('MATLAB:introspective:helpParts:SeeAlso'));
            seeAlsoTranslated = getString(message('MATLAB:introspective:helpParts:SeeAlsoSingleSource'));
            seeAlsoHeader = append('(', seeAlsoEnglish, '|', seeAlsoTranslated, ')');
            seeAlsoPattern = append('(?<title>\s*', seeAlsoHeader, '\>:?.*?\>)(?<body>.*)');
            note = getString(message('MATLAB:introspective:helpParts:Note'));

            seenExample = false;
            % For each paragraph, check which help part it is
            for j = 1:numel(paragraphs)
                paragraph = paragraphs{j};

                if ~seenExample
                    litParagraph = matlab.internal.help.highlightHelp(strip(paragraph), packagedName, fcnName, '<FUNCTION>', '</FUNCTION>');
                    usage = regexp(litParagraph, functionPattern, 'match', 'once');
                    usage = strip(regexprep(usage, '</?FUNCTION>', ''));
                else
                    usage = "";
                end

                currentSection = matlab.internal.help.AtomicHelpSections('', paragraph, j);
                if usage ~= "" && contains(usage, ["=","(", " "])
                    this.Syntax = [this.Syntax, currentSection];
                    this.Usages(end+1) = usage; %#ok<*AGROW>
                else
                    % Check if the paragraph is an example, note, or see also
                    match = regexpi(paragraph, append('^(?<example>)(?<title>[%\s]*example[^\n]*)(?<body>.*)|^(?<note>)(?<title>\s*', note, '\>:?.*?\>)(?<body>.*)|^(?<seealso>)', seeAlsoPattern), 'names', 'once');
                    if isempty(match)
                        if inClass && (lastKind == "ClassMembers" || ~isempty(regexpi(paragraph, classMembersPattern, 'dotexceptnewline', 'once')))
                            this.ClassMembers = [this.ClassMembers, matlab.internal.help.AtomicHelpSections('', paragraph, j)];
                            lastKind = "ClassMembers";
                        elseif lastKind == "Example"
                            this.Example = [this.Example, currentSection];
                        else
                            this.Invalid = [this.Invalid, currentSection];
                            lastKind = "Invalid";
                        end
                    else
                        currentSection.title   = match.title;
                        currentSection.helpStr = match.body;
                        if ischar(match.example)
                            this.Example = [this.Example, currentSection];
                            lastKind = "Example";
                            seenExample = true;
                        elseif ischar(match.note)
                            this.Invalid = [this.Invalid, this.Note];
                            this.Note = currentSection;
                            lastKind = "Note";
                        else
                            assert(ischar(match.seealso))
                            this.Invalid = [this.Invalid, this.SeeAlso];
                            this.SeeAlso = currentSection;
                            lastKind = "SeeAlso";
                        end
                    end
                end
            end
            if isempty(this.SeeAlso)
                match = regexpi(currentSection.helpStr, append('^(?<before>.*\n)', seeAlsoPattern), 'names', 'once', 'lineanchors');
                if ~isempty(match)
                    currentSection.helpStr = match.before;
                    this.SeeAlso = matlab.internal.help.AtomicHelpSections(match.title, match.body, currentSection.paragraphNumber+1);
                end
            end
        end
    end

    methods
        function allHelpText = getFullHelpText(this)
            allParts = [this.Invalid, this.SeeAlso, this.Note, this.Syntax, this.Example, this.ClassMembers];
            [~, ind] = sort([allParts.paragraphNumber]);
            allParts = allParts(ind);
            allHelpText = this.H1;
            if ~isempty(allParts)
                numParts = numel(allParts);
                remainingParts = cell(1, numParts*2);
                remainingParts(1:2:end) = {allParts.title};
                remainingParts(2:2:end) = {allParts.helpStr};
                remainingParts = join(remainingParts, '');
                allHelpText = append(allHelpText, remainingParts{1});
            end
        end

        function this = getProcessedHelpPart(this, message, helpPart)
            messagePattern = getString(message);
            parts = regexpi(this.Raw.helpStr, append('(?<beforeHeader>.*^\s*)(?<header>', messagePattern, '\>:?)\n(?<body>.*)'), 'names', 'once','lineanchors');
            if ~isempty(parts)
                whiteLine = regexp(parts.body, '\n\s*\n', 'once');
                if ~isempty(whiteLine)
                    parts.body = parts.body(1:whiteLine-1);
                end
                this.(helpPart) = matlab.internal.help.AtomicHelpSections(parts.header, parts.body, 0);
            end
        end
    end
end

function pattern = generateHotlinkMatchPattern(packageName, className)
    % generateHotlinkMatchPattern generates a match pattern from message
    % catalog messages based upon the cell array of matchers passed in

    matchers = {'Methods', 'Functions','Properties','Events','Enumerations'};
    patternList = cell(size(matchers));

    for i = 1:numel(matchers)
        patternList{i}   = getString(message(append('MATLAB:helpUtils:helpProcess:', matchers{i}), className));
    end

    pattern = strjoin(patternList,'|');
    pattern = regexptranslate('flexible', pattern, '\s+');

    if packageName ~= ""
        packageName = append('(', packageName, '\.)?');
    end

    pattern = append('^\s*', packageName, '(?:', pattern, ').*:\s*(?m:$)');
end

function o = optional(p)
    o = "(?:" + p + ")?";
end

function k = kleene(p)
    k = "(?:" + p + ")*";
end

function w = white
    w = kleene("[ \t]");
end

function e = either(p1, p2)
    e = "(?:" + p1 + "|" + p2 + ")";
end

function c = capture(name, p)
    c = "(?<" + name + ">" + p + ")";
end

function ite = ifThenElse(name, pt, pf)
    ite = "(?(" + name + ")" + pt + "|" + pf + ")";
end

function fp = functionPattern
    lazy = ".*?";
    bracketed = "\[" + lazy + "\]";
    nested = "\(" + lazy + "\)";
    parenthesized = "\((" + nested + "|.)*?\)";
    lhs = capture("lhs", optional(either("\S+", bracketed) + white + "=" + white));
    fcnName = "<FUNCTION>\S*?</FUNCTION>";
    cmdArgs = kleene("\s+-?[A-Z.]+\>");
    rhs = ifThenElse("lhs", optional(parenthesized), either(parenthesized, cmdArgs));
    fp = "^" + lhs + fcnName + white + rhs;
end
