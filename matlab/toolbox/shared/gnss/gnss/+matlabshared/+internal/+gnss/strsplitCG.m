function [splitStr, numElementsPerLine, ...
                    numElementsPerBlock] = strsplitCG(str)
%STRSPLITCG  Split string at delimiters
%   Reserved for MathWorks internal use only.

% This function splits the string at delimiters into SPLITSTR. It works
% similar to strsplit, and it is codegenable. It also returns the number of
% elements in each line, NUMELEMENTSPERLINE, and the number of elements in
% each block, NUMELEMENTSPERBLOCK. A new line is defined by a newline
% character and a new block is defined by a blank line.
%
%   Input Argument:
%       str                 - Character vector or string array
%
%   Output Arguments:
%       splitStr            - String array
%       numElementsPerLine  - Number of elements in each row
%       numElementsPerBlock - Number of elements in each block

%   Copyright 2022 The MathWorks, Inc.

%#codegen

    % Get the delimiters
    patternsToCheck = getPatternsToCheck();

    % Initialize variable for storing current string
    currentStr = '';
    % Initialize variable for storing split strings
    splitStr = cell(1,0);

    % Initialize variable for storing number of elements in a line
    numElementsPerLine = zeros(1,1);
    coder.varsize('numElementsPerLine',[inf,1],[1 0]);
    % Initialize variable for storing number of elements in a block
    numElementsPerBlock = zeros(1,1);
    coder.varsize('numElementsPerBlock', [inf,1],[1 0]);
    newBlockFlag = false;

    % Extract the strings
    for idx = 1:numel(str)
        % Keep updating current string till any delimiter is found
        if ~matches(str(idx), patternsToCheck)
            currentStr = [currentStr str(idx)]; %#ok<AGROW>
        else    % Delimiter found
            % If the current string is not empty then update the split
            % string array and update the count of number of elements
            if ~isempty(currentStr)
                if newBlockFlag
                    % Increase size of numElementsPerBlock
                    numElementsPerBlock = ...
                                    [numElementsPerBlock; 0]; %#ok<AGROW>
                    newBlockFlag = false;
                end
                splitStr{end+1} = currentStr;
                numElementsPerLine(end) = numElementsPerLine(end) + 1;
                numElementsPerBlock(end) = ...
                    numElementsPerBlock(end) + 1;
            end
            % A new line is found
            if contains(str(idx), newline)
                % Check if new block has also started
                if numElementsPerLine(end) == 0 && ...
                        numElementsPerBlock(end) ~= 0
                    % Set the flag for a new block
                    newBlockFlag = true;
                end
                % Increase size of numElementsPerLine
                numElementsPerLine = [numElementsPerLine; 0]; %#ok<AGROW>
            end
            % Empty the current string
            currentStr = '';
        end
    end
    % If current string is not empty after all the string is read, add
    % current string in split string array and update the count of number
    % of elements
    if ~isempty(currentStr)
        splitStr{end+1} = currentStr;
        numElementsPerLine(end) = numElementsPerLine(end) + 1;
        numElementsPerBlock(end) = numElementsPerBlock(end) + 1;
    end
end

function patternsToCheck = getPatternsToCheck()
    % The delimiters
    whiteSpace = char(32);      % ' '
    formFeed = char(12);        % '\f'
    newLine = newline;          % '\n'
    carriageReturn = char(13);  % '\r'
    horizontalTab = char(9);    % '\t'
    verticalTab = char(11);     % '\v'
    patternsToCheck = {whiteSpace, carriageReturn, newLine, ...
                       formFeed, horizontalTab, verticalTab};
end