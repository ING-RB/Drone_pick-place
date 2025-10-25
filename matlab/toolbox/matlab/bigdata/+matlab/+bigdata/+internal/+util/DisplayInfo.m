%DisplayInfo Structure holding information required to display a tall array
%   Also includes underlying implementations of display methods.

% Copyright 2016-2023 The MathWorks, Inc.
classdef DisplayInfo
    properties (SetAccess = immutable, GetAccess = private)
        % Function to emit a blank line if necessary (tied to 'format loose')
        BlankLineFcn
    end
    properties (SetAccess = immutable)
        % Does the destination support hyperlinks
        IsHot
        % Do we have preview data
        IsPreviewAvailable
        % Name of the array we're displaying
        Name
        % Structure returned by getArrayInfo
        ArrayInfo
    end

    methods (Access = private)

        function printXEqualsLine(obj, dataClass, dataNDims, dataSize)
        % Print the "x = " line and also the array type/size line as appropriate.

        % We print the "x = " line if there's a name, and we know for sure that there
        % isn't a multi-dimensional preview coming.
            multiDimPreviewAvailable = obj.IsPreviewAvailable && ...
                dataNDims >= 3 && ...
                ~any(dataSize == 0);
            showNameLine = ~isempty(obj.Name) && ~multiDimPreviewAvailable;
            if showNameLine
                obj.blankLine();
                fprintf("%s =\n", obj.Name);
            end
            % Putting this blank line in isn't completely 100% compatible with all MATLAB
            % data types. Compare
            % display(ones(2,2,2,'single')) vs. display(caldays(ones(2,2,2)))
            obj.blankLine();

            % Now the size and type (with hotlinks if appropriate).
            % Tall data is always non-sparse
            isSparse = false;
            % Cannot call isreal on tall arrays (it would be a lazily evaluated
            % property in any case), so display all tall arrays is if they
            % are not complex. This means that tall(complex([])) doesn't display
            % the same as complex([]).
            isComplex = false;
            matlab.bigdata.internal.util.displaySizeTypeLine( ...
                'tall', dataClass, dataNDims, dataSize, isSparse, isComplex, obj.IsHot);
            obj.blankLine();
        end

        function displayPreviewData(obj, previewData, isTruncated)
        % Print out the preview data, adding the continuation characters as required.

            % For empty we do not print out any data, except for tabular
            % where the VariableNames are printed if possible.
            if isempty(previewData) && ...
                    (~istabular(previewData) || ...
                    (istabular(previewData) && size(previewData, 2) == 0))
                return
            elseif isempty(previewData) && istabular(previewData) ...
                    && size(previewData, 2) > 0
                % When displaying VariablesNames of an empty tabular,
                % display is never truncated.
                isTruncated = false;
            end

            % Start with the builtin DISP version - except for scalar
            % string objects so long as they are not <missing>.
            if isstring(previewData) && isscalar(previewData) && ~ismissing(previewData)
                previewText = iIndentScalarStringText(previewData);
            elseif ischar(previewData)
                previewText = iIndentCharText(previewData);
            elseif iscell(previewData)
                previewText = matlab.internal.display.getCellDisplayOutput(previewData);
            else
                previewText = evalc("disp(previewData)");
            end

            % Keep from the first to the last non-empty lines
            previewLines  = strsplit(previewText, newline, ...
                "CollapseDelimiters", false);
            nonEmptyLines = ~cellfun(@isempty, previewLines);
            previewLines  = previewLines(find(nonEmptyLines, 1, "first"):find(nonEmptyLines, 1, 'last'));

            % Remove any <strong></strong> tags from the display
            if ~obj.IsHot
                previewLines = regexprep(previewLines, "</?strong>", "");
            end

            if ~ismatrix(previewData)
                % For >2D data, prepend the variable name to the lines like "x(:,:,1) =". Also
                % note that some data type displays (e.g. datetime) miss pieces
                % out, and string adds extra whitespace.
                previewLines = regexprep(previewLines, "^(\(.*\))( =)?( *)$", [obj.Name, '$1$2$3']);
            end

            if isTruncated
                if istabular(previewData)
                    % Table display never wraps, so we can do something relatively simple here.
                    iDisplayTablePreviewLinesWithContinuation(previewLines);
                else
                    iDisplayTruncatedPreviewLines(obj.Name, previewData, previewLines);
                end
            else
                fprintf("%s\n", previewLines{:});
            end
            obj.blankLine();
        end

        function displayQueries(obj, dataNDims, dataSize)
        % Print a matrix of ? characters to indicate we don't know what's going on.
            maxQueriesToDisplay = matlab.bigdata.internal.util.defaultHeadTailRows();
            if any(dataSize == 0)
                % Value guaranteed empty, do not display queries.
            elseif isnan(dataNDims) || dataNDims > 2 || all(isnan(dataSize)) || ...
                    all(dataSize > maxQueriesToDisplay)
                % Print a matrix of ? for cases:
                % 1. NDims unknown
                % 2. NDims > 2
                % 3. NDims known, but all sizes unknown
                % 4. All dims > 3
                txt = [repmat(sprintf("    ?    ?    ?    ...\n"), 1, 3), ...
                       repmat(sprintf("    :    :    :\n"), 1, 2)];
                fprintf("%s", txt);
            else
                % Try and make the shape of the matrix reflect the known dimensions. Here, we
                % can assume 2-D. Treat unknown sizes as 3, and then clamp to the value
                % matlab.bigdata.internal.util.defaultHeadTailRows()

                extend = isnan(dataSize) | dataSize > maxQueriesToDisplay;
                dataSize(isnan(dataSize)) = 3;
                numQueries = min(maxQueriesToDisplay, dataSize);

                normalRow = repmat('    ?', 1, numQueries(2));
                if extend(2)
                    normalRow = [normalRow, '   ...'];
                end
                textRows = repmat({normalRow}, numQueries(1), 1);
                fprintf('%s\n', textRows{:});
                if extend(1)
                    extendRow = repmat('    :', 1, numQueries(2));
                    fprintf('%s\n%s\n', extendRow, extendRow);
                end
            end
            obj.blankLine();
        end

        function displayHint(obj)
            if obj.IsHot
                % Only display the hint in 'hot' mode where the hyperlink can function.
                fprintf("%s\n", getString(message("MATLAB:bigdata:array:UnevaluatedArrayDisplayFooter")));
                obj.blankLine();
            end
        end
    end

    methods
        function obj = DisplayInfo(name, arrayInfo)
            obj.Name = name;
            formatSpacing = matlab.internal.display.formatSpacing();
            obj.IsHot = matlab.internal.display.isHot;
            if isequal(formatSpacing, "compact")
                obj.BlankLineFcn = @()[];
            else
                obj.BlankLineFcn = @() fprintf('\n');
            end
            obj.IsPreviewAvailable = arrayInfo.IsPreviewAvailable;
            obj.ArrayInfo = arrayInfo;
        end
        function blankLine(obj)
            feval(obj.BlankLineFcn);
        end
        function doDisplay(obj)
            printXEqualsLine(obj, obj.ArrayInfo.Class, obj.ArrayInfo.Ndims, obj.ArrayInfo.Size);
            if obj.IsPreviewAvailable
                displayPreviewData(obj, obj.ArrayInfo.PreviewData, obj.ArrayInfo.IsPreviewTruncated);
            else
                displayQueries(obj, obj.ArrayInfo.Ndims, obj.ArrayInfo.Size);
                displayHint(obj);
            end
        end
        function doDisplayWithFabricatedPreview(obj, fabricatedPreview, previewClass, dataNDims, dataSize)
        % Call this to apply a fabricated preview array. The fabricated preview is
        % presumed to be truncated.
            printXEqualsLine(obj, previewClass, dataNDims, dataSize);
            isPreviewTruncated = isnan(dataNDims) || size(fabricatedPreview, 1) ~= dataSize(1);
            displayPreviewData(obj, fabricatedPreview, isPreviewTruncated);
            displayHint(obj);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Given a line of display content, generate a line of continuation
