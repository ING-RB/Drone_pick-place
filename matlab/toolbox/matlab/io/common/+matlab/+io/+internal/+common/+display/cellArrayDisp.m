function cellArrayStr = cellArrayDisp(cellArr, isFile, nlSpacing, numItems)
% cellArrayDisp helper function to extract cell array of strings and
% display

%   Copyright 2014-2022 The MathWorks, Inc.

import matlab.internal.display.getNewlineCharacter;
% maximum number of strings that we display using cellArrayDisp
persistent NL CR NLSYM CRSYM;
if isempty(NL)
    NL = newline;
    CR = char(13);
    NLSYM = getNewlineCharacter(NL);
    CRSYM = getNewlineCharacter(CR);
end
MAX_STRINGS_DISPLAYED_IN_CELL = 3;

if nargin < 4
    % get num items
    numItems = numel(cellArr);
end

% separator for strings in a cell array. This is a sprintf(', ') for
% variable names formats etc. This is a sprintf(',\n') for Files.
stringSeparator = ', ';

% for files newlineBool is always true
if iscolumn(cellArr)
    stringSeparator = '; ';
end
if isFile
    stringSeparator = [';' newline];
end

ind = MAX_STRINGS_DISPLAYED_IN_CELL;
if numItems < ind
    ind = numItems;
end

% initialize and grow the cell str
cellArrayStr = '{';
if isFile && numItems > 0
    cellArrayStr = [cellArrayStr, newline];
end

% ind is always <= 3
for i=1:ind
    cellArrStr = cellArr{i};
    % newlines in the data should be represented with the arrow characters.
    if any(contains(cellArrStr,{NL,CR}),'all')
        cellArrStr = replace(cellArrStr,{NL,CR},...% \n or \r 
                                        {NLSYM,CRSYM}); % arrows
    end
    numChars = numel(cellArrStr);
    % handle empty chars in cellstr for future clients of cellArrayDisp
    if (numChars == 0)
        if i < ind
            cellArrayStr = [cellArrayStr, '''''', stringSeparator]; %#ok<AGROW>
        else
            cellArrayStr = [cellArrayStr, '''''']; %#ok<AGROW>
            stringSeparator = '';
        end
        continue;
    end

    % ensure large number of chars in cells are also displayed properly
    if (numChars > 70)
        % If 71 chars, indices=2:71
        cellArrStr = cellArrStr(numChars-69:numChars);
        % Try to find a file separator in the string
        k = strfind(cellArrStr, filesep);
        if isempty(k)
            cellArrStr = [' ...', cellArrStr]; %#ok<AGROW>
        else
            % if found, trim leading characters to the first file separator
            cellArrStr = [' ...', cellArrStr(k(1):numel(cellArrStr))];
        end
    end

    % handle the last of the 3 strings with a different string separator
    if (i == ind)
        stringSeparator = '';
        if isFile
            stringSeparator = newline;
        end
    end

    cellArrayStr = [cellArrayStr, nlSpacing, '''', ...
        cellArrStr, '''', stringSeparator]; %#ok<AGROW>
end

if (numItems > 3)
    cellArrayStr = [cellArrayStr, nlSpacing, ...
                 sprintf(' ... and %d more', numItems-3), stringSeparator];
end
cellArrayStr = [cellArrayStr, nlSpacing, '}'];

end
