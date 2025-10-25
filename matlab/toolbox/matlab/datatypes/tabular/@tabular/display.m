function display(obj, varargin) %#ok<DISPLAY> % Showing extra information.
%

% Copyright 2016-2024 The MathWorks, Inc.

import matlab.internal.display.lineSpacingCharacter

% Check if the table being displayed is bound to a variable.
if nargin == 1
    name = inputname(1);
else
    name = convertStringsToChars(varargin{1});
end

namedCall = ~isempty(name);

if feature('SuppressCommandLineOutput')
    if ~namedCall
        name = '';
    end
    matlab.internal.structuredoutput.signalVariableDisplay(obj, name)
else
    displayNewline = "\n"+lineSpacingCharacter;

    % If display is directly called, no varname is supplied.
    if ~namedCall
        varEquals = "";
    else
        varEquals = sprintf("%s =", name) + displayNewline;
    end
 
    % Ensure consistent formatting for special cases.
    if namedCall
        fprintf(lineSpacingCharacter);
    end
    
    % Print full header.
    fprintf(varEquals + getDisplayHeader(obj,name) + displayNewline);

    % Print table.
    truncate = shouldTruncate(obj);
    bold = true; indent = 4; fullChar = false; nestedLevel = 0; % defaults used in disp
    disp(obj,bold,indent,fullChar,nestedLevel,truncate);

    % Print hyperlink.
    if truncate
        printHyperlink(name, class(obj), height(obj));
    end
end
end

%-----------------------------------------------------------------------
function numRows = shouldTruncate(t)
    % Returns the number of rows from the beginning and end of t to display
    % if t should be truncated to fit in the command window and 0
    % otherwise.

    % the maximum distance users should have to scroll when their command
    % window is about the same size as the table height 
    scrollDistance = 5;
    tHeight = height(t);
    numRows = getNumRowsInTruncatedTable(tHeight);
    withinScrollRange = numRows <= (tHeight - scrollDistance);
    
    % check to see if we're displaying somewhere where hyperlinks work,
    % that the table height is higher than the 20 row threshold, and that
    % we're not truncating when the table can almost fit in the command
    % window. If all true, then truncate
    truncationThreshold = 20; % need at least 20 rows in the table to consider truncating it
    truncate = matlab.internal.display.isHot && tHeight > truncationThreshold && withinScrollRange;
    numRows = truncate * numRows;
end

%-----------------------------------------------------------------------
function numRows = getNumRowsInTruncatedTable(tHeight)
    import matlab.internal.display.formatSpacing;

    isLoose = (formatSpacing == "loose");
    cwHeight = getCommandWindowHeight();

    % Subtract the number of non-data lines (the cmd that displayed the table, the header,
    % ellipsis, link, the trailing command prompt, and blank lines) from the cmd window
    % height.
    numNonDataLines = 8 + isLoose*8;
    dynamicNumRows = floor((cwHeight - numNonDataLines)/2); % floor ensures the cmd is fully visible
    
    % then, choose either the default number of rows or the dynamic number
    % if the command window is large enough to handle it
    numRowsHalf = 5; % display at least 5 rows from the top and 5 rows from the bottom
    numRowsHalf = max(numRowsHalf,dynamicNumRows);

    % check to make sure that we're not printing more than half the table's
    % worth of rows from the top/bottom of obj
    if numRowsHalf >= tHeight/2
        numRowsHalf = floor(tHeight/2 - 1);
    end
    numRows = numRowsHalf * 2;
end

%-----------------------------------------------------------------------
function cwHeight = getCommandWindowHeight()
    % g2576521
    %cws = matlab.desktop.commandwindow.size;
    %cwHeight = cws(2);
    if isdeployed
        cwHeight = 25;
    else
        cwHeight = builtin('_getcmdwinrows');
    end
    % end g2576521
end

%-----------------------------------------------------------------------
function printHyperlink(tblName, tClass, tHeight)
    import matlab.internal.display.lineSpacingCharacter;
    % Construct the hyperlink. takes inputname here, as we have to grab
    % the variable from the workspace (not the variable given to us)
    msg = getString(message('MATLAB:tabular:DisplayLinkMissingVariable', tClass, tblName));
    % Before trying to display the whole timetable, the link will verify a
    % timetable with that name exists.
    codeToExecute = sprintf("if exist('%s','var') && istabular(%s),displayWholeObj(%s,'%s'),else,fprintf('%s\\n');end", tblName, tblName, tblName, tblName, msg);
    linkText = getString(message('MATLAB:tabular:DisplayAllRowsLink', tHeight));
    fprintf("\t<a href=""matlab:%s"">%s</a>\n"+lineSpacingCharacter,codeToExecute,linkText);
end
