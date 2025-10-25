function disp(t,bold,indent,fullChar,nestedLevel,truncate)
%

%DISP Display a table.
%   DISP(T) prints the table T, including variable names and row names (if
%   present), without printing the table name.  In all other ways it's the same
%   as leaving the semicolon off an expression. If truncate is nonzero (such as
%   when disp is called from display), disp will display the top half of the
%   table (the first truncate/2 rows), then a row of ellipses, then the bottom
%   half of the table (the last truncate/2 rows). If truncate is greater
%   than 0, it must be an even integer.
%
%   For numeric or categorical variables that are 2-dimensional and have 3 or
%   fewer columns, DISP prints the actual data using either short g, long g,
%   or bank format, depending on the current command line setting.  Otherwise,
%   DISP prints the size and type of each table element.
%
%   For character variables that are 2-dimensional and 10 or c characters
%   wide, DISP prints quoted strings.  Otherwise, DISP prints the size and
%   type of each table element.
%
%   For cell variables that are 2-dimensional and have 3 or fewer columns,
%   DISP prints the contents of each cell (or its size and type if too large).
%   Otherwise, DISP prints the size of each table element.
%
%   For other types of variables, DISP prints the size and type of each
%   table element.
%
%   See also TABLE, DISPLAY, FORMAT.

%   Copyright 2012-2024 The MathWorks, Inc.

% Follow the cmd window's format settings as possible
import matlab.internal.display.lineSpacingCharacter;
import matlab.internal.display.formatSpacing;
import matlab.internal.tabular.display.nSpaces;
import matlab.internal.tabular.display.boldifyLabels;
import matlab.internal.tabular.display.vectorizedWrappedLength;
import matlab.internal.tabular.display.boldifyLinks;
import matlab.internal.tabular.display.containsRegexp;
import matlab.internal.tabular.display.alignTabularContents;
import matlab.internal.tabular.display.alignTabularVar;

if nargin < 2, bold = true; end
if nargin < 3, indent = 4; end
if nargin < 4, fullChar = false; end
if nargin < 5, nestedLevel = 0; end
if nargin < 6, truncate = false; end

% A tabular var within the current tabular causes disp to be called recursively, and
% deepestLevel is how each of those calls reports how many levels of tabular nesting there
% are below each tabular var. myDeepestLevel saves the max of those across the current
% tabular's vars, and is what the current call to disp reports back to _its_ caller as
% deepestLevel.
persistent deepestLevel
deepestLevel = nestedLevel;
myDeepestLevel = nestedLevel;

if truncate
    numRows = truncate;
    t = truncateTabular(t, numRows);
end

between = 4;
headerIndent = indent;
ellipsisIndent = indent;
betweenColSpaces = 2;
maxNumVarColsToDisp = 25;
maxCharWidthToDisp = 100;
maxNumNestedLevelsToToDisp = 4; % outer table, plus 4 nested levels
isLoose = (formatSpacing == "loose");

lostWidth = zeros(t.rowDim.length,1);
marginChars = nSpaces(indent);
[dblFmt,snglFmt] = getFloatFormats();
 
bold = matlab.internal.display.isHot() && bold;
strongBegin = ''; strongEnd = '';
if bold
    strongBegin = getString(message('MATLAB:table:localizedStrings:StrongBegin'));
    strongEnd = getString(message('MATLAB:table:localizedStrings:StrongEnd'));
end

