function dataTipRows = createDefaultDataTipRows(obj)
% Overridden function that returns data tip rows for a
% ViolinPlot object

%  Copyright 2024 The MathWorks, Inc.

% Create data descriptors
xgroup = dataTipTextRow(getString(message('MATLAB:graphics:violinplot:Position')),...
    getString(message('MATLAB:graphics:violinplot:Position')));
evalPt = dataTipTextRow(getString(message('MATLAB:graphics:violinplot:EvalPt')),...
    getString(message('MATLAB:graphics:violinplot:EvalPt')));
densVal = dataTipTextRow(getString(message('MATLAB:graphics:violinplot:DensVal')),...
    getString(message('MATLAB:graphics:violinplot:DensVal')));

% Populate the descriptors
dataTipRows = [xgroup, evalPt, densVal];

end