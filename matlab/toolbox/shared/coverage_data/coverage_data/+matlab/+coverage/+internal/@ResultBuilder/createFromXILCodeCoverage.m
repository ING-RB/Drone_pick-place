%

% Copyright 2022 The MathWorks, Inc.

function resObjs = createFromXILCodeCoverage(dataProvider)

arguments
    dataProvider (1,1) matlab.coverage.internal.CodeCovDataProvider
end

% Let the provider doing the work!
cvds = dataProvider.getCodeCovData();

% Construct the output array of objects
resObjs(1:numel(cvds), 1) = matlab.coverage.Result();
for ii = 1:numel(resObjs)
    resObjs(ii) = matlab.coverage.Result(cvds(ii));
end
