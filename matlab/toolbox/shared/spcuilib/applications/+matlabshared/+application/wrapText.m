function paragraphs = wrapText(str, hTxt, hContainer)
%wrapLine Wrap the text onto separate lines.

%   Copyright 2013-2017 The MathWorks, Inc.

oldunits = hTxt.Units;
oldstr   = hTxt.String;
oldvis   = hTxt.Visible;

% Hide the text to avoid showing the tweaking of strings.  Force into pixels so we can compare
% pixels of extent with the width of the container
set(hTxt, 'Visible', 'Off', 'Units', 'pixels');
if nargin < 3
    hContainer = get(hTxt, 'Parent');
end

% Add optional numeric input for container to specify the width directly.
if isnumeric(hContainer) && ~ishghandle(hContainer)
    width = hContainer;
else
    pos = getpixelposition(hContainer);
    width = pos(3);
end

% we want to keep the paragraphs together, split those before going into the accumulation stage.  If
% we dont do this then the paragraphs may end up on the same line as each other.
paragraphs = strsplit(str, newline, 'CollapseDelimiters', false);

for indx = 1:numel(paragraphs)
    paragraph = paragraphs{indx};
    if isempty(paragraph)
        paragraphs{indx} = ' ';
        continue;
    end
    set(hTxt, 'String', paragraph);
    ext = get(hTxt, 'Extent');

    % If the paragraph fits in the width, move on to the next one, there's nothing to do here.
    if ext(3) < width
        paragraphs{indx} = {paragraph};
        continue;
    end

    % Convert the paragraph into individual words or characters (for ch, ja, ko, etc.)
    brokenText = matlab.internal.display.printWrapped(paragraph, 1);

    % Remove any trailing spaces or newline feeds
    brokenText = strtrim(brokenText);

    % Break the newline feed split string into a cell array for easier manipulation.
    brokenText = strsplit(brokenText, newline);

    % Add the spaces back in if they exist.  They will be removed later.  We need them to put
    % partial strings back together.
    for jndx = 1:numel(brokenText)
        paragraph(1:numel(brokenText{jndx})) = [];
        if ~isempty(paragraph)
            brokenText{jndx} = [brokenText{jndx} repmat(' ', 1, find(paragraph ~= ' ', 1, 'first') - 1)];
        end
        paragraph = strtrim(paragraph);
    end
    breakIndex = 1;

    outstr = {};
    while breakIndex <= numel(brokenText)

        newString = brokenText{breakIndex};

        % Set the ext to 0 so that it always goes into the loop once.  No matter the extent of
        % newString at this point, we always have to put it on its own line because its the first
        % word that can go onto that line.
        ext(3) = 0;
        while ext(3) < width

            % Remember the current string, we may need to use it to avoid going over.
            lastString = newString;

            % If the breakIndex is passed the size of the broken text, break, we're done.
            breakIndex = breakIndex + 1;
            if breakIndex > numel(brokenText)
                break;
            end

            % Add the next string/word/char and get the extent to test if the 2+ word string still
            % fits in the width available.
            newString = [newString brokenText{breakIndex}];
            set(hTxt, 'String', newString);
            ext = get(hTxt, 'Extent');
        end

        % When we leave the loop, the newString was too large, use the lastString instead.
        outstr{end + 1} = lastString; %#ok<*AGROW>
    end

    paragraphs{indx} = outstr;
end

withSpaces = horzcat(paragraphs{:});
paragraphs = strtrim(withSpaces);

set(hTxt, 'String', oldstr, 'Visible', oldvis, 'Units', oldunits);

% for testing, we need the spaces
setappdata(hTxt, 'WrapTextWithSpaces', withSpaces);

% [EOF]
