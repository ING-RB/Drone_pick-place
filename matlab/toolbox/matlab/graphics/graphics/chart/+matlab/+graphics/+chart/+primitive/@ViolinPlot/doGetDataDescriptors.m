function desc = doGetDataDescriptors(obj, index, ~)
%doGetDataDescriptors Return the data descriptors for a point
%
%  doGetDescriptors(obj, index, factor) returns an array of data
%  descriptors that describe the data at the specified point.

%  Copyright 2024 The MathWorks, Inc.

% Use index to find out what is being clicked on
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

% Create data descriptors
xgroup = matlab.graphics.chart.interaction.dataannotatable.DataDescriptor(...
    getString(message('MATLAB:graphics:violinplot:Position')),obj.XGroupPositions(xind));
evalPt = matlab.graphics.chart.interaction.dataannotatable.DataDescriptor(...
    getString(message('MATLAB:graphics:violinplot:EvalPt')),obj.EvaluationPoints_I(pdfind,xind));
densVal = matlab.graphics.chart.interaction.dataannotatable.DataDescriptor(...
    getString(message('MATLAB:graphics:violinplot:DensVal')),obj.DensityValues_I(pdfind,xind));

% Populate the descriptors
desc = [xgroup, evalPt, densVal];

end
