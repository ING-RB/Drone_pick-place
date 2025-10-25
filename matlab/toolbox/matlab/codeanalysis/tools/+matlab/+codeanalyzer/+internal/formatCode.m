function formattedCode = formatCode(Code, Rows, Options)
% FORMATCODE Formats code.
%   F = formatCode(C) indents the input code according to the default
%   behavior.
%   F = formatCode(C,R,O) indents the code according to the
%   rows of R and options of O. These optional inputs are:
%    Rows: (Defaults)
%     StartRow (1)
%     EndRow (10000000)
%    Options: (Defaults)
%     IndentMode {'ClassicFunctionIndent', 'AllFunctionIndent', 'MixedFunctionIndent'} (AllFunctionIndent)
%     IndentSize 1 <= size <= 1024 (4)
%     UseSpacesInsteadOfTabs {true, false} (true)
%     TabSize 1 <= size <= 1024 (4)
%     BlankLineMode {'Indent', 'Ignore', 'RemoveWhitespace'} (Remove)
%
%   To parse code from a file, consider 'matlab.internal.getCode(File)'
%
%   This file is for internal use only and is subject to change without
%   notice.

%   Copyright 2023 The MathWorks, Inc.
    arguments
        Code char

        Rows.StartLine (1,1) uint32 {mustBeGreaterThan(Rows.StartLine,0), mustBeLessThan(Rows.StartLine,10000001)} = 1;
        Rows.EndLine (1,1) uint32 {mustBeGreaterThan(Rows.EndLine,0), mustBeLessThan(Rows.EndLine,10000001)} = 10000000;

        Options.IndentMode char {mustBeMember(Options.IndentMode, {'ClassicFunctionIndent', 'AllFunctionIndent', 'MixedFunctionIndent'})} = 'AllFunctionIndent';
        Options.IndentSize (1,1) uint32 {mustBeGreaterThan(Options.IndentSize,0), mustBeLessThan(Options.IndentSize,1025)} = 4;
        Options.UseSpacesInsteadOfTabs (1,1) logical = true;
        Options.TabSize (1,1) uint32 {mustBeGreaterThan(Options.TabSize,0), mustBeLessThan(Options.TabSize,1025)} = 4;
        Options.BlankLineMode char {mustBeMember(Options.BlankLineMode, {'Indent', 'Ignore', 'RemoveWhitespace'})} = 'RemoveWhitespace';
    end

    formattedCode = matlab.codeanalyzer.internal.format( ...
        Code, ...
        Rows.StartLine, Rows.EndLine, ...
        Options.UseSpacesInsteadOfTabs, Options.TabSize, ...
        Options.IndentMode, Options.IndentSize, ...
        Options.BlankLineMode);
end