% indicators. We look for groups of non-space characters, and place a single
% ":" in the middle of each group.
function contLine = iGetContinuationLineFromContentLine(txtLine)
    % Find extents of non-whitespace characters
    nonSpaceGroups = regexp(txtLine, "(\S*)", "tokenExtents");
    if isempty(nonSpaceGroups)
        % Get here if txtLine is completely empty (don't think that can happen) or
        % contains only whitespace (can happen for char display). Either way,
        % treat first column as non-whitespace.
        contLine = ':';
    else
        % Find the middle of the non-whitespace groups
        contPosns = floor(cellfun(@mean, nonSpaceGroups));
        % Make a string that has ':' at the middle of each group.
        contLine  = repmat(' ', 1, max(contPosns));
        contLine(contPosns) = ':';
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iDisplayTablePreviewLinesWithContinuation(previewLines)
% We're looking for the table display '___' lines, here
% we always need to remove the <strong> tags first.
% This uses [^\w<>/ ]? to work around PLT, which inserts test characters
% into translatable messages, including the <strong> tags.
% To avoid this problem completely, we should strive to avoid parsing the
% non-tall table display.
    previewLinesNoEmph = regexprep(previewLines, '[^\w<>/ ]?<[^\w<>/ ]?/?strong>[^\w<>/ ]?', '');
    linesMatch         = regexp(previewLinesNoEmph, '^(_|\s)+$');
    lineIdx            = find(~cellfun(@isempty, linesMatch), 1, 'first');
    txtLine            = previewLinesNoEmph{lineIdx};
    contLine           = iGetContinuationLineFromContentLine(txtLine);
    fprintf('%s\n', previewLines{:}, contLine, contLine);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For display purposes, this divides a cell array of lines into chunks delimited
% by the supplied regular expression. Because of the way the display stuff
% works, the first chunk returned contains all lines preceding the first
% occurence of the regular expression, at most one instance of that regular
% expression, and then a bunch of lines up to but not including the next
% instance of the regular expression. For example, given output like this:
%
% 1
% 1 Columns 1 through 3
% 1
% 1   0.7742    0.4527    0.8970
% 1   0.0822    0.1448    0.4540
% 1   0.7278    0.0879    0.8887
% 1
% 2 Column 4
% 2
% 2   0.4053
% 2   0.5513
% 2   0.0864
% 2
%
% The preceding digits indicate which chunk the line would count as, presuming a
% delimiter of '^\s*(Columns \d+ through \d+|Column \d+)$'.
function chunks = iDivideLinesIntoChunksByRegexp(allLines, delimiterRegexp)
    matchingLines = find(~cellfun(@isempty, regexp(allLines, delimiterRegexp)));
    if numel(matchingLines) < 1
        % Either zero or one delimiters - return all output as a single chunk.
        chunks = {allLines};
    else
        chunks = cell(1, numel(matchingLines));
        startIdx = [1, matchingLines(2:end)];
        endIdx = [matchingLines(2:end) - 1, numel(allLines)];
        for idx = 1:numel(matchingLines)
            chunks{idx} = allLines(startIdx(idx):endIdx(idx));
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iDisplayTruncatedPreviewLinesOneSetOfColumns(linesOneSetOfColumns)
    nonEmptyLines = ~cellfun(@isempty, linesOneSetOfColumns);
    firstNonBlank = find(nonEmptyLines, 1, "first");
    lastNonBlank  = find(nonEmptyLines, 1, "last");
    linesOneSetOfColumnsTrimmed  = linesOneSetOfColumns(firstNonBlank:lastNonBlank);
    contLine = iGetContinuationLineFromContentLine(linesOneSetOfColumnsTrimmed{end});
    fprintf('%s\n', linesOneSetOfColumnsTrimmed{:}, contLine, contLine, ...
            linesOneSetOfColumns{lastNonBlank+1:end});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function expression = iGetColumnDelimiterRegexp()
    str1 = getString(message("MATLAB:services:printmat:Columns",999,999));
    str1 = iEscapeForRegexp(str1);
    str2 = getString(message("MATLAB:services:printmat:Column",999));
    str2 = iEscapeForRegexp(str2);
    expression = ['^\s*(', strrep(str1, '999', '\d+'), '|', ...
                  strrep(str2, '999', '\d+'), ')$'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = iEscapeForRegexp(str)
str = regexptranslate('escape', str);
% This groups together non-language characters into a "\W+". We do this to
% avoid issues in PLT.
str = regexprep(str, '\W+', '\\W\+');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iDisplayTruncatedPreviewLinesOnePage(linesOnePage)
% On this page, find the last non-blank line and use that to generate
% continuations.

    columnDelimiterRegexp = iGetColumnDelimiterRegexp();
    columnChunks = iDivideLinesIntoChunksByRegexp(linesOnePage, columnDelimiterRegexp);
    cellfun(@iDisplayTruncatedPreviewLinesOneSetOfColumns, columnChunks);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iDisplayTruncatedPreviewLines(varName, ~, previewLines)
% First, split into pages
    pageDelimiterRegexp = ['^', varName, '\([^\)]+\)( =)? *$'];
    pageChunks = iDivideLinesIntoChunksByRegexp(previewLines,pageDelimiterRegexp);
    cellfun(@iDisplayTruncatedPreviewLinesOnePage, pageChunks);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add leading spaces to each line for a scalar string. Non-scalar strings work
% fine using the "disp" version of the data.
function indentedText = iIndentScalarStringText(stringText)
    % First, convert \r\n to \n
    stringText = strrep(stringText, compose("\r\n"), compose("\n"));
    % Finally, indent lines correctly by replacing either \r or \n to indentation
    stringText = strrep(stringText, compose("\n"), compose("\n     "));
    stringText = strrep(stringText, compose("\r"), compose("\r     "));
    indentedText = sprintf("    ""%s""", stringText);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Indent char data for display. "disp" output is no use here.
function indentedText = iIndentCharText(charText)
    if isrow(charText)
        % A single char vector - in this case, we simply need to indent the text and add
        % quotes.
        indentedText = sprintf('    ''%s''', ...
                               strrep(charText, newline, sprintf('\n     ')));
    else
        % Start by converting the char array into a string array, using NUM2CELL to
        % reduce each row into a cell.
        stringRows   = string(num2cell(charText, 2)); %#ok<NASGU> used in EVALC

        % Here we are relying on string/disp to do the right thing in terms of adding
        % linefeed and arrow characters.
        indentedText = evalc('disp(stringRows)');

        % Fix up quotes - change " to '.
        indentedText = regexprep(indentedText, '^(\s+)"', '$1''', 'lineanchors');
        indentedText = regexprep(indentedText, '"$', '''', 'lineanchors');

        % Fix up whitespace added by string display to match what should be emitted by
        % char display.
        indentedText = regexprep(indentedText, '= $', '=', 'lineanchors');
    end
end
