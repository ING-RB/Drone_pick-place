function coordinateData = createCoordinateData(obj, valueSource, index, ~)
% Overridden function that returns an array of CoordinateData containing Data Source
% and its calculated value

%  Copyright 2024 The MathWorks, Inc.

import matlab.graphics.chart.interaction.dataannotatable.internal.CoordinateData;
coordinateData = CoordinateData.empty(0,1);

% numXGroups = obj.XNumGroups;
numPoints = obj.numEvalPts;

% Find which violin and relative position:
if strcmp(obj.DensityDirection_I,'both')
    xind = fix((index-1)/(2*numPoints)) + 1;
    pdfind = index - (xind-1)*2*numPoints;
    if pdfind > numPoints
        % We are on the negative side. Get to 1:numPoints and reverse:
        pdfind = 2*numPoints - pdfind + 1;
    end
else
    xind = fix((index-1)/numPoints) + 1;
    pdfind = index - (xind-1)*numPoints;
end
if strcmp(obj.DensityDirection_I,'negative')
    % Reverse the pdf index because the vertices are drawn top to bottom:
    pdfind = numPoints - pdfind + 1;
end

switch(valueSource)
    case getString(message('MATLAB:graphics:violinplot:Position'))
        coordinateData = CoordinateData(valueSource,obj.XGroupPositions(xind));
    case getString(message('MATLAB:graphics:violinplot:EvalPt'))
        coordinateData = CoordinateData(valueSource,obj.EvaluationPoints_I(pdfind,xind));
    case getString(message('MATLAB:graphics:violinplot:DensVal'))
        coordinateData = CoordinateData(valueSource,obj.DensityValues_I(pdfind,xind));
end

end