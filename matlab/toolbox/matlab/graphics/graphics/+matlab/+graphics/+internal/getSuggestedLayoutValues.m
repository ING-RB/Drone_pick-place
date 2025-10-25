function values = getSuggestedLayoutValues(varargin)
% This function is undocumented and may change in a future release.

%   Copyright 2018-2019 The MathWorks, Inc.

    if nargin == 2
        values = getAxesLevelProperties(varargin{1}, varargin{2});
    else
        values = getCanvasLevelPropertes(varargin{1});
    end
end

function values = getCanvasLevelPropertes(updateState)
    
    % This function computes suggested layout values at the canvas level.
    % This includes CanvasTitleFontSize and CanvasLabelPadding

    % Canvas level layout suggestions use three responsive break points  
    minCanvasSize = [240 192];
    baseCanvasSize = [560 420];
    maxCanvsSize = [1120 840];

    % Convert from device pixels to pixels
    pixelScale = (72.0 * updateState.PixelsPerPoint) / double(updateState.Canvas.ScreenPixelsPerInch);
    canvasSizeInPixels = updateState.ViewerPosition(3:4) ./ pixelScale;

    rWeight = [(canvasSizeInPixels(1) - minCanvasSize(1)) / (maxCanvsSize(1) - minCanvasSize(1)), ...
        (canvasSizeInPixels(2) - minCanvasSize(2)) / (maxCanvsSize(2) - minCanvasSize(2))];

    % store the most space constrained index in minIndex.  This is used to
    % calculated the suggested font size.
    rWeight = min(max(rWeight,0.0), 1.0);
    [~, minIndex] = min(rWeight);

    % Compute suggested decoration padding
    decorationPadding = [5 5];
    
    % Currently, suggested decoration padding is only changed if the canvas 
    % size is less than baseCanvasSize. 
    if canvasSizeInPixels(1) < baseCanvasSize(1)
        % Canvas width is less than base width, so calculate the suggested 
        % horizontal decoration padding (interpolate between 3 and 5
        % points)
        rWeight = (canvasSizeInPixels(1) - minCanvasSize(1)) / (baseCanvasSize(1) - minCanvasSize(1));
        decorationPadding(1) = 5 * (rWeight) + 3 * (1.0 - rWeight);
    end
    if canvasSizeInPixels(2) < baseCanvasSize(2)
        % Canvas height is less than base height, so calculate the suggested 
        % horizontal decoration padding (interpolate between 3 and 5
        % points)
        rWeight = (canvasSizeInPixels(2) - minCanvasSize(2)) / (baseCanvasSize(2) - minCanvasSize(2));
        decorationPadding(2) = 5 * (rWeight) + 3 * (1.0 - rWeight);
    end

    % Compute suggested title font size
    if canvasSizeInPixels(minIndex) < baseCanvasSize(minIndex)
        % smaller plot - titleFontSize between 13 and 11
        tScale = (canvasSizeInPixels(minIndex) - minCanvasSize(minIndex)) / (baseCanvasSize(minIndex) - minCanvasSize(minIndex));
        tScale = min(max(tScale,0.0), 1.0);
        titleFontSize = 13 * tScale + 11 * (1.0 - tScale);
    else
        % larger plot - titleFontSize between 15 and 13
        tScale = (maxCanvsSize(minIndex) - canvasSizeInPixels(minIndex)) / (maxCanvsSize(minIndex) - baseCanvasSize(minIndex));
        tScale = min(max(tScale,0.0), 1.0);
        titleFontSize = 13 * tScale + 15 * (1.0 - tScale);
    end

    % Round font size to nearest 0.5
    titleFontSize = round(titleFontSize * 2.0) / 2.0;

    values = struct('CanvasTitleFontSize', titleFontSize, ... 
        'CanvasDecorationPadding', decorationPadding);
end

function values = getAxesLevelProperties(ax, updateState)
    
    % This function computes suggested layout values for charts. Charts
    % should call this function during their doUpdate

    % Layout values change between minCanvasSize and maxCanvasSize.  These
    % values need to stay in sync with what the Axes uses in its
    % Min/MaxResponsiveSize property
    
    minAxesSize = [106 85];
    maxAxesSize = [300 240];
    
    % ResponsiveArea accounts for subplot layouts
    responsiveArea = ax.ResponsiveArea_I;
    
    if strcmp(ax.ActivePositionProperty, 'outerposition')
        % defaultPlotBoxSize takes into account the default axes loose insets
        defaultPlotBoxSize = [0.775 0.815];  
    
        % Pixel scale used to convert from device pixels to pixels
        pixelScale = (72.0 * updateState.PixelsPerPoint) / double(updateState.Canvas.ScreenPixelsPerInch);
    
        % Approximation for axes size in pixels takes into account pixel 
        % scale, OuterPosition, ResponsiveArea, and the default plot box 
        % size.  ViewerPosition is in device pixels, so the pixelScale is
        % applied to convert to "conceptual" pixels.
        innerPosInPixels = updateState.ViewerPosition(3:4) * pixelScale;
        outerPosInNormalized=updateState.convertUnits('canvas', 'normalized',  ax.Units, ax.OuterPosition_I(3:4));
        innerPosInPixels = outerPosInNormalized .* innerPosInPixels .* responsiveArea .* defaultPlotBoxSize;
    else
        innerPosInPixels = updateState.convertUnits('canvas', 'pixels',  ax.Units, ax.Position_I(3:4));
    end
    
    rWeight = [(innerPosInPixels(1) - minAxesSize(1)) / (maxAxesSize(1) - minAxesSize(1)), ...
        (innerPosInPixels(2) - minAxesSize(2)) / (maxAxesSize(2) - minAxesSize(2))];
    
    rWeight = min(max(rWeight,0.0), 1.0);
    minRWeight = min(rWeight);    

    % FontSize ranges from factory default to 80% factory default
    fontSize = get(groot, 'FactoryAxesFontSize');
    fontSize = fontSize * minRWeight + fontSize * 0.8 * (1.0 - minRWeight); 
    
    % Round to nearest 0.5 points
    fontSize = round(fontSize * 2.0) / 2.0;
      
    % clamp to 10 pixels
    if (fontSize * updateState.PixelsPerPoint) < 10.0
        fontSize = 10 / updateState.PixelsPerPoint;
    end

    % Decoration spacing ranges from 8 to 4 points
    decorationSpacing = round(8 * rWeight + 4 * (1.0 - rWeight));

    values = struct('FontSize', fontSize, 'DecorationSpacing', decorationSpacing, 'ResponsiveWeight', rWeight);
end