% Display a nonempty table or timetable
% or an empty timetable with rows (and thus row times), but no variables
% or an empty table/timetable with variables, but no rows.
if (t.varDim.length > 0) || (t.rowDim.length > 0 && t.dispRowLabelsHeader)
    if t.rowDim.hasLabels
        [marginChars,lostWidth,rowLabelsDispWidth,rowDimName,rowDimNameDispWidth,headerIndent,ellipsisIndent] = getRowMargin(t,lostWidth,between,indent,bold);
    end

    % Boldify variable names and figure out their wrapped length.
    varNames = string(t.varDim.labels);
    % Replace LF with "knuckle" tab with "arrow", and CR with "backarrow".
    % This also truncates long lines, but is irrelevant here.
    % Replaces hyperlinks with no display text with ''.
    varNames = matlab.display.internal.vectorizedTruncateLine(varNames,10000);
    varNameOrigNumChars = strlength(varNames);
    varNameDispWidths = varNameOrigNumChars;
    [varNames, liesAboutWidth] = boldifyLabels(varNames,bold,strongBegin,strongEnd);
    for idx = 1:numel(varNames)
        liesAboutWidth(idx) = liesAboutWidth(idx) || any(varNames{idx} > char(128));
    end
    varNameDispWidths(liesAboutWidth) = vectorizedWrappedLength(varNames(liesAboutWidth));
    varNameDispWidths = ceil(varNameDispWidths);

    varDispWidths = zeros(1,t.varDim.length);
    nestedVarHeaderStrs = strings(0,t.varDim.length); % grows to two lines for each nested level, varnames and underlines
    tblChars = strings(t.rowDim.length,t.varDim.length);

    if t.rowDim.length == 0
        % Set widths of variables, underlines, and the row name to
        % the variable names when there are no rows to display.
        varDispWidths = varNameDispWidths;
        if t.dispRowLabelsHeader
            rowLabelsDispWidth = rowDimNameDispWidth;
        end
    else
        % Determine the display widths of variables
        % variables, underlines, ... for when there are > 0 rows.

        % Check if MATLAB desktop is available and pass that to truncateLine so
        % it does not need to perform that check every iteration of the for
        % loop
        doesMATLABUseDesktop = matlab.internal.display.isDesktopInUse;

        for ivar = 1:t.varDim.length
            var = t.data{ivar};

            % Let the compact display mixin handle display. Eventually as more classes
            % inherit from the mixin, their special case code below will be removed,
            % leaving only this and the outer class+size fallback display below.
            if isa(var,'matlab.mixin.CustomCompactDisplayProvider')
                availableWidth = 50;
                displayConfig = matlab.display.DisplayConfiguration("Columnar");
                displayConfig.DataDelimiters = "";
                finalRep = compactRepresentation(var,displayConfig,availableWidth);
                varStr = finalRep.PaddedDisplayOutput;
                [varStr,maxVarLen,lostWidth] = alignTabularVar(varStr,lostWidth,finalRep.CharacterWidth);

            elseif ischar(var)
                if ismatrix(var) && (fullChar || (size(var,2) <= maxCharWidthToDisp))
                    % Display individual strings for a char variable that is 2D and no
                    % more than 10 chars.
                    varStr = string(var);
                else
                    % Otherwise, display a description of the chars.
                    varStr = getInfoDisplay(var);
                end
                [varStr,maxVarLen,lostWidth] = alignTabularContents(varStr,lostWidth);

            else
                % Display the individual data if the var is 2D and no more than 5 columns.
                if ~isempty(var) && ismatrix(var) && (size(var,2) <= maxNumVarColsToDisp)
                    if isnumeric(var) && ~isenum(var)
                        if isa(var,'double')
                            varChars = num2str(var,dblFmt);
                        elseif isfloat(var) % single, or fallback for any other floating point type
                            varChars = num2str(var,snglFmt);
                        elseif isa(var,'uint8') || isa(var,'uint16') || isa(var,'uint32') || isa(var,'uint64')
                            varChars = num2str(var,'%u    ');
                        elseif isinteger(var) % standard signed integers, or fallback for any other integer type
                            varChars = num2str(var,'%d    ');
                        else % fallback for anything numeric that fails isfloat or isinteger
                            varChars = num2str(var);
                        end
                        varStr = string(varChars);
                        maxVarLen = max(strlength(varStr));
                    elseif islogical(var)
                        % Display the logical values using meaningful names.
                        tf = ["false" "true "];
                        s = reshape(tf(1+var),size(var));
                        varStr = s.join(nSpaces(betweenColSpaces),2);
                        maxVarLen = max(strlength(varStr));
                    elseif isa(var,'categorical') || isa(var,'datetime') || isa(var,'duration') || isa(var,'calendarDuration')
                        if isa(var,'categorical')
                            checkChars = categories(var);
                            padSide = 'right';
                        else
                            checkChars = {var.Format};
                            padSide = 'left';
                        end

                        % Convert values to a string array. String is a data
                        % conversion, so missing values need to be handled
                        % specially.
                        varStr = string(var);
                        miss = var(1); miss(1) = missing; miss = char(miss);
                        varStr(ismissing(varStr)) = miss;

                        tagged = containsRegexp(checkChars,'<a\s+href\s*=|<strong>');
                        if any(any(char(checkChars) > 127)) || any(tagged(:))
                            % Align the var data display accounting for wide chars
                            % or markup in a category name or a date/time format.
                            [varStr, ~, ~] = alignTabularContents(varStr);
                            varStr = varStr.join(nSpaces(betweenColSpaces),2);
                            [varStr,maxVarLen,lostWidth] = alignTabularContents(varStr,lostWidth);
                        else
                            % Otherwise, no wide chars or markup, just pad to equal
                            % number of chars.
                            varStr = pad(varStr,padSide,' ');
                            varStr = varStr.join(nSpaces(betweenColSpaces),2);
                            maxVarLen = max(strlength(varStr));
                        end
                    elseif isstring(var)
                        if isscalar(var) && ~ismissing(var)
                            % Scalar string displays specially, which is not what we
                            % want inside a table. Truncate long text, replace LF
                            % with "knuckle", tab with "arrow", and CR with "backarrow".
                            var = matlab.internal.display.truncateLine(var{1},10000,doesMATLABUseDesktop);
                            % Scalar strings display without quotes, add them to the
                            % string itself.
                            var = '"' + string(var) + '"';
                        end
                        varStr = getStrOutput(var);
                        [varStr,maxVarLen,lostWidth] = alignTabularContents(varStr,lostWidth);
                    elseif iscell(var)
                        if isscalar(var) && ischar(var{1}) && ~isempty(var{1})
                            % One-row char displays specially, which is not what we
                            % want inside a table. Truncate long text, replace LF with
                            % "knuckle", tab with "arrow", and CR with "backarrow".
                            % But avoid truncateLine on empty char; it turns 1x0 into
                            % '', a 0x0.
                            var = {matlab.internal.display.truncateLine(var{1},10000,doesMATLABUseDesktop)};
                        end
                        varStr = getStrOutput(var);
                        [varStr,maxVarLen,lostWidth] = alignTabularContents(varStr,lostWidth);
                    elseif isenum(var)
                        % Convert enum values to strings. value names don't contain
                        % wide chars or markup, just pad to equal number of chars.
                        varStr = pad(getStrOutput(var),' ');
                        maxVarLen = max(strlength(varStr));
                    elseif isa(var,'tabular') && (nestedLevel < maxNumNestedLevelsToToDisp-1) % nestedLevel is 0 for outermost tabular
                        % Get the nested tabular's disp, bold per caller, no indent, and
                        % whatever char disp setting our caller gave us. Tell the nested
                        % tabular that it's one level deeper than we are.
                        varChars = evalc('disp(var,bold,0,fullChar,nestedLevel+1)');
                        varStr = splitlines(string(varChars));

                        % Save the first few lines of the nested tabular's display, i.e. its
                        % var names, its underlines, and any header lines from deeper nesting
                        % (two rows for each level, names/underlines). Then chop them off
                        % the from data display. format loose adds one blank line per level.
                        numNestedHeaderRows = (2 + isLoose)*(deepestLevel - nestedLevel);
                        nestedVarHeaderStrs(1:numNestedHeaderRows,ivar) = varStr(1:numNestedHeaderRows);
                        varStr(1:numNestedHeaderRows) = [];
                        varStr(varStr == "") = []; % trailing newlines

                        % Find the maximum width of the nested tabular's data display.
                        % This accounts for any wide chars in the nested tabular's
                        % data or row names. It does not explicitly account for the
                        % width of the nested tabular's var names, which will become
                        % an extra header line for the outer tabular. But tabular/disp
                        % creates (approx) equal-length lines of text for the nested
                        % tabular, including its var names header line, so their width
                        % need not be accounted for separately.
                        [varStr,maxVarLen,lostWidth] = alignTabularContents(varStr,lostWidth);

                        % Track the deepest nesting across all of the current tabular's vars.
                        myDeepestLevel = max(deepestLevel,myDeepestLevel);
                    else
                        % Display a description of each table element.
                        varStr = getInfoDisplay(var);
                        maxVarLen = max(strlength(varStr));
                    end

                else
                    % The variable is not a CustomCompactDisplayProvider, and it's not 2D, or it's
                    % empty, or it's too wide to show. Display a description of each table element.
                    varStr = getInfoDisplay(var);
                    maxVarLen = max(strlength(varStr));
                end
            end

            if maxVarLen < varNameDispWidths(ivar)
                % If the var name is wider than the var's data display, pad the
                % latter with spaces to center the data under the varname
                varDataPad = varNameDispWidths(ivar) - maxVarLen;
                varStr = getPaddedStr(varStr, varDataPad);
                maxVarLen = varNameDispWidths(ivar);
            end
            varDispWidths(ivar) = maxVarLen;
            tblChars(:,ivar) = varStr;
        end
    end

    % Report the deepest level of nesting in the current tabular to our caller.
    deepestLevel = myDeepestLevel;

    headerLines = alignHeaderLines(nestedVarHeaderStrs);
    for i = 1:height(headerLines)
        disp(char(headerLines(i)));
    end

    indentChars = nSpaces(ellipsisIndent);
    if (t.varDim.length > 0)
        tblChars = marginChars + tblChars.join('    ',2);
    else
        % Displaying a timetable with no variables.
        % Strip the space after the rowtimes, since that is all that will
        % be displayed.
        tblChars = strip(marginChars,"right");
    end
    for row = 1:t.rowDim.length
        if row == t.rowDim.length/2+1 && truncate
            fprintf(lineSpacingCharacter);
            % start by checking if we're displaying a timetable or a table
            % with row labels. add the ellipsis here because it's not
            % held in the same array as other variables
            ellipsis = ':';  % set colon as a vertical ellipsis
            ellipsisWidth = 1;
            if t.rowDim.hasLabels
                varDataPad = rowLabelsDispWidth - ellipsisWidth;
                ellipsisStr = getPaddedStr(ellipsis, varDataPad);
                ellipsisStr = indentChars + ellipsisStr;
                fprintf("%s",ellipsisStr);
            end

            % print ellipses with spacing based on variable widths
            remainderWidth = 0;
            for w = 1:length(varDispWidths)
                % get the ellipsis string with appropriate padding
                % (including accounting for extra wide/narrow characters)
                [ellipsisStr, remainderWidth] = getEllipsisString(w, remainderWidth, varDispWidths, ellipsis, ellipsisWidth);
                ellipsisStr = nSpaces(between) + ellipsisStr;
                fprintf("%s",ellipsisStr);
            end

            fprintf(lineSpacingCharacter);
            fprintf(newline); % lineSpacingCharacter gets eaten by 'format compact', but \n does not
        end

        disp(char(tblChars(row,:)));
    end
    fprintf(lineSpacingCharacter);
