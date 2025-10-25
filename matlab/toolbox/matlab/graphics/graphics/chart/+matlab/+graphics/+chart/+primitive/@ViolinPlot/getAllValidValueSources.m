function valueSources = getAllValidValueSources(obj)
% Overridden function that returns a string array of valid valueSources

%  Copyright 2024 The MathWorks, Inc.

valueSources = [string(getString(message('MATLAB:graphics:violinplot:Position')));...
    getString(message('MATLAB:graphics:violinplot:EvalPt'));...
    getString(message('MATLAB:graphics:violinplot:DensVal'))];

end
