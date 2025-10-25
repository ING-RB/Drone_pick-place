function [xOffset, yOffset, widthScaleFactor, groupWidth] = computeBars(x, y, isGrouped, maxSpacing, groupWidth)
%

%   Copyright 2014-2023 The MathWorks, Inc.

% Determine the number of bars and series
[numBars,numSeries] = size(y);

% Calculate the Y-offset:
yOffset = [];
if ~isGrouped && (numSeries>1)
    % When displaying "stacked" bar charts, negative bars are stacked below
    % zero and positive bars are stacked above zero.
    
    % Append zeros to the y-data for use in cumsum.
    yPad = [zeros(numBars,1) y];
    yPos = ~(yPad<0); % Count NaN and Inf as positive but -Inf as negative.
    
    % Replace non-finite with 0 for use in cumsum.
    yPad(~isfinite(yPad))=0;
    
    % Calculate the height for positive bars.
    yPosSum = cumsum(yPad.*yPos,2);
    
    % Calculate the negative height for negative bars.
    yNegSum = cumsum(yPad.*(~yPos),2);
    
    % Calculate the location for the bottom of each bar.
    yPos = yPos(:,2:end);
    yOffset = yPosSum(:,1:end-1).*yPos + yNegSum(:,1:end-1).*(~yPos);
end

% Determine the width of each bar:
defaultGroupWidth = 0.8;
if numSeries == 1 || ~isGrouped
    groupWidth = 1;
elseif ~isfinite(groupWidth)
    groupWidth = min(defaultGroupWidth, numSeries/(numSeries+1.5));
end

% Figure out the spacing between bars
barSpacing = min(diff(unique(x)));
if isempty(barSpacing) || ~isfinite(barSpacing)
    barSpacing = 1;
end
barSpacing = min(barSpacing, maxSpacing);

if isGrouped && (numSeries>1)
    % Calculate the width scale factor and x-offset based on the number of
    % bars and space between XData values.
    widthScaleFactor = repmat(groupWidth/numSeries, 1, numSeries).*barSpacing;
    dt = (0:(numSeries-1))-(numSeries-1)/2;
    xOffset = dt.*widthScaleFactor;
else
    % There is no x-offset for stacked bar plots or when numSeries == 1
    widthScaleFactor = ones(1,numSeries).*barSpacing;
    xOffset = zeros(1, numSeries);
end

end
