classdef CodeFormattingParser < appdesigner.internal.serialization.loader.interface.DecoratorLoader
    %CODEFORMATTINGPARSER A decorator which parses mlapp file code for how
    %code formatting options were saved:
    % -indent Size
    % -spaces for Tabs
    % -function formatting style

    % Copyright 2020-2021 The MathWorks, Inc.

    properties (Access = private)
        AppCode
    end

    properties (Constant)
        ClassicFunctionIndenting = 'ClassicFunctionIndent';
        MixedFunctionIndenting = 'MixedFunctionIndent';
    end

    methods
        function obj = CodeFormattingParser(loader, appCode)
            obj@appdesigner.internal.serialization.loader.interface.DecoratorLoader(loader);
            obj.AppCode = appCode;
        end

        function appData = load(obj)
            appData = obj.Loader.load();

            if ( ~isfield(appData.code, 'codeFormatting'))
                appData.code.codeFormatting = obj.parseCodeFormatting();
            end
        end
    end

    methods (Access = private)
        function formattingData = parseCodeFormatting(obj)
            % PARSECODEFORMATTING looking at the code which was saved from
            % file, parse for the three values which client side needs to
            % re-generate the user's app code under the original
            % preferences. if this fails for any reason we default to what
            % the original values of the code engine prior to 21a, and
            % allows the app to continue loading. At worst the app code
            % will load dirty for formatting differences, but not code
            % differences. We use the readonly "delete (app)" method since
            % this is out of the users control and is quick to find

            formattingData = struct;

            try
                splitLines = splitlines(obj.AppCode);

                [codeLine, lineNumber] = obj.getFirstFunctionCodeLine(splitLines);

                spacing = obj.getSpacing(codeLine, 'function');

                formattingData.InsertSpaces = obj.isSpacesForTabs(spacing);

                formattingData.IndentSize = obj.getIndentSize(spacing, formattingData.InsertSpaces);

                formattingData.FunctionIndentingFormat = obj.getFunctionFormattingStyle(...
                    splitLines, lineNumber, formattingData.IndentSize, formattingData.InsertSpaces);
            catch ex
                % revert to defaults which the code engine used prior to 21a
                formattingData.InsertSpaces = true;

                formattingData.IndentSize = 4;

                formattingData.FunctionIndentingFormat = 'MixedFunctionIndent';
            end
        end

        function [codeLine, lineNumber] = getFirstFunctionCodeLine(~, splitLines)
            % GETFIRSTFUNCTIONCODELINE iterates from the bottom of the app
            % code upwards to find the first function declaration,
            % returning the line of code and what line number it was found
            % on. Will continue iterating until it finds a function with
            % content (empty functions will not work).

            % iterate up until
            for i = length(splitLines):-1:1
                % The word 'function' is found outside of a comment
                [startIdx, ~] = regexp(strtrim(splitLines(i)),'^function+\s+[\w\=\s\[\]\,]+\s*+\(', 'once');
                if ~isempty(startIdx{1}) && startIdx{1} == 1
                    % iterate down until
                    for checkIndex = i:length(splitLines)
                        trimmed = char(strtrim(splitLines(checkIndex)));

                        % end token is found, continue looking
                        if strcmp(trimmed, 'end')
                            break;
                            % function has code in it, done.
                        elseif ~strcmp(trimmed, '') && ~contains(trimmed, 'function ')
                            lineNumber = i;
                            codeLine = splitLines(i);
                            return;
                        end
                    end
                end
            end
        end

        function spacesForTabs = isSpacesForTabs(~, spacePrefix)
            % ISSPACESFORTABS determines whether spaces are used for
            % indentation or tabs
            asciiValues = double(char(spacePrefix));
            firstChar = asciiValues(1);

            if firstChar == 9
                spacesForTabs = false;
            else
                spacesForTabs = true;
            end
        end

        function indentSize = getIndentSize(~, spacePrefix, insertSpaces)
            % GETINDENTSIZE using the argued indentation determine how many
            % spaces are used per tab. CodeEngine will generate the line of
            % code we're parsing at an indent depth of 2. If the user is
            % loading an app which uses tabs for spaces this number will
            % not be utilized, instead just return the default

            generatedIndentDepth = 2;

            if insertSpaces
                indentSize = strlength(spacePrefix) / generatedIndentDepth;
            else
                indentSize = generatedIndentDepth;
            end
        end

        function functionFormattingStyle = getFunctionFormattingStyle(obj, ...
                splitLines, codeLineNumber, indentSize, insertSpaces)
            % GETFUNCTIONFORMATTINGSTYLE looks at the first line of code
            % within the delete method to determine if the code engine
            % generated in either mixed or classic function indenting mode

            contentLine = '';

            % search for the first line of code of the delete method
            for i = codeLineNumber + 1:length(splitLines)
                if ~isempty(char(strtrim(splitLines(i))))
                    contentLine = splitLines(i);
                    break;
                end
                if strcmp(strtrim(splitLines(i)), 'end')
                    throw('searched through all of a function without finding any content');
                end
            end

            % we never found our code line to parse - fail out of this and
            % let the parser default to the fallbacks
            if isempty(contentLine)
                throw('unable to find line of code to parse');
            end

            spacing = obj.getSpacing(contentLine, strtrim(contentLine));

            if insertSpaces
                depth = strlength(spacing) / indentSize;
            else
                depth = length(double(char(spacing)));
            end

            % code engine will generate this line with a indentation depth
            % of 3, if it's less, that means we're in "classic" mode
            if (depth < 3)
                functionFormattingStyle = obj.ClassicFunctionIndenting;
            else
                functionFormattingStyle = obj.MixedFunctionIndenting;
            end
        end

        function spacing = getSpacing(~, codeLine, token)
            % GETSPACING helper function used in the main parsing entry
            % point to get the indentation leading up to the argued token

            parts = split(codeLine, token);

            spacing = parts(1);
        end
    end
end
