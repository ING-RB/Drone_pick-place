classdef ScriptBuilder < matlabshared.testmeasapps.internal.ITestable

    %SCRIPTBUILDER is a builder utility class that is used to generate
    %MATLAB code.
    % The Text is the generated script content.
    % E.g.
    % >> scriptBuilder = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder
    % >> scriptBuilder.addNewLine();
    % >> scriptBuilder.addSectionHeader("This is a Section Header");
    % >> scriptBuilder.addComment("Do an assignment");
    % >> commentLine = "This will assign a value '5' to a variable 'data'. This is just an example.";
    % >> scriptBuilder.addComment(commentLine);
    % >> scriptBuilder.addCodeLine("data = 5;");
    %
    % % View the Text
    % >> scriptBuilder.getText()
    %
    %      %% This is a Section Header
    %      % Do an assignment
    %      % This will assign a value '5' to a
    %      % variable 'data'. This is just an
    %      % example.
    %      data = 5;
    %
    % % Generate MATLAB code
    % >> scriptBuilder.createMFile();

    %  Copyright 2021-2023 The MathWorks, Inc.

    properties(Access = ?matlabshared.testmeasapps.internal.ITestable, SetObservable)

        % The text of the generated script, containing the comments and the
        % code.
        Text (1, 1) string
    end

    properties (Constant)
        SectionHeaderPrefix = "%%" + blanks(1)

        Space (1, 1) string = blanks(1)
        EmptyDelimiter (1, 1) string = ""

        CodeDelimiter (1, :) string = blanks(1)
        CommentDelimiter (1, 1) string = blanks(1)

        CodeNewlineSeparator (1, 1) string = "..."
        CommentNewLineSeparator (1, 1) string = ""

        CodeNewlineStarter (1, 1) string = blanks(4)
        CommentNewLineStarter (1, 1) string = ""

        CodePrefix (1, 1) string = ""
        CommentPrefix (1, 1) string = "%" + blanks(1)

        CodeWordSeparator (1, 1) string = blanks(1)
        CommentWordSeparator (1, 1) string = blanks(1)

        DelimiterDictionary = dictionary(["code", "comment"], ...
            [matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CodeDelimiter, ...
            matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CommentDelimiter] ...
            )

        NewLineSeparatorDictionary = dictionary(["code", "comment"], ...
            [matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CodeNewlineSeparator, ...
            matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CommentNewLineSeparator] ...
            )

        NewLineStarterDictionary = dictionary(["code", "comment"], ...
            [matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CodeNewlineStarter, ...
            matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CommentNewLineStarter] ...
            )

        PrefixDictionary = dictionary(["code", "comment"], ...
            [matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CodePrefix, ...
            matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CommentPrefix] ...
            )

        WordSeparatorDictionary = dictionary(["code", "comment"], ...
            [matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CodeWordSeparator, ...
            matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.CommentWordSeparator] ...
            )
    end

    properties
        % Maximum number of characters in a comment line. Words exceeding
        % this limit will go to the next comment line
        CommentLength = 90
    end

    methods
        function text = getText(obj)
            % Returns the Text of the Generate Code Helper
            text = obj.Text;
        end

        function text = setText(obj, text)
            % Set the text value of the Generate Code Helper. This could be
            % useful if the user has a string ready externally to be
            % generated as a script, assign the text and generate the
            % script.

            arguments
                obj
                text (1, 1) string
            end

            obj.Text = text;
        end

        function text = addNewLine(obj)
            % Adds an empty new line to the Text.
            % Syntax:
            % scriptBuilder.addNewLine();
            % This adds a newline to text.

            text = newline;
            obj.Text = obj.Text + text;
        end

        function sectionHeaderText = addSectionHeader(obj, sectionHeaderText)
            % Adds a Section Header to Text on a newline.
            % Syntax:
            % scriptBuilder.addSectionHeader("This is a Section Header");
            % This adds
            % %% This is a Section Header
            % to the Text.

            arguments
                obj
                sectionHeaderText (1, 1) string
            end

            sectionHeaderText = string(sectionHeaderText);
            sectionHeaderText = obj.SectionHeaderPrefix + sectionHeaderText;
            obj.addText(sectionHeaderText);
        end

        function finalCommentLine = addComment(obj, commentText)
            % Adds Comment to Text on a newline. The
            % comment is formatted such that words fitting inside obj.CommentLength
            % number of characters are fitted in 1 line. Words exceeding
            % obj.CommentLength are moved to a new line. The
            % "CommentPrefix" text is also included in the comment length,
            % Syntax:
            % scriptBuilder.addComment("This is a Comment");
            % This adds
            %   % This is a Comment
            % to the Text.

            arguments
                obj
                commentText (1, 1) string
            end

            if isempty(commentText) || commentText == ""
                return
            end

            % Prepare the indented comment line.
            finalCommentLine = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.getIndentedText("comment", commentText, obj.CommentLength);
            obj.addText(finalCommentLine);
        end

        function codeText = addCodeLineWithSemiColon(obj, codeText)
            % Adds a code line to Text on a newline. If the line of code
            % does not end with semi-colon, automatically assign semicilon
            % to the end of the code line. If the line ends with a
            % semicolon, does not add new semicolon to the end of the line.
            % Syntax:
            % scriptBuilder.addCodeLineWithSemiColon("a = 5");
            % This adds
            %   a = 5;
            % to the Text.
            %
            % scriptBuilder.addCodeLineWithSemiColon("b = 10;");
            % This adds
            %   b = 10;
            % to the Text.

            arguments
                obj
                codeText (1, 1) string
            end

            if ~endsWith(codeText, ";")
                codeText = codeText + ";";
            end
            codeText = obj.addCodeLine(codeText);
        end

        function finalLine = addCodeLineTruncatedWithSemicolon(obj, codeText)
            % Adds the codeline to Text on a newline. The codeline is
            % formatted such that words fitting inside obj.CommentLength
            % number of characters are fitted in 1 line. Words exceeding
            % obj.CommentLength are moved to a new line.
            %
            % Syntax:
            %
            % codeline = "s = serialport('COM3', 38400); dev = ividev('AgInfiniuum', Simulate=true); u = udpport; validateattributes(input, ['string', 'char'])";
            %
            % scriptBuilder.addCodeLineTruncatedWithSemicolon(codeline);
            %
            % adds
            %   "s = serialport('COM3', 38400); dev = ividev('AgInfiniuum', Simulate=true); u = udpport; ...
            %    validateattributes(input, ['string', 'char']);"
            %
            % to the Text.

            arguments
                obj
                codeText (1, 1) string
            end

            if ~endsWith(codeText, ";")
                codeText = codeText + ";";
            end

            % Prepare the indented code line
            finalLine = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.getIndentedText("code", codeText, obj.CommentLength);
            obj.addText(finalLine);
        end

        function codeText = addCodeLine(obj, codeText)
            % Adds a code line to Text on a newline. It does not check or
            % append semicolons. This could be useful for lines of code
            % that do not terminate with a semicolon, like loops,
            % conditional statements, etc.
            % Syntax:
            % scriptBuilder.addCodeLine("if a == 5");
            % This adds
            %  if a == 5
            % to the Text.

            arguments
                obj
                codeText (1, 1) string
            end
            obj.addText(codeText);
        end

        function text = insertSpaces(obj, count)
            % Adds a white space to the string.
            % count - number of white spaces to add to string.
            %         Default: 1
            % scriptBuilder.insertSpaces();
            % This adds 1 space
            arguments
                obj
                count (1, 1) {mustBeNumeric, mustBeFinite, mustBeNonzero, mustBeNonempty, mustBeInteger} = 1
            end
            text = join(repmat(obj.Space, 1, count), obj.EmptyDelimiter);
            obj.Text = obj.Text + text;
        end

        function createMFile(obj)
            % Creates an untitled script in the MATLAB editor.
            mFileInstance = matlab.desktop.editor.newDocument(obj.Text);

            % Indent the contents.
            mFileInstance.smartIndentContents;
        end

        function createMLXFile(obj)
            % Creates an untitled MLX script in the MATLAB editor. No need
            % to indent as indentation happens automatically in an MLX.

            matlab.internal.liveeditor.openAsLiveCode(obj.Text);
        end

        function clearText(obj)
            % Clears the Text of the generate code helper.
            % Syntax:
            % scriptBuilder.clearText();
            obj.Text = "";
        end
    end

    methods (Access = {?matlabshared.testmeasapps.internal.ITestable})
        function addText(obj, text)
            % Add a line of text

            if strlength(obj.Text) ~= 0
                obj.Text = obj.Text + newline + text;
            else
                obj.Text = obj.Text + text;
            end
        end
    end

    methods (Static, Access = ?matlabshared.testmeasapps.internal.ITestable)
        function indentedText = getIndentedText(type, completeText, indentationLimit)
            % Indent the comment or code line based on the indentationLimit

            arguments
                type (1, 1) string {mustBeMember(type, ["code", "comment"])}
                completeText (1, 1) string
                indentationLimit (1, 1) double
            end

            % Get the prefix, delimiter, newlineSeparator, and
            % wordSeparator sub-strings based on "type".
            prefix = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.PrefixDictionary(type);
            delimiters = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.DelimiterDictionary(type);
            newlineSeparator = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.NewLineSeparatorDictionary(type);
            newlineStarter = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.NewLineStarterDictionary(type);
            wordSeparator = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder.WordSeparatorDictionary(type);

            % If the entire line fits in 1 line, no need for further
            % processing or indentation.
            if strlength(prefix) + strlength(completeText) < indentationLimit
                indentedText = prefix + completeText;
                return
            end

            % Start preparing the indented lines.
            eachLine = prefix;

            % Split the words in the string.
            commentTextSplit = strsplit(completeText, delimiters);

            % Create each line, based on the indentationLimit size.
            for word = commentTextSplit

                % If length of current "eachLine" and length of current
                % word is less than the indentation limit, add the word to
                % the same line, else create a new line.
                if strlength(eachLine(end)) + strlength(word) >= indentationLimit

                    % If the word is the first word of the line and the
                    % word itself is greater than the desired length,
                    % ignore the length and just add the word.
                    if eachLine(end) == prefix
                        eachLine(end) = eachLine(end) + word + wordSeparator;
                        continue
                    end
                    eachLine(end) = eachLine(end) + newlineSeparator;

                    % Create a new line.
                    eachLine(end+1) = prefix + newlineStarter; %#ok<AGROW>
                end

                eachLine(end) = eachLine(end) + word + wordSeparator;
            end

            % Remove the trailing spaces from all the lines, if any.
            eachLine = strip(eachLine, "right");
            indentedText = join(eachLine, newline);
        end
    end
end