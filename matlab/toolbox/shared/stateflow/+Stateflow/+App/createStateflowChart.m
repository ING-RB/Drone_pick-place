function createStateflowChart()
%

%   Copyright 2024 The MathWorks, Inc.

if ~license('test', 'Stateflow')
    runtimeUtils = Stateflow.internal.getRuntime();
    errId = 'MATLAB:sfx:SFLicenseMissingForSFX';
    runtimeUtils.throwError(errId, getString(message(errId)),'chartName','OnlyCMD');
end

Stateflow.App.Studio.CreateNewSFXWithUserName();

end