end

%-----------------------------------------------------------------------
    function headerLines = alignHeaderLines(nestedVarHeaderStrs)
        varNameStrs = strings(1,t.varDim.length);
        ulStrs = strings(1,t.varDim.length);

        if height(nestedVarHeaderStrs) > 0
            % Nested var header lines in columns in nestedVarHeaderStrs corresponding
            % to non-tabular vars have never been assigned to, and so are <missing>.
            % Fill with "", and they will ultimately be padded with spaces to the
            % correct width.
            nestedVarHeaderStrs(ismissing(nestedVarHeaderStrs)) = "";
        
            % Get the actual display width of each header string. In most cases strings in
            % one column are all the same display width, but it's possible for a column to
            % have empty strings below non-empty strings.
            nestedVarHeaderDispWidths = ceil(vectorizedWrappedLength(nestedVarHeaderStrs));
        end

        % The data disp captured for each var has already been padded to be at least as
        % wide as the var name (varNameDispWidths) but the name may need to be padded to
        % the data display widths (varDispWidths). This padding accounts for a display
        % width different than the number of chars in the name due to:
            % * Strong tags
            % * Hyperlinks (and thus no strong tags)
            % * Wide characters
        % * Narrow characters or wide-displaying characters that don't report to be
        %   wide (nothing to be done about those).
        for ii = 1:t.varDim.length
            varname = varNames(ii);
            % Pad variable names if necessary to match the data display width.
            numPadChars = varDispWidths(ii) - varNameDispWidths(ii); % non-negative
            varNameStrs(ii) = pad(varname, strlength(varname) + numPadChars,'both',' ');
            % Create underlines under each variable name to the full data display width.
            ulStrs(ii) = nUnder(varDispWidths(ii));

            % Nested header strings corresponding to nested tabular vars were captured
            % from actual disp of the nested tabular, but were captured as a stand-alone
            % tabular, so their display widths may need to be padded to account for wide
            % var names above them. Nested header strings corresponding to non-tabular
            % vars are "", those definitely need padding.
            if height(nestedVarHeaderStrs) > 0
                numPadChars = varDispWidths(ii) - nestedVarHeaderDispWidths(:,ii);
                nestedVarHeaderStrs(:,ii) = pad(nestedVarHeaderStrs(:,ii), strlength(nestedVarHeaderStrs(:,ii)) + numPadChars,'both',' ');
            end
        end
        
        if t.dispRowLabelsHeader
            % Need to print the name of the rowDim; add it to the left edge of the header.
            numPadChars = rowLabelsDispWidth - rowDimNameDispWidth; % non-negative
            varNameStrs = [pad(rowDimName, strlength(rowDimName) + numPadChars,'both',' '), varNameStrs];
            ulStrs = [nUnder(rowLabelsDispWidth), ulStrs];
            nestedVarHeaderStrs = [repmat(nSpaces(rowLabelsDispWidth),height(nestedVarHeaderStrs),1), nestedVarHeaderStrs];
        end
        
        % Join all the variable names and underlines with spaces.
        spacesBetween = string(nSpaces(between));
        headerIndentChars = nSpaces(headerIndent);
        
        headerLines = [headerIndentChars + join(varNameStrs,spacesBetween,2); ...
                       headerIndentChars + join(strongBegin + ulStrs + strongEnd, spacesBetween,2) + lineSpacingCharacter; ...
                       headerIndentChars + join(nestedVarHeaderStrs,spacesBetween,2)];
    end

