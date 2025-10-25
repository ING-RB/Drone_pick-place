function [shape,referenceHeight] = wordshape(words,weights,height,props,screenWidth)
% This internal helper function may be removed in a future release.

% [SHAPE, REFHEIGHT] = WORDSHAPE(WORDS,WEIGHTS,HEIGHT,PROPS) computes shape
% information about each word in WORDS given font sizes WEIGHTS*REFHEIGHT. The
% preferred REFHEIGHT is HEIGHT (in pixels). PROPS is a structure of text properties.
%
% WORDSHAPE(__, SCREENWIDTH) optionally passes in the screen width in pixels.
%
% Shape is M-by-N where each column encodes bounds info about the corresponding
% word shape. Each column is [wl wr md ma d1 a1 d2 a2 ... ] where 
% 'wl' and 'wr' are the widths in pixels from center to left and right most pixels
% 'dn' and 'an' are the descent and ascent in pixels of the nth column of pix
% along the string. The ascent and descent are relative to the center line.
% wl+wr is the number of pairs [dn an] for the shape.
% So [d1 a1] = [2 5] means the first strip of the string starts 2 pixels
% below the center line and 5 pixels above.
% 'ma' and 'md' are the maximum ascent and descent for the word.
% We do not capture holes in strings - only the start and end of vertical spaces.
% If a section is blank the ascent and descent are 0.

% Copyright 2016-2025 The MathWorks, Inc.

num_words = length(words);

shape = zeros(3,num_words);

initialFigureSize = [800 800];
fig.f = figure(HandleVisibility = 'off',...
               Visible = 'off',...
               IntegerHandle = 'off',...
               Toolbar = 'none',...
               Menubar = 'none',...
               WindowStyle = 'normal',...
               DockControls = 'off',...
               Color = 'k',...
               Units = 'pixels',...
               Position = [50 50 initialFigureSize]);

clean = onCleanup(@()close(fig.f));

fig.ax = axes(Parent = fig.f, Position = [0 0 1 1], Visible = 'off');

% get vertical extent of a test string 
props.Parent = fig.ax;
t0 = text(0,0,'test',props,...
          FontUnits = 'pixels',...
          FontSize = 100,...
          Interpreter = 'tex');
t0.Units = 'pixels';
ext = t0.Extent;
factor = ext(4)/100; % how much larger is the text height than our requested height
factor = max(factor, 1.2); % add at least 20% gap above and below (mac seems to need it)
fontname = t0.FontName;

inset = 10; % keep 10 pixels away from edges since printing prefers that
if nargin < 5
    screenWidth = getScreenWidth;
end
screenWidth = screenWidth - 2*inset;
[fsize, referenceHeight] = fontSizeInPixels(weights,height,words,screenWidth);
offset = ceil(fsize*factor); % vertical extents of each word (including leading)
delete(t0);
maxNumTextObjects = 50;
font = matlab.graphics.general.Font;
font.Name = fontname;
font.Size = 10;
for i = maxNumTextObjects:-1:1
  fig.tprim(i) = matlab.graphics.primitive.world.Text(...
      Visible = "off",...
      Font = font,...
      Margin = 1e-10,...
      HorizontalAlignment = "center",...
      VerticalAlignment = "middle",...
      ColorData = uint8([255;255;255;255]),...
      Parent = fig.ax,...
      Interpreter = "none");
end

if num_words == 0
    shape = double.empty;
    return;
end

