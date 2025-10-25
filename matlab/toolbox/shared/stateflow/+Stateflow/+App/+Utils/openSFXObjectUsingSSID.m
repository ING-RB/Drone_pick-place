function openSFXObjectUsingSSID(chartPath, ssIdNumber)
%

%   Copyright 2018-2020 The MathWorks, Inc.
    if  ~exist(chartPath, 'file') && ~exist([chartPath '.sfx'], 'file')
        errId = 'MATLAB:lang:FileNotFound';
        Stateflow.internal.getRuntime().throwError(errId, getString(message(errId, chartPath)), chartPath, 'OnlyCMD');
    end
    edit(chartPath);
    [~, chartName, ~] = fileparts(chartPath);
    chartId = sfprivate('block2chart', [chartName '/' chartName]);
    chartH = sf('IdToHandle', chartId);
    objectH = chartH.find('ssIdNumber', ssIdNumber);
    if isempty(objectH)%fail silent for invalid ssId
        return;
    end
    sfprivate('studio_redirect', 'SelectIfOpen', objectH(1).Id);
end
