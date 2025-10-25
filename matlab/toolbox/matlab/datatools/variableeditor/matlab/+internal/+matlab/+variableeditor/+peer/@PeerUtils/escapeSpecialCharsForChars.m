% Function handles \n and \t from strings by converting them to char arrays with
% char(10) and char(9) respectively. For example, 'a\nb\tc' -> ['a' char(10) 'b'
% char(10) 'c']

% Copyright 2014-2023 The MathWorks, Inc.

function formattedData = escapeSpecialCharsForChars(data)
    tabChar = char(8594);
    newlineChar = char(8629); % In nodesktop mode, getNewLineCharacter  returns '...', account for the unicode newline char
    % that we get from the client side for the right codegen.
    nbspChar = char(160);
    if any(regexp(data, '\n|\t')) || ...
            contains(data, matlab.internal.display.getNewlineCharacter(newline)) || ...
            contains(data, newlineChar) || ...
            contains(data, tabChar)

        % Input data already comes enclosed in '',
        data = regexprep(data,'(^''|''$)','');
        data = ['[''' data ''']'];
        s = strrep(data, newline, ''' newline ''');
        s = strrep(s, matlab.internal.display.getNewlineCharacter(newline), ''' newline ''');
        s = strrep(s, newlineChar, ''' newline ''');
        s = strrep(s, sprintf('\t'), ''' char(9) ''');
        s = strrep(s, tabChar, ''' char(9) ''');
        formattedData = char(s);
    else
        formattedData = data;
    end
    % Replace non-breaking spaces with ML spaces as client formats the string
    % with nbsp.
    formattedData = strrep(formattedData, nbspChar, ' ');
end