% process in chunks of strings up to 500 pixels high at a time, otherwise figure gets too big
pixelSize = 500;
c = cumsum(offset);
wordChunkNum = discretize(c,0:pixelSize:(c(end)+pixelSize));
[groupCounts,chunkNums] = groupsummary((1:numel(wordChunkNum))',wordChunkNum(:),'numunique');
if any(groupCounts > maxNumTextObjects)
    startGroupNum = chunkNums(find(groupCounts > maxNumTextObjects,1));
    startIdx = find(wordChunkNum==startGroupNum,1);
    i1 = startIdx;
    i2 = startIdx;
    run_sum = 0;
    currGroupNum = startGroupNum;
    while i2 <= num_words
        run_sum = run_sum + offset(i2);
        if run_sum > 500 || i2 == num_words || (i2-i1+1 == maxNumTextObjects)
            wordChunkNum(i1:i2) = currGroupNum;
            currGroupNum = currGroupNum+1;
            i2 = i2+1;
            i1 = i2;
            run_sum = 0;
        else
            i2 = i2+1;
        end
    end
end

% Determine what figure size can accomodate all the word chunks and update
% Figure position.
[estWidth,estHeight] = estimateFigureSize(words, initialFigureSize, wordChunkNum, fsize, offset, inset, screenWidth);
fig.f.Position(3:4) = [estWidth,estHeight];
waitForFigure(fig.f,[estWidth,estHeight]);

grps = unique(wordChunkNum);
for i = 1:numel(grps)
    thisGrp = grps(i);
    idx = wordChunkNum==thisGrp;
    chunk = processWords(fig,words(idx),fsize(idx),offset(idx),inset);
    shape(1:size(chunk,1), find(idx)) = chunk;
end
end

function [estWidth,estHeight] = estimateFigureSize(words,initialFigureSize,wordChunkNum,fsize,offset,inset,max_width)
grps = unique(wordChunkNum);
estWidth = initialFigureSize(1);
estHeight = initialFigureSize(2);
for i = 1:numel(grps)
    thisGrp = grps(i);
    idx = wordChunkNum==thisGrp;
    num_words = numel(words(idx));
    localEstWidth = estimateWidth(words(idx),fsize(idx));
    localEstHeight = estimateHeight(sum(offset(idx)),inset,num_words);
    estWidth = max(estWidth,localEstWidth);
    estHeight = max(estHeight,localEstHeight);
end
estWidth = min(max_width,estWidth);
end

function shape = processWords(fig, words, fsize, offset, inset)
% Take words with given font sizes and vertical placement offsets and
% return the shape information for those strings. The strings are stacked
% vertically, bottom to top, along the hidden figure and rendered to a
% bitmap. The bitmap is then scanned along columns of each string to
% find the vertical metrics.
num_words = length(words);

actualWidth = fig.f.Position(3);
actualHeight = fig.f.Position(4);
axcenter = round(actualWidth/2);
fig.ax.Units = 'pixels';
fig.ax.Position = [1 inset+1 actualWidth actualHeight]; % small gap on bottom
fig.ax.YLim = [0 actualHeight];
fig.ax.XLim = [0 actualWidth];

% compute world primitive text data to stack words up along y
vd = zeros(3,1,'single');
pixelsPerPoint = get(0,'ScreenPixelsPerInch')/72;
y = 0;
for k=1:num_words
    txt = words(k);
    vd(1) = axcenter;
    y = y + offset(k)/2;
    vd(2) = y;
    y = y + offset(k)/2 + 2; % also include 2 pix gap between words
    fig.tprim(k).VertexData = vd;
    fig.tprim(k).String = char(txt);
    fig.tprim(k).Font.Size = fsize(k)/pixelsPerPoint;
    fig.tprim(k).Visible = "on";
end
set(fig.tprim((num_words+1):end), Visible = "off");

% get pixel data
pix = getframe(fig.f);
pix = pix.cdata(:,:,1); % extract just R from RGB (they're all the same)
pix = matlab.graphics.chart.internal.wordcloud.shrinkHighDPI(pix, fig.f.Position); % remove hi-dpi scaling
pix = flipud(pix);
shape = zeros(3,num_words);

% loop over rendered words and get bound information
y = inset;
maxy = size(pix,1);
for k=1:num_words
    y1 = min(maxy, y);
    y2 = min(maxy, floor(y1 + offset(k)));

    % word_pix are the pixels for a given word.
    word_pix = pix(y1:y2,:);

    % now look for left and right edge of glyphs
    [wl,wr] = computeLeftRightEdge(word_pix);
    thicken = 2 + feature('webui'); % thicken the shape slightly for robustness
    wl = wl + thicken;
    wr = wr + thicken;

    % now loop over columns and find the ascent and descent of each one
    centerline = round(offset(k)/2);
    pixwidth = size(word_pix,2);
    width = wl + wr;
    header = 4; % size of header of shape data
    shape(header + 2*width,k) = 0; % pre-allocate space for metrics
    for j=1:width
        % take pixels at around column j to make the outline "bolder"
        a = max(1,axcenter - wl + j - 1 - thicken);
        b = max(1,min(pixwidth,axcenter - wl + j - 1 + thicken));
        c = word_pix(:,a:b);
        c = max(c.');
        
        starti = find(c,1,'first');
        endi = find(c,1,'last');
        if ~isempty(starti)
            coli = 2*(j-1) + header + 1;
            shape(coli,k) = centerline - starti + thicken; % descent
            shape(coli+1,k) = endi - centerline + thicken; % ascent
        end
    end
    
    y = y + offset(k) + 2;

    max_descent = max(shape((header+1):2:end,k));
    max_ascent = max(shape((header+2):2:end,k));
    shape(1,k) = wl;
    shape(2,k) = wr;
    shape(3,k) = max_descent;
    shape(4,k) = max_ascent;
end
end

function [wl,wr] = computeLeftRightEdge(word)
% word is a bitmap rendering of a word
% wl and wr are left and right widths from the center
h = size(word,1);
flat = word(:); % flatten by columns
first = floor((find(flat,1,'first')-1)/h)+1;
last = floor((find(flat,1,'last')-1)/h)+1;
if isempty(first)
    wl = 0;
    wr = 0;
else
    n = size(word,2);
    center = n/2;
    wl = max(1,ceil(center - first));
    wr = max(1,ceil(last - center));
end
end

function width = getScreenWidth
ss = get(groot,'ScreenSize');
width = ss(3);
end

function [fsize, shapeHeight] = fontSizeInPixels(weights,height,words,screenWidth)
fsize = weights*height; % font sizes in pixels
estimatedWidth = estimateWidth(words,fsize);
shapeHeight = height;
if estimatedWidth > screenWidth
    shapeHeight = ceil(height/estimatedWidth*screenWidth);
    fsize = weights*shapeHeight;
end
end

function h = estimateHeight(offset_sum,inset,num_words)
h = offset_sum + 2*inset + 2*num_words;
h = roundFigureSize(h);
end

function w = estimateWidth(words,fsize)
w = ceil(max((5+strlength(words)).*fsize));
w = roundFigureSize(w);
end

function x = roundFigureSize(x)
x = 100*ceil(x/100);
end

function isExpFigSize = waitForFigure(f,expSize)
% Figures need to process events until the position reaches the expected
% size, i.e. the Position set on Figure in this code.

arguments
    f (1,1) matlab.ui.Figure
    expSize (1,2) double
end

% Use pause to give Figure position a chance to settle. Diminishing pause
% times are designed to give Figure a heads start initially, but resolve as
% quickly as possible.
numLoops = 7;
maxPause = 600; % miliseconds
minPause = 100;
timeStep = logspace(log10(maxPause),log10(minPause),numLoops); % all together ~2 sec
for i = 1:numLoops

    % Always pause at least once to make sure the queried Position value is
    % real.
    pause(timeStep(i)/1000);

    % Use a 10px tolerance to allow for small figure size descrepencies.
    isExpFigSize = all(isapprox(f.Position(3:4),expSize,AbsoluteTolerance=10));
    if isExpFigSize
        break;
    end
end
end