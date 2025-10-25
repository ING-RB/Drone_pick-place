%

% Copyright 2022 The MathWorks, Inc.

function resObjs = createFromCodeCoverageCollector(ccDataAccessor)

arguments
   ccDataAccessor (1,1) function_handle
end

% Extract the static and runtime data from the coverage engine
staticData = ccDataAccessor('getStaticData');
if isempty(staticData) || ~iscell(staticData)
    resObjs = matlab.coverage.Result.empty();
    return
end
runtimeData = ccDataAccessor('getRuntimeData');

resObjs = matlab.coverage.internal.ResultBuilder.createFromCodeCoverageCollectorData(staticData, runtimeData);

% LocalWords:  LXE mf
