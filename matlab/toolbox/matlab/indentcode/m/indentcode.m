function indentedText = indentcode(text)
    % INDENTCODE Indents code.
    %   I = INDENTCODE(T) indents the text T according to the MATLAB
    %   language indenting preferences. When indenting text, INDENTCODE
    %   retains the same line separator style used by the input text.
    %
    %   This file is for internal use only and is subject to change without
    %   notice.

    %   Copyright 2012-2024 The MathWorks, Inc.

    if ~ischar(text) && ~isStringScalar(text)
        error(message('MATLAB:INDENTCODE:NotString'))
    end

    % Return early if empty input
    if (ischar(text) && isempty(text)) || (isstring(text) && text == "")
        indentedText = text;
        return;
    end

    % Perform indenting
    s = settings;

    % Not pass-through since Editor does not have 'Ignore' option
    if s.matlab.editor.indent.PadEmptyLines.ActiveValue == true
        BlankLineMode = 'Indent';
    else
        BlankLineMode = 'RemoveWhitespace';
    end

    % Call the C++ formatter API for 'matlab'
    % By default, all lines are indented in indentcode, so 'startLine'
    % and 'endLine' use default values
    indentedText = matlab.codeanalyzer.internal.formatCode(text, ...
        IndentMode = s.matlab.editor.language.matlab.FunctionIndentingFormat.ActiveValue, ...
        IndentSize = s.matlab.editor.tab.IndentSize.ActiveValue, ...
        UseSpacesInsteadOfTabs = s.matlab.editor.tab.InsertSpaces.ActiveValue, ...
        TabSize = s.matlab.editor.tab.TabSize.ActiveValue, ...
        BlankLineMode = BlankLineMode);

end