end % main function

%-----------------------------------------------------------------------
function subTable = truncateTabular(t, numRows) 
    % Grab a subset of the table; basically just the top and bottom N rows of the table.
    numRowsHalf = numRows/2;
    tHeight = height(t);
    subTable = t([(1:numRowsHalf),(tHeight-numRowsHalf+1:tHeight)],:);
end

%-----------------------------------------------------------------------
function varStr = getPaddedStr(varStr, varDataPad)
    % Pad the variable's data with spaces to center the data within the
    % variable. Need to do this explicitly, because while each line has
    % (approx) the same display width, they may have different numbers
    % of chars due to wide chars and markup, and pad requires a common
    % target width. 
    import matlab.internal.tabular.display.nSpaces;
    numRightSpaces = ceil(varDataPad/2);
    numLeftSpaces = varDataPad - numRightSpaces;
    varStr = nSpaces(ceil(numLeftSpaces)) + varStr + nSpaces(numRightSpaces);
end

%-----------------------------------------------------------------------
function [paddedEllipsis, remainderWidth] = getEllipsisString(currVar, remainderWidth, dispWidthArr, ellipsis, ellipsisWidth)
    % When using Unicode characters, e.g. ellipses, we have to consider
    % that some characters may be thinner/wider than others and require
    % some form of padding. Keep track of the "remainder" width, and if
    % it exceeds 1 then remove/add a single space from our display.
    if remainderWidth > 1
        % if the ellipsis is wider than 1, we've pushed the display
        % over too far. so, remove a space from our display by
        % subtracting one from the variable's width
        dispWidthArr(currVar) = dispWidthArr(currVar) - 1;
        remainderWidth = mod(remainderWidth,1);
    else
        % otherwise, we don't need to adjust spacing
    end

    % next, get the actual padded ellipsis
    varDataPad = dispWidthArr(currVar) - ellipsisWidth;
    paddedEllipsis = getPaddedStr(ellipsis, varDataPad);
