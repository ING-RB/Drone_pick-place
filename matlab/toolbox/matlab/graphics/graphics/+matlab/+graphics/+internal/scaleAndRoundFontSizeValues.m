function newFontSizes = scaleAndRoundFontSizeValues(currFontSizes, factor, units)
% scaleAndRoundFontSizeValues scales one or more font size values by a
% scale factor and rounds the result dependent on its magnitude. Used by 
% the FONTSIZE function. This file is for internal use only and may change 
% in a future release of MATLAB.

%   Copyright 2021-2022 The MathWorks, Inc.
arguments
    currFontSizes (1,:) double
    factor (1,1) double
    units (1,:) string
end

pixPointsIdx = ismember(units, ["pixels","points"]);
doRound = pixPointsIdx; % only round for pixels and points

minValidFontSize = eps * ones(size(currFontSizes));
minValidFontSize(pixPointsIdx) = 0.5;

newFontSizes = currFontSizes*factor;

% define threshold for rounding behavior
threshold = 10;
fontsOverThreshold = newFontSizes > threshold;

% round values over threshold to the nearest integer
newFontSizes(fontsOverThreshold & doRound) = round(newFontSizes(fontsOverThreshold & doRound));

% round values at the threshold and under to the nearest half integer (0.5)
newFontSizes(~fontsOverThreshold & doRound) = round(newFontSizes(~fontsOverThreshold & doRound)/0.5)*0.5;

% make sure font sizes are above the minimum
newFontSizes(newFontSizes<=minValidFontSize) = minValidFontSize(newFontSizes<=minValidFontSize);
end