end

%-----------------------------------------------------------------------
function out = getStrOutput(v)
% Let the built-in cell/string/enum disp method show the contents
% of each element however it sees fit. For example, cell disp will
% display only a size/type if the contents are large, and puts
% quotes around char contents, which char wouldn't. Any newlines in
% the data are replaced with arrows, so splitlines is guaranteed to
% split on elements as opposed to newlines within the data.
% Therefore, deleting empty newlines should not change underlying
% data.
import matlab.display.internal.cellDisplayWithoutHeader
if iscell(v)
    out = strip(splitlines(cellDisplayWithoutHeader(v)));
else
    out = strip(splitlines(string(evalc('disp(v)'))));
end
out(out == "") = [];

% If the command window is narrow, the display will page. If the var is
% string or cellstr, "unfold" the paged display.
if length(out) ~= size(v,1)
    if isstring(v)
        quoteChar = """";
        missingString = "<missing>";
        out = unfoldPagedTextDisplay(v,quoteChar,missingString);
    elseif iscellstr(v)
        quoteChar = "'";
        missingString = "''";
        out = unfoldPagedTextDisplay(v,quoteChar,missingString);
    else % non-cellstr cell or enumeration
        % Fall back to showing just size and type for each element
        out = getInfoDisplay(v);
    end
end
end

%-----------------------------------------------------------------------
function out = unfoldPagedTextDisplay(v,quoteChar,missingString)
% Get an estimate of the command window width by truncating a long char
winLenEstimate = strlength(matlab.internal.display.truncateLine(nUnder(100000)));

final = strings(size(v));
missingVals = ismissing(v);
final(~missingVals) = quoteChar + matlab.display.internal.vectorizedTruncateLine(v(~missingVals),winLenEstimate/size(v,2)) + quoteChar;
final(missingVals) = missingString;
final = matlab.internal.tabular.display.alignTabularContents(final);
out = join(final,'    ',2);
end

%-----------------------------------------------------------------------
function [dblFmt,snglFmt] = getFloatFormats()
% Display for double/single will follow 'format long/short g/e' or 'format bank'
% from the command window. 'format long/short' (no 'g/e') is not supported
% because it often needs to print a leading scale factor.
switch lower(matlab.internal.display.format)
case {'short' 'shortg' 'shorteng'}
    dblFmt  = '%.5g    ';
    snglFmt = '%.5g    ';
case {'long' 'longg' 'longeng'}
    dblFmt  = '%.15g    ';
    snglFmt = '%.7g    ';
case 'shorte'
    dblFmt  = '%.4e    ';
    snglFmt = '%.4e    ';
case 'longe'
    dblFmt  = '%.14e    ';
    snglFmt = '%.6e    ';
case 'bank'
    dblFmt  = '%.2f    ';
    snglFmt = '%.2f    ';
otherwise % rat, hex, + fall back to shortg
    dblFmt  = '%.5g    ';
    snglFmt = '%.5g    ';
end
end

%-----------------------------------------------------------------------
function varStr = getInfoDisplay(var)
sz = size(var);
szFmt = matlab.internal.display.getDimensionSpecifier + "%d";
if iscell(var)
    leftDelim = "{"; rightDelim = "}";
else
    % NO brackets around size+class info display.
    leftDelim = ""; rightDelim = "";
end
szStr = leftDelim + "1" + join(compose(szFmt,sz(2:end)),"");
varStr = repmat(compose("%s %s"+rightDelim,szStr, class(var)),sz(1),1);
end

%-----------------------------------------------------------------------
function ul = nUnder(n)
    ul = string(repmat('_',1,n));
end
